;;; -*- lexical-binding: t; -*-

(setq straight-cache-autoloads t
      straight-check-for-modifications '(check-on-save)
      straight-vc-git-auto-fast-forward nil
      straight-vc-git-default-clone-depth 1
      straight-vc-git-default-protocol 'https
      straight-use-package-by-default t
      use-package-compute-statistics nil
      vc-follow-symlinks t)

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

(use-package esup
  :defer t
  )

(use-package benchmark-init
  :if (getenv "EMACS_PROFILE")
  :demand t
  :config
  (benchmark-init/activate)
  (add-hook 'after-init-hook 'benchmark-init/deactivate)
  )

(use-package bug-hunter
  :straight t
  :defer t)

(add-hook
 'emacs-startup-hook
 (lambda ()
   (message "Emacs ready in %s with %d garbage collections."
            (format
             "%.2f seconds"
             (float-time
              (time-subtract after-init-time before-init-time)))
            gcs-done)))
(setq straight-cache-autoloads t
      straight-check-for-modifications '(check-on-save)
      straight-vc-git-auto-fast-forward nil
      straight-vc-git-default-clone-depth 1
      straight-vc-git-default-protocol 'https
      use-package-compute-statistics nil
      vc-follow-symlinks t
      straight-use-package-by-default t
      )
