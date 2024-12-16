;;; Commentary:
;;" init.el: settings from customise-*


;; Ensure straight.el and use-package are loaded
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(setq vc-follow-symlinks t)

;; Load Org mode as early as possible
(straight-use-package 'org)

;; add the readthedocs theme as safe
(setq org-safe-remote-resources
      '("\\`https://fniessen\\.github\\.io/org-html-themes/org/theme-readtheorg\\.setup\\'"))

;; load the config
;;; removing caching from the org file did not solve forcing tangling, so we ensure to delete the
;;; file
(let ((config-el (expand-file-name "~/.emacs.d/config.el")))
  (when (file-exists-p config-el)
    (delete-file config-el)
    (message "Deleted existing config.el")))

(org-babel-load-file "~/.emacs.d/config.org")
