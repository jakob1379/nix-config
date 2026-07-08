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
(defvar me/config-el-file (expand-file-name "config.el" user-emacs-directory))

;; add the readthedocs theme as safe
(setq org-safe-remote-resources
      '("\\`https://fniessen\\.github\\.io/org-html-themes/org/readtheorg\\.setup\\'"
        "\\`https://fniessen\\.github\\.io/org-html-themes/org/theme-readtheorg\\.setup\\'"))

;; Home Manager installs a tangled config.el. Non-Nix installs can fall back to
;; tangling config.org at startup when config.el is missing.
(cond
 ((file-readable-p me/config-el-file)
  (load-file me/config-el-file))
((file-readable-p me/config-org-file)
  (require 'org)
  (require 'ob-tangle)
  (org-babel-load-file me/config-org-file))
 (t
  (user-error "Cannot find readable Emacs config: %s or %s"
              me/config-el-file
              me/config-org-file)))

;;; init.el ends here
