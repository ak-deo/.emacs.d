;; tmux setup
;; Language support (modes for Python, JavaScript, TypeScript, Go, Rust, Racket, LaTex)
;; RSS feeds (blogposts, hnrss, etc.)

;; No startup screen
(setq inhibit-startup-screen t)

;;;;;;;;;;;;;;;;
;;; PACKAGES ;;;
;;;;;;;;;;;;;;;;


;; Bootstrap straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; All use-package declarations will use straight.el by default
(setq straight-use-package-by-default t)

;; Install use-package via straight
(straight-use-package 'use-package)

(use-package tmux-pane
 ;; :vc (:url "https://github.com/laishulu/emacs-tmux-pane.git")
 :bind (("M-i" . tmux-pane-omni-window-up)
        ("M-j" . tmux-pane-omni-window-left)
        ("M-k" . tmux-pane-omni-window-down)
        ("M-l" . tmux-pane-omni-window-right)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PERSONAL PREFERENCES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-display-line-numbers-mode)

(global-visual-line-mode)

(setq make-backup-files nil)

(setq-default tab-width 4)

(global-eldoc-mode -1)

(global-set-key (kbd "C-x <") 'flymake-goto-prev-error)
(global-set-key (kbd "C-x >") 'flymake-goto-next-error)

;;;;;;;;;;;;;;;;;;;
;;; KEYBINDINGS ;;;
;;;;;;;;;;;;;;;;;;;

(global-set-key (kbd "M-;") 'comment-line)

(global-set-key (kbd "C-x j") 'next-buffer)
(global-set-key (kbd "C-x l") 'previous-buffer)

(defun akash/find-init-file ()
  "Edit init.el"
  (interactive)
  (find-file "~/.emacs.d/init.el"))

(defun akash/find-todo-org ()
  "Edit life.org"
  (interactive)
  (find-file "~/org/todo.org"))

(defun akash/find-inbox-org ()
  "Edit inbox.org"
  (interactive)
  (find-file "~/org/inbox.org"))

(global-set-key (kbd "C-x C-v") 'akash/find-init-file)
(global-set-key (kbd "C-x ,") 'akash/find-todo-org)
(global-set-key (kbd "C-x /") 'akash/find-inbox-org)



(global-set-key (kbd "M-i") 'windmove-up)
(global-set-key (kbd "M-j") 'windmove-left)
(global-set-key (kbd "M-k") 'windmove-down)
(global-set-key (kbd "M-l") 'windmove-right)

(defun akash/auto-remember-project ()
  "Auto-register the current project with project.el."
  (when-let ((pr (project-current)))
    (project-remember-project pr)))
(add-hook 'find-file-hook #'akash/auto-remember-project)

(use-package treemacs
  :config
  (setq treemacs-width 30)
  :bind (("C-c e" . treemacs-select-window)
         ("C-c E" . treemacs-add-and-display-current-project-exclusively)
         :map treemacs-mode-map
         ("M-i" . windmove-up)
         ("M-j" . windmove-left)
         ("M-k" . windmove-down)
         ("M-l" . windmove-right)))
;;;;;;;;;;;;;
;;; MAGIT ;;;
;;;;;;;;;;;;;

(use-package magit
  :bind ("C-c i" . magit-status))

;; ;;; IVY
(use-package counsel
  :init (counsel-mode))

(use-package ivy
  :init (ivy-mode))

(setq ivy-use-virtual-buffers t)
(setq ivy-count-format "(%d/%d) ")

;; Trying this for a while and seeing what breaks

(keymap-global-set "C-s" #'swiper-isearch)
(keymap-global-set "M-x" #'counsel-M-x)
(keymap-global-set "C-x C-f" #'counsel-find-file)
(keymap-global-set "M-y" #'counsel-yank-pop)
(keymap-global-set "<f1> f" #'counsel-describe-function)
(keymap-global-set "<f1> v" #'counsel-describe-variable)
(keymap-global-set "<f1> o" #'counsel-describe-symbol)
(keymap-global-set "<f1> l" #'counsel-find-library)
(keymap-global-set "<f2> i" #'counsel-info-lookup-symbol)
(keymap-global-set "<f2> u" #'counsel-unicode-char)
(keymap-global-set "<f2> j" #'counsel-set-variable)
(keymap-global-set "C-x b" #'ivy-switch-buffer)
(keymap-global-set "C-c v" #'ivy-push-view)
(keymap-global-set "C-c V" #'ivy-pop-view)

(keymap-global-set "C-c c" #'counsel-compile)
(keymap-global-set "C-c g" #'counsel-git)
(keymap-global-set "C-c j" #'counsel-git-grep)
(keymap-global-set "C-c L" #'counsel-git-log)
(keymap-global-set "C-c k" #'counsel-rg)
(keymap-global-set "C-c m" #'counsel-linux-app)
(keymap-global-set "C-c n" #'counsel-fzf)
(keymap-global-set "C-x l" #'counsel-locate)
(keymap-global-set "C-c J" #'counsel-file-jump)
(keymap-global-set "C-S-o" #'counsel-rhythmbox)
(keymap-global-set "C-c w" #'counsel-wmctrl)

(keymap-global-set "C-c C-r" #'ivy-resume)
(keymap-global-set "C-c b" #'counsel-bookmark)
(keymap-global-set "C-c d" #'counsel-descbinds)
(keymap-global-set "C-c o" #'counsel-outline)
(keymap-global-set "C-c t" #'counsel-load-theme)
(keymap-global-set "C-c F" #'counsel-org-file)


;;; LSP
;; (setq load-path
;;       (cons (expand-file-name "~/tank/mojo-experiments/mojo-hl/") load-path))
;; (require 'mojo-mode)

(use-package js2-mode
  :mode "\\.js\\'")

(use-package web-mode
  :mode ("\\.html\\'" "\\.css\\'"))

(use-package eglot
  :hook ((c-mode . eglot-ensure)
         (c++-mode . eglot-ensure)
         (python-mode . eglot-ensure)
         (js2-mode . eglot-ensure)
         (web-mode . eglot-ensure)
         (mojo-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs
               '((c-mode c++-mode) . ("clangd")))
  (add-to-list 'eglot-server-programs
               '((python-mode) . ("pylsp")))
  (add-to-list 'eglot-server-programs
               '((js2-mode) . ("typescript-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(web-mode . ("vscode-html-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((mojo-mode) . ("mojo-lsp-server")))
  (add-hook 'eglot-managed-mode-hook (lambda () (eldoc-mode -1))))

(use-package company
  :hook (after-init . global-company-mode))

(use-package ivy-xref
  :ensure t
  :init
  ;; xref initialization is different in Emacs 27 - there are two different
  ;; variables which can be set rather than just one
  (when (>= emacs-major-version 27)
    (setq xref-show-definitions-function #'ivy-xref-show-defs))
  ;; Necessary in Emacs <27. In Emacs 27 it will affect all xref-based
  ;; commands other than xref-find-definitions (e.g. project-find-regexp)
  ;; as well
  (setq xref-show-xrefs-function #'ivy-xref-show-xrefs))


;; ;; company
;; (use-package company
;;   :ensure t)
;; ;; treemacs

(use-package which-key
  :config
    (which-key-mode))

;; (setq load-path
;;       (cons (expand-file-name "~/tank/llvm-project/llvm/utils/emacs/") load-path))
;; (require 'llvm-mode)
;; (require 'llvm-mir-mode)

;;;;;;;;;;;;;;;;
;;; ORG-MODE ;;;
;;;;;;;;;;;;;;;;

;; org-mode configuration
;; Capture
(setq org-directory "~/org")
(setq org-capture-templates
      (quote (("t" "todo" entry (file "inbox.org")
               "* TODO %?\n%U\n%a\n" :clock-in t :clock-resume t)
              ("m" "Meeting" entry (file+headline "inbox.org")
               ,(concat "* %? :meeting:\n"
                        "<%<%Y-%m-%d %a %H:00>>"))
              ("n" "Note" entry  (file "notes.org")
               ,(concat "* Note (%a)\n"
                        "/Entered on/ %U\n" "\n" "%?")))))
(global-set-key (kbd "C-c c") 'org-capture)
;; Refile
(setq org-refile-targets (quote ((org-agenda-files :maxlevel . 9))))
(setq org-refile-use-outline-path 'file)
(setq org-outline-path-complete-in-steps nil)

;; TODO
(setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "HOLD(h)" "|" "DONE(d)")))
(setq org-use-fast-todo-selection t)

(defun log-todo-next-creation-date (&rest ignore)
  "Log NEXT creation time in the property drawer under the key 'ACTIVATED'"
  (when (and (string= (org-get-todo-state) "NEXT")
             (not (org-entry-get nil "ACTIVATED")))
    (org-entry-put nil "ACTIVATED" (format-time-string "[%Y-%m-%d]"))))
(add-hook 'org-after-todo-state-change-hook #'log-todo-next-creation-date)

(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c l") 'org-store-link)

;; Clocking
(setq org-log-done 'time)


;; code blocks
(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (python . t)
   (C . t)))
(setq org-confirm-babel-evaluate nil)

;; copy-paste
(use-package xclip
  :config
  (xclip-mode 1))

(setq custom-safe-themes t)
(use-package zenburn-theme
  :config
  (load-theme 'zenburn))

(winner-mode)

;; Eat windmove helpers: switch to emacs mode before navigating away
(defun akash/eat-windmove-up ()
  (interactive) (eat-emacs-mode) (windmove-up))
(defun akash/eat-windmove-down ()
  (interactive) (eat-emacs-mode) (windmove-down))
(defun akash/eat-windmove-left ()
  (interactive) (eat-emacs-mode) (windmove-left))
(defun akash/eat-windmove-right ()
  (interactive) (eat-emacs-mode) (windmove-right))

(use-package eat
  :config
  ;; Bind M-i/j/k/l in char and semi-char mode so they escape the terminal
  (dolist (map (list eat-char-mode-map eat-semi-char-mode-map))
    (define-key map (kbd "M-i") #'akash/eat-windmove-up)
    (define-key map (kbd "M-j") #'akash/eat-windmove-left)
    (define-key map (kbd "M-k") #'akash/eat-windmove-down)
    (define-key map (kbd "M-l") #'akash/eat-windmove-right))
  ;; Auto-activate semi-char mode when an eat window is selected.
  ;; Semi-char forwards normal typing to the terminal but keeps C-c as
  ;; an Emacs prefix, so C-c C-e (switch to emacs mode for scrolling) works.
  (add-hook 'window-selection-change-functions
            (lambda (frame)
              (with-selected-frame frame
                (when (derived-mode-p 'eat-mode)
                  (eat-semi-char-mode))))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
