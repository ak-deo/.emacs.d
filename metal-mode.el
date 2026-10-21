;;; metal-mode.el --- Major mode for Apple's Metal Shading Language -*- lexical-binding: t; -*-

;; A thin layer over c++-mode (MSL is a C++ dialect):
;; - highlights Metal qualifiers, types and [[attributes]]
;; - teaches cc-mode to skip address-space / stage qualifiers when parsing
;;   declarations, so `device float4 *out' still indents and fontifies right
;; - flymake diagnostics from the real Metal compiler (xcrun metal -fsyntax-only)
;; - `M-x compile' defaults to compiling the current file to .air

;;; Code:

(require 'cc-mode)
(require 'flymake)

(defgroup metal nil
  "Major mode for the Metal Shading Language."
  :group 'languages
  :prefix "metal-")

(defcustom metal-compiler-command '("xcrun" "-sdk" "macosx" "metal")
  "Command (program and leading args) that invokes the Metal compiler."
  :type '(repeat string))

(defcustom metal-flymake-extra-args nil
  "Extra arguments passed to the compiler for flymake checks.
Add -I/-D flags here (or in .dir-locals.el) for project headers."
  :type '(repeat string))

(defcustom metal-enable-flymake t
  "Turn on flymake in Metal buffers when the compiler is available."
  :type 'boolean)

;;;; Keywords

(defconst metal-qualifiers
  '("kernel" "vertex" "fragment"
    "device" "constant" "thread" "threadgroup" "threadgroup_imageblock"
    "ray_data" "object_data")
  "Function and address-space qualifiers.
cc-mode treats these as noise so declaration parsing isn't confused.")

(defconst metal-types
  (append
   '("half" "bfloat" "uchar" "ushort" "uint" "ulong" "size_t" "ptrdiff_t"
     "vec" "packed_vec" "matrix"
     "texture1d" "texture1d_array" "texture2d" "texture2d_array"
     "texture2d_ms" "texture2d_ms_array" "texture3d"
     "texturecube" "texturecube_array" "texture_buffer"
     "depth2d" "depth2d_array" "depth2d_ms" "depth2d_ms_array"
     "depthcube" "depthcube_array"
     "sampler" "array" "array_ref" "imageblock"
     "atomic" "atomic_int" "atomic_uint" "atomic_bool" "atomic_float"
     "command_buffer" "render_command" "compute_command"
     "visible_function_table" "intersection_function_table"
     "acceleration_structure" "primitive_acceleration_structure"
     "instance_acceleration_structure" "intersector" "intersection_query"
     "ray" "mesh" "mesh_grid_properties" "simdgroup_matrix")
   ;; float4, packed_half3, uint2 ...
   (let (out)
     (dolist (base '("bool" "char" "uchar" "short" "ushort" "int" "uint"
                     "long" "ulong" "half" "bfloat" "float"))
       (dolist (n '("2" "3" "4"))
         (push (concat base n) out)
         (push (concat "packed_" base n) out)))
     out)
   ;; float4x4, half3x2 ...
   (let (out)
     (dolist (base '("half" "float" "bfloat"))
       (dolist (c '("2" "3" "4"))
         (dolist (r '("2" "3" "4"))
           (push (concat base c "x" r) out))))
     out))
  "Metal built-in type names.")

(defconst metal-font-lock-keywords
  `((,(regexp-opt metal-qualifiers 'symbols) . font-lock-keyword-face)
    (,(regexp-opt metal-types 'symbols) . font-lock-type-face)
    ;; access::read, coord::normalized, filter::linear ...
    ("\\_<\\(access\\|address\\|coord\\|filter\\|mip_filter\\|compare_func\\)::\\(\\sw\\|\\s_\\)+"
     . font-lock-constant-face)
    ;; every name inside [[...]]: [[buffer(0)]], [[stage_in]], [[user(locn0)]]
    ("\\[\\["
     ("\\_<[A-Za-z_][A-Za-z0-9_]*\\_>"
      (save-excursion (if (search-forward "]]" (line-end-position) t)
                          (point)
                        (line-end-position)))
      nil
      (0 font-lock-preprocessor-face t))))
  "Extra font-lock rules layered on top of c++-mode's.")

;;;; Flymake

(defvar-local metal--flymake-proc nil)

(defun metal-flymake (report-fn &rest _args)
  "Flymake backend running the Metal compiler with -fsyntax-only."
  (unless (executable-find (car metal-compiler-command))
    (error "Cannot find %s" (car metal-compiler-command)))
  (when (process-live-p metal--flymake-proc)
    (kill-process metal--flymake-proc))
  (let* ((source (current-buffer))
         ;; Check a temp copy so unsaved edits are seen; -I keeps
         ;; #include "Foo.h" relative to the real file working.
         (tmp (make-temp-file "metal-flymake" nil ".metal"))
         (dir (and buffer-file-name (file-name-directory buffer-file-name)))
         (diag-re (concat "^.*" (regexp-quote (file-name-nondirectory tmp))
                          ":\\([0-9]+\\):\\([0-9]+\\): \\(?:fatal \\)?"
                          "\\(error\\|warning\\|note\\): \\(.*\\)$")))
    (save-restriction
      (widen)
      (write-region nil nil tmp nil 'silent))
    (setq metal--flymake-proc
          (make-process
           :name "metal-flymake" :noquery t :connection-type 'pipe
           :buffer (generate-new-buffer " *metal-flymake*")
           :command `(,@metal-compiler-command "-fsyntax-only"
                      ,@(when dir (list "-I" (expand-file-name dir)))
                      ,@metal-flymake-extra-args ,tmp)
           :sentinel
           (lambda (proc _event)
             (when (memq (process-status proc) '(exit signal))
               (unwind-protect
                   (if (with-current-buffer source (eq proc metal--flymake-proc))
                       (with-current-buffer (process-buffer proc)
                         (goto-char (point-min))
                         (let (diags)
                           (while (re-search-forward diag-re nil t)
                             (let ((region (flymake-diag-region
                                            source
                                            (string-to-number (match-string 1))
                                            (string-to-number (match-string 2))))
                                   (type (pcase (match-string 3)
                                           ("error" :error)
                                           ("warning" :warning)
                                           (_ :note))))
                               (push (flymake-make-diagnostic
                                      source (car region) (cdr region)
                                      type (match-string 4))
                                     diags)))
                           (funcall report-fn (nreverse diags))))
                     (flymake-log :warning "Canceling obsolete check %s" proc))
                 (delete-file tmp)
                 (kill-buffer (process-buffer proc)))))))))

;;;; Mode

;;;###autoload
(define-derived-mode metal-mode c++-mode "Metal"
  "Major mode for Apple's Metal Shading Language."
  (setq-local c-noise-macro-names
              (append metal-qualifiers c-noise-macro-names))
  (c-make-noise-macro-regexps)
  (font-lock-add-keywords nil metal-font-lock-keywords)
  (when buffer-file-name
    (let ((file (file-name-nondirectory buffer-file-name)))
      (setq-local compile-command
                  (format "%s -c %s -o %s"
                          (mapconcat #'shell-quote-argument
                                     metal-compiler-command " ")
                          (shell-quote-argument file)
                          (shell-quote-argument
                           (concat (file-name-sans-extension file) ".air"))))))
  ;; Only our backend: cc-mode's flymake-cc / legacy backends just error here.
  (setq-local flymake-diagnostic-functions (list #'metal-flymake))
  (when (and metal-enable-flymake
             (executable-find (car metal-compiler-command)))
    (flymake-mode 1)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.metal\\'" . metal-mode))

(provide 'metal-mode)
;;; metal-mode.el ends here
