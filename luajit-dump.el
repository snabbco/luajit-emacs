;;; luajit-dump.el -- LuaJIT dump reading mode
;; Created by Luke Gorrie <luke@snabb.co> in December 2014.

;; Major mode for viewing LuaJIT compiler traces. Based on outline-mode.
;;
;; Supports deriving an outline-mode structure and simple
;; cross-referencing with source files.
;;
;; To use:
;;
;;   `M-x luajit-dump-mode'
;;
;;   Use standard outline-mode commands to fold and navigate.
;;
;;   `C-c C-c' to show source file referenced in a trace line.
;;
;; Screenshot:
;;   http://lukego.tumblr.com/post/105010736106
;; Format description:
;;   http://wiki.luajit.org/SSA-IR-2.0#Example-IR-Dump

;; This program is free software; you can redistribute it and/or 
;; modify it under the terms of the GNU General Public License 
;; as published by the Free Software Foundation; either version 2 
;; of the License, or (at your option) any later version.

(require 'outline)
(require 'find-recursive)

(defgroup luajit-dump nil
  "LuaJIT jit.dump trace viewing"
  :prefix "luajit-dump-"
  :group 'tools)

(defcustom luajit-dump-source-directory nil
  "Directory to search for source files.
Default to the current directory."
  :type '(choice (const nil) directory))

(defvar luajit-dump-mode-map (make-sparse-keymap)
  "Keymap used in LuaJIT dump viewing mode.")

(define-key luajit-dump-mode-map "\C-c\C-c" 'luajit-dump-find-file)

(define-derived-mode luajit-dump-mode outline-mode "LuaJIT dump"
  "Major mode for viewing LuaJIT jit.dump files.

This mode is a derivative of `outline-mode`."
  (set (make-local-variable 'outline-regexp) "---- TRACE")
  (set (make-local-variable 'outline-level) 'luajit-dump-outline-level)
  (use-local-map luajit-dump-mode-map)
  (hide-sublevels 1))

(defun luajit-dump-outline-level ()
  "Return the heading level for the current line.
Trace start lines are level 1 and other lines are level 2."
  (or (and (looking-at "---- TRACE \[0-9\]+ start ") 1)
      2))

(defun luajit-dump-find-file ()
  "Find the file and line for the trace on the current line.
Search `luajit-dump-source-directory' recursively for the filename.

Example line that this command can be used on:
    ---- TRACE 167 start link.lua:31"
  (interactive)
  (save-excursion
    (beginning-of-line)
    (unless (looking-at "^[^\n]*\\s \\([^\\s ]+\\.lua\\):\\([0-9]+\\)")
      (error "No <filename>.lua:<line> pattern found on current line"))
    (let ((filename (match-string-no-properties 1))
	  (line (string-to-number (match-string-no-properties 2)))
	  (dir (or luajit-dump-source-directory
		   default-directory)))
      (with-current-buffer
	  (save-window-excursion
	    (find-file-recursively
	     (concat "^" (regexp-quote filename)) dir)
	    (current-buffer))
	(save-selected-window
	  (pop-to-buffer (current-buffer))
	  (goto-line line)
	  (recenter)
	  ;; XXX Cleanup the overlay arrow somehow? -lukego
	  (setq overlay-arrow-string "=>"
		overlay-arrow-position (point-marker)))))))

(add-to-list 'auto-mode-alist '("\\.ljdump$" . luajit-dump-mode))

(provide 'luajit-dump)