(setq native-comp-deferred-compilation t)
(setq frame-inhibit-implied-resize t)
(defun me/run-after-startup-idle (seconds function)
  "Run FUNCTION after startup and SECONDS idle seconds."
  (add-hook 'emacs-startup-hook
            (list 'lambda nil
                  (list 'run-with-idle-timer seconds nil
                        (list 'quote function)))))
;; max memory available for gc on startup
(defvar me/gc-cons-threshold 16777216)

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold me/gc-cons-threshold
                  gc-cons-percentage 0.1)))

;; max memory available for gc when opening minibuffer
(defun me/defer-garbage-collection-h ()
  (setq gc-cons-threshold most-positive-fixnum))

(defun me/restore-garbage-collection-h ()
  ;; Defer it so that commands launched immediately after will enjoy the
  ;; benefits.
  (run-at-time
   1 nil (lambda () (setq gc-cons-threshold me/gc-cons-threshold))))

(add-hook 'minibuffer-setup-hook #'me/defer-garbage-collection-h)
(add-hook 'minibuffer-exit-hook #'me/restore-garbage-collection-h)
(setq garbage-collection-messages t)
(defvar me/-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist me/-file-name-handler-alist)))
(setq site-run-file nil)
(setq inhibit-compacting-font-caches t)
(use-package gcmh
  :delight gcmh-mode
  :commands gcmh-mode
  :init
  (me/run-after-startup-idle
   1
   (lambda ()
     (when (require 'gcmh nil t)
       (gcmh-mode 1)))))
;; Global Settings
(setq-default
 ad-redefinition-action 'accept                     ;; Silence warnings for redefinition
 backup-by-copying t                                ;; Backup by copying
 confirm-kill-processes nil                         ;; Confirm kill processes
 create-lockfiles nil                               ;; Create lockfiles
 custom-safe-themes t                               ;; Custom safe themes
 delete-old-versions t                              ;; Delete old versions
 dired-kill-when-opening-new-dired-buffer t         ;; Dired kill when opening new buffer
 enable-local-variables t                           ;; Enable local variables
 inhibit-startup-message t                          ;; Inhibit startup message
 inhibit-startup-screen t                           ;; Inhibit startup screen
 initial-scratch-message nil                        ;; Initial scratch message
 load-prefer-newer t                                ;; Load prefer newer files
 use-short-answers t                                ;; Use short answers in prompts
 fill-column 100                                    ;; Set width for linebreaking
 )

;; Buffer-Local Settings
(setq
 column-number-mode t                               ;; Show columns/line in mode-line
 compilation-ask-about-save nil                     ;; Do not ask about saving when compiling
 compilation-save-buffers-predicate '(lambda () nil);; Do not save unrelated buffers
 delete-by-moving-to-trash t                        ;; Delete files to trash

 indent-tabs-mode nil                               ;; Go away, tabs - use spaces!
 lazy-highlight-syntax 'lazy
 read-process-output-max (* 1024 1024)              ;; Increase read size per process
 reb-re-syntax 'string                              ;; makes building reg-ex sane
 require-final-newline t                            ;; Adds newline at end of file if necessary
 select-enable-clipboard t                          ;; Merge system's and Emacs' clipboard
 tab-always-indent 'complete                        ;; Tab indents first then tries completions
 tab-width 4                                        ;; Smaller width for tab characters
 uniquify-buffer-name-style 'forward                ;; Uniquify buffer names
 whitespace-style '(face tabs)
 window-combination-resize t                        ;; Resize windows
 )

(global-whitespace-mode 1)
(electric-pair-mode 1)
(global-auto-revert-mode 1)                         ;; refresh a buffer if changed on disk
(global-display-fill-column-indicator-mode 1)       ;; Show this indicator > | <
(global-display-line-numbers-mode 1)                ;; show the left column with line numbers
(global-font-lock-mode t)                           ;; always highlight code
(global-so-long-mode 1)
(global-visual-line-mode 1)                         ;; Wrap line
(menu-bar-mode 1)
(save-place-mode 1)                                 ;; continue where you left off
(tool-bar-mode 0)                                   ;; it's not used anyways
;; (windmove-default-keybindings)
(prefer-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(set-clipboard-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-file-name-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-language-environment "UTF-8")
(set-selection-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(put 'narrow-to-defun  'disabled nil)
(put 'narrow-to-page   'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'set-goal-column 'disabled nil)
(put 'upcase-region 'disabled nil)
(setq desktop-dirname (concat user-emacs-directory "var/desktop/"))

(unless (file-directory-p desktop-dirname)
  (make-directory desktop-dirname t))

(setq desktop-base-file-name ".emacs.desktop") ; Optional: Customize base file name
;; (desktop-save-mode 1)
;; (desktop-auto-save-enable t)

;; (if (file-exists-p (concat desktop-dirname desktop-base-file-name))
;;     (desktop-read))
(defalias 'yes-or-no-p 'y-or-n-p)
(global-set-key (kbd "C-+")     'text-scale-increase)
(global-set-key (kbd "C--")     'text-scale-decrease)
(global-set-key (kbd "C-c s l") 'sort-lines)
(global-set-key [C-S-tab]       'previous-window)
(global-set-key [C-mouse-4]     'text-scale-increase)
(global-set-key [C-mouse-5]     'text-scale-decrease)
(global-set-key [C-tab]         'other-window)
(global-set-key [f10]           'treemacs)
(require 'ansi-color)
(defun display-ansi-colors ()
  (interactive)
  (ansi-color-apply-on-region (point-min) (point-max)))
;; (add-function :after after-focus-change-function
;;               (defun me/garbage-collect-maybe ()
;;                 (unless (frame-focus-state)
;;                   (garbage-collect))))
(require 'iso-transl)
(require 'server)
(unless noninteractive
  (me/run-after-startup-idle
   1
   (lambda ()
     (unless (server-running-p)
       (server-start)))))
(add-hook 'before-save-hook 'delete-trailing-whitespace)
(setq ring-bell-function 'ignore)
(setq-default line-spacing 1)
;; highlight the current line
(global-hl-line-mode t)

;; fix color display when loading Emacs in terminal
(defun enable-256color-term ()
  (interactive)
  (load-library "term/xterm")
  (terminal-init-xterm))

(unless (display-graphic-p)
  (if (string-suffix-p "256color" (getenv "TERM"))
      (enable-256color-term)))
(add-hook 'after-save-hook
          'executable-make-buffer-file-executable-if-script-p)
(add-hook 'compilation-filter-hook 'ansi-color-compilation-filter)
(define-key minibuffer-local-map (kbd "SPC") 'self-insert-command)
(use-package delight)
(use-package diminish)
(use-package all-the-icons
  :defer t
  :if (display-graphic-p)
  )

(use-package all-the-icons-completion
  :after all-the-icons
  :defer t
  :config
  (add-hook 'marginalia-mode-hook
            #'all-the-icons-completion-marginalia-setup)
  (all-the-icons-completion-mode 1))
(use-package ansible
  :defer t
  )
(use-package auto-sudoedit
  :defer 3
  :config (auto-sudoedit-mode 1)
  :delight
  )
(use-package auto-package-update
  :defer t
  :config
  (setq auto-package-update-prompt-before-update t
        auto-package-update-interval 7)
  )
(use-package beacon
  :delight
  :commands (beacon-blink beacon-mode)
  :bind ("C-x =" . (lambda ()
                     (interactive)
                     (beacon-blink)
                     (what-cursor-position)))
  :init
  (me/run-after-startup-idle
   2
   (lambda ()
     (when (require 'beacon nil t)
       (beacon-mode 1)))))
(use-package emacs
  :straight nil
  :init
  (when (boundp 'treesit-enabled-modes)
    (setq treesit-enabled-modes t))
  (when (boundp 'treesit-auto-install-grammar)
    ;; Grammars are provided by Nix; ask before compiling/downloading any gap.
    (setq treesit-auto-install-grammar 'ask))
  (when (boundp 'completion-eager-update)
    (setq completion-eager-update t))
  (when (boundp 'completion-eager-display)
    (setq completion-eager-display 'auto))
  (when (boundp 'minibuffer-visible-completions)
    (setq minibuffer-visible-completions 'up-down))
  (when (boundp 'eldoc-help-at-pt)
    (setq eldoc-help-at-pt t))
  (when (boundp 'kill-region-dwim)
    (setq kill-region-dwim 'emacs-word))
  (when (boundp 'ibuffer-human-readable-size)
    (setq ibuffer-human-readable-size t))
  (when (boundp 'display-fill-column-indicator-warning)
    (setq display-fill-column-indicator-warning nil))
  :custom
  ;; Let TAB indent first and complete when point is already indented.
  (tab-always-indent 'complete)
  ;; Emacs 30+: avoid adding Ispell as a noisy text-mode CAPF.
  (text-mode-ispell-word-completion nil)
  ;; Hide mode-inapplicable commands from M-x.
  (read-extended-command-predicate #'command-completion-default-include-p))

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-quit-no-match 'separator)
  (corfu-count 8)
  (corfu-popupinfo-delay '(0.4 . 0.2))
  (corfu-popupinfo-max-height 20)
  :bind (:map corfu-map
              ("C-n" . corfu-next)
              ("C-p" . corfu-previous)
              ("C-g" . corfu-quit)
              ("M-g" . corfu-info-location)
              ("M-h" . corfu-info-documentation)
              ("M-d" . corfu-popupinfo-toggle)
              ("M-p" . corfu-popupinfo-scroll-down)
              ("M-n" . corfu-popupinfo-scroll-up))
  :init
  (global-corfu-mode)
  :config
  (require 'corfu-popupinfo)
  (corfu-popupinfo-mode 1)
  (corfu-history-mode 1))

(use-package cape
  :defer t
  :bind ("C-c p" . cape-prefix-map)
  :init
  ;; Keep global fallback CAPFs cheap. Eglot's buffer-local CAPF wins in
  ;; programming buffers; Cape remains available explicitly under C-c p.
  (add-hook 'completion-at-point-functions #'cape-file t))
(use-package conf-mode
  :mode
  ("\\.cfg\\'"        . conf-mode)
  ("\\.conf\\'"       . conf-mode)
  ("\\.env.*\\'"      . conf-toml-mode)  ; Matches .env, .env-*, .env.* etc.
  ("\\.gitignore\\'"  . conf-mode)
  ("\\.txt\\'"        . conf-mode)
  )
(use-package csv-mode
  :mode (("\\.csv\\'" . csv-mode)
         ("\\.tsv\\'" . csv-mode))
  :hook (csv-mode . (lambda ()
                      (csv-guess-set-separator)
                      (csv-align-mode)
                      (csv-header-line)
                      (toggle-truncate-lines -1))))
;; Dired and related packages configuration
(use-package dired
  :defer t
  :straight (:type built-in)
  :config
  (require 'ls-lisp)
  :hook
  ((dired-after-reading . dired-git-info-auto-enable))
  :custom
  (ls-lisp-use-insert-directory-program nil)
  (dired-listing-switches "-laa --group-directories-first") ;; all is needed twice to show . and ..
  )
(use-package dired-open
  :if (display-graphic-p))
(use-package dired-rainbow
  :defer t
  :hook (dired-mode . (lambda () (require 'dired-rainbow)))
  :config
  (progn
    (dired-rainbow-define-chmod directory "#6cb2eb" "d.*")
    (dired-rainbow-define html "#eb5286" ("css" "less" "sass" "scss" "htm" "html" "jhtm" "mht" "eml" "mustache" "xhtml"))
    (dired-rainbow-define xml "#f2d024" ("xml" "xsd" "xsl" "xslt" "wsdl" "bib" "json" "msg" "pgn" "rss" "yaml" "yml" "rdata"))
    (dired-rainbow-define document "#9561e2" ("docm" "doc" "docx" "odb" "odt" "pdb" "pdf" "ps" "rtf" "djvu" "epub" "odp" "ppt" "pptx"))
    (dired-rainbow-define markdown "#ffed4a" ("org" "etx" "info" "markdown" "md" "mkd" "nfo" "pod" "rst" "tex" "textfile" "txt"))
    (dired-rainbow-define database "#6574cd" ("xlsx" "xls" "csv" "accdb" "db" "mdb" "sqlite" "nc"))
    (dired-rainbow-define media "#de751f" ("mp3" "mp4" "MP3" "MP4" "avi" "mpeg" "mpg" "flv" "ogg" "mov" "mid" "midi" "wav" "aiff" "flac"))
    (dired-rainbow-define image "#f66d9b" ("tiff" "tif" "cdr" "gif" "ico" "jpeg" "jpg" "png" "psd" "eps" "svg"))
    (dired-rainbow-define log "#c17d11" ("log"))
    (dired-rainbow-define shell "#f6993f" ("awk" "bash" "bat" "sed" "sh" "zsh" "vim"))
    (dired-rainbow-define interpreted "#38c172" ("py" "ipynb" "rb" "pl" "t" "msql" "mysql" "pgsql" "sql" "r" "clj" "cljs" "scala" "js"))
    (dired-rainbow-define compiled "#4dc0b5" ("asm" "cl" "lisp" "el" "c" "h" "c++" "h++" "hpp" "hxx" "m" "cc" "cs" "cp" "cpp" "go" "f" "for" "ftn" "f90" "f95" "f03" "f08" "s" "rs" "hi" "hs" "pyc" ".java"))
    (dired-rainbow-define executable "#8cc4ff" ("exe" "msi"))
    (dired-rainbow-define compressed "#51d88a" ("7z" "zip" "bz2" "tgz" "txz" "gz" "xz" "z" "Z" "jar" "war" "ear" "rar" "sar" "xpi" "apk" "xz" "tar"))
    (dired-rainbow-define packaged "#faad63" ("deb" "rpm" "apk" "jad" "jar" "cab" "pak" "pk3" "vdf" "vpk" "bsp"))
    (dired-rainbow-define encrypted "#ffed4a" ("gpg" "pgp" "asc" "bfe" "enc" "signature" "sig" "p12" "pem"))
    (dired-rainbow-define fonts "#6cb2eb" ("afm" "fon" "fnt" "pfb" "pfm" "ttf" "otf"))
    (dired-rainbow-define partition "#e3342f" ("dmg" "iso" "bin" "nrg" "qcow" "toast" "vcd" "vmdk" "bak"))
    (dired-rainbow-define vc "#0074d9" ("git" "gitignore" "gitattributes" "gitmodules"))
    (dired-rainbow-define-chmod executable-unix "#38c172" "-.*x.*")
    ))
(use-package dockerfile-mode
  :defer t

  :mode ("Dockerfile$" . dockerfile-mode)
  )
(use-package doom-modeline
  :straight t
  :defer t
  :hook (after-init . (lambda ()
                        (when (display-graphic-p)
                          (doom-modeline-mode 1)))))
(use-package editorconfig
  :diminish
  :config
  (editorconfig-mode 1))
(use-package eldoc
  :config
  (global-eldoc-mode t))
(use-package envrc
  :hook (after-init . envrc-global-mode)
  :mode ("\\.envrc\\'" . conf-toml-mode)
  :bind ("C-c e r" . 'envrc-reload)
  )
(use-package expand-region
  :defer t
  :bind ("C-=" . er/expand-region))
;; (setq fast-but-imprecise-scrolling t
;;       jit-lock-defer-time 0)
(use-package ultra-scroll
  :custom
  (scroll-conservatively 101) ;; important!
  (scroll-margin 0)
  :straight (:host github :repo "jdtsmith/ultra-scroll")
  :commands ultra-scroll-mode
  :init
  (me/run-after-startup-idle
   1
   (lambda ()
     (when (require 'ultra-scroll nil t)
       (ultra-scroll-mode 1)))))
(use-package flymake
  :straight (:type built-in)
  :defer t
  :bind (:map flymake-mode-map
              ("M-n" . flymake-goto-next-error)
              ("M-p" . flymake-goto-prev-error)
              ("C-c ! l" . flymake-show-buffer-diagnostics)
              ("C-c ! p" . flymake-show-project-diagnostics)))
(use-package flyspell
  :defer t
  :delight
  :hook ((prog-mode . (lambda () (setq flyspell-prog-text-faces
                                       (delq 'font-lock-string-face
                                             flyspell-prog-text-faces))))
         (text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode))
  :custom
  (flyspell-issue-welcome-flag nil))
(use-package persistent-soft
  :defer t
  )
(use-package unicode-fonts
  :defer t
  :if (display-graphic-p)
  :after persistent-soft
  :init
  (me/run-after-startup-idle
   4
   (lambda ()
     (when (require 'unicode-fonts nil t)
       (unicode-fonts-setup)))))
(use-package fira-code-mode
  :defer t
  :custom (fira-code-mode-disabled-ligatures '("[]" "#{" "#(" "#_" "#_(" "x")) ;; List of ligatures to turn off
  :delight
  :if (display-graphic-p)
  :hook
  (prog-mode . fira-code-mode)
  (org-mode . fira-code-mode)
  (text-mode . fira-code-mode)
  :config
  (fira-code-mode-set-font)
  )
(use-package format-all
  :defer t
  :hook (prog-mode . format-all-mode)
  :commands (format-all-buffer format-all-region-or-buffer format-all-mode)
  :diminish
  )
(use-package git-modes
  :defer t
  )
(use-package diff-hl
  :hook ((dired-mode . diff-hl-dired-mode-unless-remote)
         (magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :commands (global-diff-hl-mode diff-hl-margin-mode)
  :init
  (me/run-after-startup-idle
   3
   (lambda ()
     (when (require 'diff-hl nil t)
       (global-diff-hl-mode 1)
       (diff-hl-margin-mode))))
  ;; :custom
  ;; (diff-hl-disable-on-remote t)
  )
(use-package gdscript-mode
  :defer t
  :mode
  ("\\.godot\\'" . conf-mode)
  :custom
  (gdscript-mode-indent-offset 4)
  (indent-tabs-mode nil)
  )
(use-package graphviz-dot-mode
  :defer t
  :custom
  (graphviz-dot-indent-width 2)
  )
(use-package helm
  :defer t
  :bind (("M-x"     . helm-M-x) ;; Evaluate functions
         ("C-x C-f" . helm-find-files) ;; Open or create files
         ("C-x b"   . helm-mini) ;; Select buffers
         ("C-x C-r" . helm-recentf) ;; Select recently saved files
         ("C-c i"   . helm-imenu) ;; Select document heading
         ("M-y"     . helm-show-kill-ring)
         :map helm-map
         ;; ("<tab>" . helm-execute-persistent-action)
         )
  :custom
  (helm-always-two-windows nil)
  (helm-autoresize-max-height 0)
  (helm-autoresize-min-height 20)
  (helm-echo-input-in-header-line t)
  (helm-ff-file-name-history-use-recentf t)
  (helm-ff-search-library-in-sexp t) ;; search for library in `require' and `declare-function' sexp.
  (helm-move-to-line-cycle-in-source t) ;; move to end or beginning of source when reaching top or bottom of source.
  (helm-split-window-in-side-p t) ;; open helm buffer inside current window, not occupy whole other window
  (helm-M-x-show-short-doc t)
  (helm-M-x-fuzzy-match t)
  (helm-candidate-number-limit 20)
  :config
  ;; (define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action) ; rebind tab to run persistent action
  (define-key helm-map (kbd "C-i") 'helm-execute-persistent-action) ; make TAB work in terminal
  (define-key helm-map (kbd "C-z") 'helm-select-action) ; list actions using C-z

  (autoload 'dired-jump "dired-x"
    "Jump to Dired buffer corresponding to current buffer." t)

  (autoload 'dired-jump-other-window "dired-x"
    "Like \\[dired-jump] (dired-jump) but in other window." t)

  (define-key global-map "\C-x\C-j" 'dired-jump)
  (define-key global-map "\C-x4\C-j" 'dired-jump-other-window)
  (helm-ff-icon-mode)
  (helm-adaptive-mode)
  (helm-autoresize-mode))
(use-package helm-ag
  :defer t
  :custom
  (helm-ag-base-command "rg --color=never --line-number --with-filename --no-heading --ignore-case")
  :bind
  ("C-c a a" . helm-do-ag)
  ("C-c a p" . helm-do-ag-project-root)
  ("C-c a g" . helm-do-grep-ag)
  )
(use-package helpful
  :defer t
  :bind (("C-h c" . helpful-key)
         ("C-h f" . helpful-callable)
         ("C-h p" . helpful-at-point)
         ("C-h v" . helpful-variable)
         ("C-h x" . helpful-command))
  :config
  (add-to-list 'display-buffer-alist
               '("*[Hh]elp"
                 (display-buffer-reuse-mode-window
                  display-buffer-pop-up-window))))
(use-package hideshow
  :delight
  :defer t
  :hook
  ;; Enable hideshow only in programming modes
  (prog-mode . hs-minor-mode)
  ;; If a fundamental-mode buffer was saved with hideshow, disable it here:
  (fundamental-mode . (lambda ()
                        (when hs-minor-mode
                          (hs-minor-mode -1))))
  :bind (("C-c C-q" . hs-toggle-hiding)
         ("C-c C--" . hs-hide-all)
         ("C-c C-+" . hs-show-all))
  :custom
  ;; Automatically open a folded block if your search matches inside it
  (hs-isearch-open t "Open a block when matching in isearch")
  :config
  (setq hs-special-modes-alist
        (mapcar 'purecopy
                '((c-mode         "{" "}" "/[*/]" nil nil)
                  (c++-mode       "{" "}" "/[*/]" nil nil)
                  (java-mode      "{" "}" "/[*/]" nil nil)
                  (js-mode        "{" "}" "/[*/]" nil)
                  (json-mode      "{" "}" "/[*/]" nil)
                  (javascript-mode "{" "}" "/[*/]" nil)))))
(use-package hungry-delete
  :delight
  :commands global-hungry-delete-mode
  :custom
  (hungry-delete-join-reluctantly 1)
  :init
  (me/run-after-startup-idle
   2
   (lambda ()
     (when (require 'hungry-delete nil t)
       (global-hungry-delete-mode 1)))))
(use-package ibuffer
  :ensure nil
  :straight (:type built-in)
  :defer nil
  :bind ("C-x C-b" . ibuffer))
(use-package iedit
  :defer t
  :bind ("C-:" . iedit-mode)
  )
(use-package info-colors
  :defer t
  :config
  (add-hook 'Info-selection-hook 'info-colors-fontify-node))
(use-package ini-mode
  :defer t
  :mode ("\\.ini\\'" . conf-toml-mode)
  )
(use-package ispell
  :straight (:type built-in)
  :bind (("C-c s w" . ispell-word)
         ("C-c s r" . ispell-region)
         ("C-c s d" . ispell-change-dictionary))
  )
(use-package guess-language
  :defer t
  :hook (text-mode . guess-language-mode)
  :config
  (setq guess-language-languages '(en da)
                guess-language-min-paragraph-length 35)
  )
(use-package js2-mode
  :defer t
  :interpreter (("node" . js2-mode))
  :config
  (add-hook 'js-mode-hook #'js2-minor-mode)
  (add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
  (add-to-list 'auto-mode-alist '("\\.json$" . js2-mode))
  :custom
  (js-basic-offset 0)
  (js2-basic-offset 2)
  )
(use-package json-mode
  :defer t
  :custom
  (js-indent-level 2))
(use-package just-mode
  :defer t
  :mode (("justfile\\'" . just-mode)
         ("Justfile\\'" . just-mode)))
(use-package latex
  :defer t
  :straight (:type built-in)
  :mode ("\\.tex\\'$" . latex-mode)
  :custom
  (LaTeX-electric-left-right-brace t)
  (TeX-PDF-mode t)
  (TeX-auto-save t)
  (TeX-electric-math (cons "$" "$"))
  (TeX-parse-self t)
  (TeX-source-correlate-method 'synctax)
  (TeX-source-correlate-mode t)
  (TeX-source-correlate-start-server nil)
  (TeX-syntactic-comment t)
  (reftex-plug-into-AUCTeX t)
  (TeX-view-program-list
   '(("DVI Viewer" "open %o")
     ("PDF Viewer" "open %o")
     ("HTML Viewer" "open %o")))
  :hook
  (latex-mode . (lambda ()
                  (tool-bar-mode 1)))
  )

;; AUCTeX configuration
(use-package auctex
  :defer t
  :mode ("\\.tex\\'" . latex-mode)
  :custom
  ;; Enable parsing
  (TeX-auto-save t)
  (TeX-parse-self t)
  ;; Default PDF viewer
  (TeX-view-program-selection '((output-pdf "PDF Viewer")))
  ;; Use pdf-tools to open PDF files
  (TeX-view-program-list '(("PDF Viewer" "pdf-tools %o")))
  ;; Enable TeX-fold-mode automatically in TeX/LaTeX mode
  (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
  ;; Configure RefTeX with AUCTeX
  (reftex-plug-into-AUCTeX t)
  :hook
  (TeX-mode-hook . (lambda () (TeX-fold-mode 1)))
  ;; Enable RefTeX in AUCTeX
  (LaTeX-mode-hook . turn-on-reftex)
  ;; Configure RefTeX with AUCTeX
  (LaTeX-mode-hook . reftex-plug-into-AUCTeX)
  )

;; LaTeX completion via cape and auctex
;; Note: AUCTeX provides its own completion via TeX-complete-symbol
;; which works with corfu through completion-at-point-functions

(use-package reftex
  :defer t
  :custom
  (reftex-cite-prompt-optional-args t)) ; Prompt for empty optional arguments in cite
(use-package eglot
  :straight (:type built-in)
  :commands (eglot eglot-ensure)
  :init
  (when (boundp 'eglot-documentation-renderer)
    (setq eglot-documentation-renderer 'markdown-ts-view-mode))
  (when (boundp 'eglot-code-action-indications)
    (setq eglot-code-action-indications nil))
  :hook
  ((conf-toml-mode . eglot-ensure)
   (css-mode . eglot-ensure)
   (just-mode . eglot-ensure)
   (latex-mode . eglot-ensure)
   (markdown-mode . eglot-ensure)
   (nix-mode . eglot-ensure)
   (python-base-mode . eglot-ensure)
   (sh-mode . eglot-ensure)
   (toml-mode . eglot-ensure)
   (typst-mode . eglot-ensure)
   (typescript-mode . eglot-ensure)
   (yaml-mode . eglot-ensure))
  :bind
  (:map eglot-mode-map
        ("C-M-<mouse-2>" . eglot-code-actions-at-mouse)
        ("C-c l a" . eglot-code-actions)
        ("C-c l d" . eldoc)
        ("C-c l f" . eglot-format)
        ("C-c l o" . eglot-code-action-organize-imports)
        ("C-c l q" . eglot-code-action-quickfix)
        ("C-c l r" . eglot-rename)
        ("C-c l s" . imenu))
  :custom
  (eglot-autoshutdown t)
  (eglot-confirm-server-initiated-edits nil)
  (eglot-events-buffer-config '(:size 0 :format lisp))
  :config
  (dolist (server
           '(((conf-toml-mode toml-mode) . ("taplo" "lsp" "stdio"))
             ((typst-mode typst--markup-mode typst--code-mode) . ("tinymist"))
             (just-mode . ("just-lsp"))
             (sh-mode . ("bash-language-server" "start"))
             (typescript-mode . ("vtsls" "--stdio"))
             (nix-mode . ("nixd"))
             (markdown-mode . ("marksman" "server"))
             (python-base-mode . ("rass" "--" "ty" "server" "--" "ruff" "server"))
             )
           )
    (add-to-list 'eglot-server-programs server))
   (add-to-list 'eglot-server-programs '(yaml-mode . ("yaml-language-server" "--stdio"))))
(use-package dape
  :defer t
  :bind (("C-c d d" . dape)
         ("C-c d b" . dape-breakpoint-toggle)
         ("C-c d c" . dape-continue)
         ("C-c d n" . dape-next)
         ("C-c d i" . dape-step-in)
         ("C-c d o" . dape-step-out)))
(use-package magit
  :after magit-gitflow
  :defer t
  :hook (magit-mode . turn-on-magit-gitflow)
  :bind ("C-x g" . magit-status)
  :custom
  (magit-process-finish-apply-ansi-colors t)
  (magit-process-log-max 100)
  )

(use-package magit-boost
  :straight (:host github :repo "jeremy-compostella/magit-boost" :files ("magit-boost.el"))
  :config
  (setq magit-boost-mode 1
        magit-boost-progress-mode 1))
(use-package magit-todos
  :after magit
  :config (magit-todos-mode 1)
  )
(use-package magit-gitflow
  :defer t
  :hook (magit-status-mode . turn-on-magit-gitflow)
  )
(use-package make-mode
  :defer t
  :ensure nil
  :mode (("Makefile\\'" . makefile-mode)
         ("\\.mk\\'" . makefile-mode))
  :hook (makefile-mode . (lambda ()
                           (setq indent-tabs-mode t)))  ;; Use tabs for indentation
  :custom
  (makefile-indent-level 4 "Indentation level in makefile-mode")
  (tab-width 4 "Set the width of a tab to 4 spaces"))

(use-package cmake-mode
  :defer t
  :mode (("CMakeLists\\.txt\\'" . cmake-mode)
         ("\\.cmake\\'" . cmake-mode))
  )
(use-package man
  :defer t
  :ensure nil
  :config
  (set-face-attribute 'Man-overstrike nil :inherit font-lock-type-face :bold t)
  (set-face-attribute 'Man-underline nil :inherit font-lock-keyword-face :underline t))
(use-package markdown-mode
  :defer t
  :commands (gfm-mode markdown-mode)
  :bind
  (("M-<right>" . markdown-demote)
   ("M-<left>" . markdown-promote)
   ("M-<return>" . markdown-insert-header-dwim))

  :mode
  (("README\\.md\\'" . gfm-mode)
   ("\\.md\\'" . markdown-mode)
   ("\\.markdown\\'" . markdown-mode))
  :custom
  (markdown-header-scaling t)
  (markdown-hide-urls t)
  (markdown-hide-markup nil) ;; hiding makes editing harder but is nice for reading
  (markdown-fontify-code-blocks-natively t)

  :config
  ;; Custom function to insert a mailto link without showing "mailto:"
  (defun insert-mailto-link ()
    "Replace the email address at point or in the selected region with a Markdown mailto link."
    (interactive)
    (let ((email (if (use-region-p)
                     (buffer-substring-no-properties (region-beginning) (region-end))
                   (thing-at-point 'email))))
      (if email
          (progn
            (when (use-region-p)
              (delete-region (region-beginning) (region-end)))
            (insert (format "[%s](mailto:%s)" email email)))
        (message "No valid email address found at point or in region."))))
  (defun insert-tel-link ()
    "Replace the phone number at point or in the selected region with a Markdown tel link."
    (interactive)
    (let ((phone (if (use-region-p)
                     (buffer-substring-no-properties (region-beginning) (region-end))
                   (thing-at-point 'phone))))
      (if phone
          (let ((cleaned-phone (replace-regexp-in-string "[^0-9+]" "" phone)))
            (when (use-region-p)
              (delete-region (region-beginning) (region-end)))
            (insert (format "[%s](tel:%s)" cleaned-phone cleaned-phone)))
        (message "No valid phone number found at point or in region."))))
  )
(use-package markdown-toc
  :defer t
  )
(use-package mermaid-mode
  :defer t)
(use-package buffer-move
  :defer t
  :bind (("C-c m r" . 'buf-move-right)
         ("C-c m l" . 'buf-move-left)
         ("C-c m u" . 'buf-move-up)
         ("C-c m d" . 'buf-move-down)))
(use-package multiple-cursors
  :defer t
  :commands multiple-cursors-mode
  :bind (("H-SPC" . set-rectangular-region-anchor)
         ("C-M-SPC" . set-rectangular-region-anchor)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C->" . mc/mark-all-like-this)
         ))
(use-package nix-mode
  :defer t
  :mode (rx ".nix" eos))
(use-package nixpkgs-fmt
  :defer t
  :hook (nix-mode . nixpkgs-fmt-on-save-mode))
(use-package pretty-sha-path
  :defer t
  :hook
  (shell-mode . pretty-sha-path-mode)
  (dired-mode . pretty-sha-path-mode))
(use-package no-littering
  :demand t
  :config
  (setq
   auto-save-file-name-transforms
   `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  (setq custom-file (no-littering-expand-etc-file-name "custom.el"))
  (when (file-exists-p custom-file)
    (load custom-file)))
(use-package ob-mermaid
  :defer t)
(use-package org
  :straight (:type built-in)
  :defer t
  :delight
  :mode ("\\.org\\'" . org-mode)
  :commands (org-agenda org-babel-load-file org-capture org-mode org-store-link)
  :custom
  (org-agenda-files "~/dropbox-private/Documents/RoamNotes")
  (org-cycle-separator-lines -1)
  (org-edit-src-content-indentation 0)       ;; Spaces from #+BEGIN_SRC
  (org-fontify-quote-and-verse-blocks t)     ;; Highlight quotes
  (org-hide-emphasis-markers t)              ;; hide emphasize marker
  (org-hierarchical-checkbox-statistics nil) ;; Recursively count checkboxes
  (org-hierarchical-todo-statistics nil)     ;; Recursively count todos
  (org-pretty-entities t)
  (org-src-fontify-natively t)               ;; pretty source code fontification
  (org-src-preserve-indentation t)
  (org-src-strip-leading-and-trailing-blank-lines t)
  (org-src-tab-acts-natively t)              ;; Native code block indentation
  (org-src-window-setup 'other-window)
  (org-startup-with-inline-images t)         ;; inline images when loading a new Org file

  (org-file-apps
   (quote
    ((auto-mode . emacs)
     ("\\.mm\\'" . default)
     ("\\.x?html?\\'" . "/usr/bin/env firefox %s")
     ("\\.pdf\\'" . default)))
   )
  (org-export-backends '(ascii html icalendar pandoc))     ;; Set export backends
  :config
  (let ((org-babel-languages '((shell . t)
                               (python . t)
                               (C . t))))
    (when (require 'ob-mermaid nil t)
      (push '(mermaid . t) org-babel-languages))
    (org-babel-do-load-languages
     'org-babel-load-languages
     org-babel-languages))
  )
(use-package org-modern
  :straight (org-modern :type git :host github :repo "minad/org-modern")
  :defer t
  :custom
  ;; Edit settings
  (org-auto-align-tags nil)
  (org-tags-column 0)
  (org-catch-invisible-edits 'show-and-error)
  (org-special-ctrl-a/e t)
  (org-insert-heading-respect-content t)

  ;; Org styling, hide markup etc.
  (org-hide-emphasis-markers t)
  (org-pretty-entities t)

  ;; Agenda styling
  (org-agenda-tags-column 0)
  (org-agenda-block-separator ?─)
  (org-agenda-time-grid
   '((daily today require-timed)
     (800 1000 1200 1400 1600 1800 2000)
     " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"))
  (org-agenda-current-time-string
   "◀── now ─────────────────────────────────────────────────")
  (org-ellipsis "…")
  :custom-face
  (org-ellipsis ((t (:inherit default :box nil))))
  :hook
  (org-mode . org-modern-mode)
  )
(use-package org-download
  :hook
  (org-mode . org-download-enable)
  (dired-mode . org-download-enable))
(use-package helm-roam
  :defer t
  :bind (
         ("C-c n f" . helm-roam)
         ("C-c n i" . helm-roam-action-insert))
  )
(use-package ox-twbs
  :defer t)
(use-package ox-pandoc
  :defer t)
(use-package pdf-tools
  :defer t
  :config
  (pdf-tools-install)
  :custom
  (pdf-view-display-size 'fit-page)
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :hook (pdf-view-mode . (lambda () (display-line-numbers-mode -1)))
  :bind (:map pdf-view-mode-map
              ;; Custom keybindings for navigating in pdf-view-mode
              ("C-s" . isearch-forward)
              ("C-r" . isearch-backward)
              ("C-n" . pdf-view-next-page-command)
              ("C-p" . pdf-view-previous-page-command)))
(use-package powershell
  :defer t
  :mode
  ("\\.ps1" . powershell-mode))
(use-package projectile
  :defer t
  :commands (projectile-project-root projectile-find-file projectile-switch-project))
(use-package python
  :defer t
  :ensure nil  ;; since python mode is built-in
  :init
  (add-to-list 'process-coding-system-alist '("python" . (utf-8 . utf-8)))
  :config
  (defun pretty-python-code ()
    (interactive)
    (call-interactively 'pyimport-remove-unused)
    (call-interactively 'python-isort-buffer)
    (call-interactively 'python-black-buffer))
  :if (executable-find "ipython")
  :custom
  ;; (python-shell-interpreter "ipython")
  (python-indent-offset 4)
  )
(use-package elpy
  :defer t
  ;; :hook (python-mode . elpy-enable)
  )
(use-package poetry
  :defer t)
(use-package snakemake-mode
  :defer t
  :mode (("Snakefile\\'" . snakemake-mode)
         ("snakefile\\'" . snakemake-mode)
         ("\\.smk\\'" . snakemake-mode)))
(use-package pyvenv
  :defer t
  :hook
  (python-mode . pyvenv-mode)
  :config
  (pyvenv-tracking-mode 1)
  )
(use-package rainbow-delimiters
  :defer t
  :hook ((org-mode . rainbow-delimiters-mode)
         (prog-mode . rainbow-delimiters-mode)))
(use-package highlight-indent-guides
  :hook (prog-mode . highlight-indent-guides-mode)
  :custom
  (highlight-indent-guides-responsive 'stack))
(use-package restart-emacs
  :defer t)
(use-package rst
  :defer t)
(use-package sh-mode
  :defer t
  :straight (:type built-in)
  :hook (sh-mode . (lambda ()  (setq sh-basic-offset 2
                                     indent-tabs-mode nil)))
  )
;; A more complex, more lazy-loaded config
(use-package solaire-mode
  :defer t
  :hook
  ;; Ensure solaire-mode is running in all solaire-mode buffers
  (change-major-mode . turn-on-solaire-mode)
  ;; ...if you use auto-revert-mode, this prevents solaire-mode from turning
  ;; itself off every time Emacs reverts the file
  (after-revert . turn-on-solaire-mode)
  ;; To enable solaire-mode unconditionally for certain modes:
  (ediff-prepare-buffer . solaire-mode)
  :custom
  (solaire-mode-auto-swap-bg t)
  :commands solaire-global-mode
  :init
  (me/run-after-startup-idle
   3
   (lambda ()
     (when (require 'solaire-mode nil t)
       (solaire-global-mode +1)))))
(use-package tramp
  :defer t
  :custom
  (tramp-default-method "ssh")
  (tramp-use-ssh-controlmaster-options nil)
  (tramp-chunksize 500)
  (tramp-use-connection-share nil)
  :config
  (let ((ssh-configs (append (seq-filter #'file-exists-p (list "~/.ssh/config"))
                             (when (file-directory-p "~/.ssh/conf.d/")
                               (directory-files-recursively "~/.ssh/conf.d/" "\\.config$")))))
    ;; Log the detected SSH config files to the *tramp-info* buffer
    (with-current-buffer (get-buffer-create "*tramp-info*")
      (insert (format "Found SSH config files: %s\n" ssh-configs)))

    ;; Append the SSH config completion functions
    (tramp-set-completion-function
     "ssh" (append (tramp-get-completion-function "ssh")
                   (mapcar (lambda (file) `(tramp-parse-sconfig file)) ssh-configs)))))
(use-package ssh-config-mode
  :defer t
  )
(use-package systemd
  :defer t
  :mode
  ("\\.service\\'" . systemd-mode)
  ("\\.timer\\'" . systemd-mode)
  ("\\.target\\'" . systemd-mode)
  ("\\.mount\\'" . systemd-mode)
  ("\\.automount\\'" . systemd-mode)
  ("\\.slice\\'" . systemd-mode)
  ("\\.socket\\'" . systemd-mode)
  ("\\.path\\'" . systemd-mode)
  ("\\.netdev\\'" . systemd-mode)
  ("\\.network\\'" . systemd-mode)
  ("\\.link\\'" . systemd-mode))
(use-package doom-themes
  :config
  (doom-themes-org-config))

(defun me/load-theme-safely (theme &optional fallback)
  "Load THEME and fall back to FALLBACK without leaving partial theme state."
  (condition-case err
      (load-theme theme t)
    (error
     (message "Failed to load %s theme: %s" theme err)
     (mapc #'disable-theme custom-enabled-themes)
     (when fallback
       (condition-case fallback-err
           (load-theme fallback t)
         (error
          (message "Failed to load fallback %s theme: %s" fallback fallback-err)
          (mapc #'disable-theme custom-enabled-themes)))))))

(if (>= emacs-major-version 31)
    (me/load-theme-safely 'modus-vivendi)
  (me/load-theme-safely 'doom-xcode 'modus-vivendi))
(use-package emacs-snazzy
  :straight (:host github :repo "weijiangan/emacs-snazzy" :files ("*.el"))
  :defer t
  :requires base16-theme
  ;; :config
  ;; (load-theme 'snazzy t)
  )

(use-package base16-theme
  :defer t
  :straight t)
(use-package titlecase
  :defer t
  :bind ("C-c t" . my-titlecase-dwim))

(defun my-titlecase-dwim ()
  "Titlecase the region, or the current line if no region is active."
  (interactive)
  (if (use-region-p)
      (titlecase-region (region-beginning) (region-end))
    (let ((beg (line-beginning-position))
          (end (line-end-position)))
      (titlecase-region beg end))))
(use-package treemacs
  :defer t
  :commands treemacs
  :bind ([f10] . treemacs)
  :config
  (treemacs-git-mode 'deferred)
  (treemacs-project-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-git-commit-diff-mode t)
  (treemacs-indent-guide-mode t))

(use-package treemacs-magit
  :defer t
  :after treemacs-magit)

(use-package treemacs-all-the-icons
  :defer t
  :after all-the-icons treemacs
  :config
  (treemacs-load-theme "all-the-icons")
  )
(use-package typst-mode
  :mode ("\\.typ\\'" . typst-mode)
  :straight (:type git :host github :repo "Ziqi-Yang/typst-mode.el")
  :custom
  (typst-basic-offset 2)
  )
(use-package typescript-mode
  :defer t
  :mode (("\\.ts\\'" . typescript-mode)
         ("\\.tsx\\'" . typescript-mode)))
(use-package vlf
  :ensure t
  :init (require 'vlf-setup)
  :custom
  (vlf-batch-size (* 100 1024 1024))
  (vlf-application 'dont-ask)
  )
(defun get-wakatime-api-key ()
  "Get Wakatime API key from .wakatime.cfg file."
  (let ((wakacfg (expand-file-name "~/.wakatime.cfg")))
    (when (file-exists-p wakacfg)
      (with-temp-buffer
        (insert-file-contents wakacfg)
        (goto-char (point-min))
        (when (re-search-forward "^api_key\\s-*=\\s-*\\(.+\\)$" nil t)
          (match-string 1))))))

(use-package wakatime-mode
  :defer t
  :commands global-wakatime-mode
  :init
  ;; Use expand-file-name to ensure correct user, or omit if in PATH
  (setq wakatime-cli-path (expand-file-name "~/.nix-profile/bin/wakatime-cli"))
  (setq wakatime-api-key (get-wakatime-api-key))
  (me/run-after-startup-idle
   5
   (lambda ()
     (when (require 'wakatime-mode nil t)
       (global-wakatime-mode 1))))
  :diminish
  )
(use-package webpaste
  :defer t
  :bind (
         ("C-c p b" . webpaste-paste-buffer)
         ("C-c p r" . webpaste-paste-region)
         ("C-c p p" . webpaste-paste-buffer-or-region))

  :config (setq webpaste-provider-priority '("dpaste.org")))
(use-package which-key
  :diminish
  :defer t
  :commands which-key-mode
  :init
  (me/run-after-startup-idle
   2
   (lambda ()
     (when (require 'which-key nil t)
       (which-key-mode)
       (which-key-setup-minibuffer)
       (set-face-attribute
        'which-key-local-map-description-face nil :weight 'bold))))
  :custom
  (which-key-idle-delay 2)
  (which-key-show-remaining-keys t)
  )
(use-package why-this
  :defer t
  :bind ("C-c w t" . why-this)
  :config ())
(use-package yaml-mode
  :defer t
  :mode
  ("\\.yml\\'" . yaml-mode)
  ("\\.yaml\\'" . yaml-mode))
(use-package yasnippet
  :delight yas
  :defer t
  :commands (yas-minor-mode yas-global-mode yas-expand)
  :hook ((prog-mode text-mode org-mode) . yas-minor-mode)
  :custom
  (yas-prompt-functions '(yas-completing-prompt))
  (yas-snippet-dirs '("~/.config/home-manager/dotfiles/emacs/yasnippet/snippets")))
(use-package yasnippet-snippets
  :after yasnippet
  :defer t
  :config
  (yasnippet-snippets-initialize)
  )
