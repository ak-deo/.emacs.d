;;; org-sync.el --- keep ~/org in sync with GitHub -*- lexical-binding: t; -*-

;; Runs ~/.local/bin/org-sync (pull --rebase --autostash, commit "sync", push)
;; in the background: when you visit a file under ~/org (so you start from the
;; latest state) and after every save (so edits reach GitHub immediately).
;; auto-revert refreshes open buffers when a pull changes files on disk.

(defconst akash/org-sync-dir (expand-file-name "~/org/"))
(defconst akash/org-sync-script (expand-file-name "~/.local/bin/org-sync"))

(defun akash/org-sync--relevant-p ()
  (and buffer-file-name
       (string-prefix-p akash/org-sync-dir (file-truename buffer-file-name))))

(defun akash/org-sync ()
  "Sync ~/org with GitHub in the background if this buffer lives there."
  (when (akash/org-sync--relevant-p)
    (let ((proc (start-process "org-sync" "*org-sync*" akash/org-sync-script)))
      (set-process-sentinel
       proc
       (lambda (_proc event)
         (unless (string-prefix-p "finished" event)
           (message "org-sync failed — see *org-sync* buffer")))))))

(add-hook 'find-file-hook #'akash/org-sync)   ; pull before you start editing
(add-hook 'after-save-hook #'akash/org-sync)  ; commit + push after you save

;; Pick up background pulls (and phone captures) in already-open buffers.
(global-auto-revert-mode 1)

(provide 'org-sync)
