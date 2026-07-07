;;; init.el --- Emacs bootstrap -*- lexical-binding: t; -*-

;;; Commentary:
;; Bootstrap straight.el and load the literate configuration.

;;; Code:

(defvar me/gc-cons-threshold 16777216)
(defvar me/file-name-handler-alist file-name-handler-alist)

;; These must be set before straight.el is loaded. Setting them from
;; config.org is too late for the expensive startup path.
(setq straight-cache-autoloads t
      straight-check-for-modifications '(check-on-save)
      straight-vc-git-auto-fast-forward nil
      straight-vc-git-default-clone-depth 1
      straight-vc-git-default-protocol 'https
      straight-use-package-by-default t
      use-package-compute-statistics nil
      vc-follow-symlinks t)

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6
      file-name-handler-alist nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold me/gc-cons-threshold
                  gc-cons-percentage 0.1
                  file-name-handler-alist me/file-name-handler-alist)))

;; Ensure straight.el is loaded.
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

(defvar me/config-org-file (expand-file-name "config.org" user-emacs-directory))

;; add the readthedocs theme as safe
(setq org-safe-remote-resources
      '("\\`https://fniessen\\.github\\.io/org-html-themes/org/theme-readtheorg\\.setup\\'"))

(if (file-readable-p me/config-org-file)
    (progn
      (require 'org)
      (require 'ob-tangle)
      (org-babel-load-file me/config-org-file))
  (user-error "Cannot find readable Emacs config: %s" me/config-org-file))

;;; init.el ends here
