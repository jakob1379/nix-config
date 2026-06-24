;;; early-init.el --- Early startup settings -*- lexical-binding: t; -*-

;;; Commentary:
;; Settings Emacs must see before package and frame initialization.

;;; Code:

(setq package-enable-at-startup nil
      native-comp-async-report-warnings-errors nil
      site-run-file nil
      frame-inhibit-implied-resize t
      inhibit-compacting-font-caches t)

(when (boundp 'native-comp-async-on-battery-power)
  (setq native-comp-async-on-battery-power nil))

;;; early-init.el ends here
