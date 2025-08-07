;;; evie.el --- Emacs View-mode Improved Editing (Baby-proof Emacs) -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: Your Name <your.email@example.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: convenience, editing, modal, navigation
;; URL: https://github.com/yourusername/evie

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; EVIE (Emacs View-mode Improved Editing) provides a baby-proof modal editing
;; experience built on top of Emacs' built-in view-mode. It combines familiar
;; Emacs navigation with efficient Vim-style keybindings while protecting your
;; files from accidental modifications.

;; Features:
;; - Enhanced view-mode with ergonomic keybindings
;; - Baby-proof file protection (files open in read-only by default)
;; - Visual feedback with cursor changes
;; - Smart integration with common Emacs workflows
;; - Customizable behavior for different modes and file types

;; Quick start:
;; 1. (require 'evie)
;; 2. (evie-mode 1)
;; 3. Use 'i' to enter edit mode, C-<tab> to return to view mode

;;; Code:

(require 'view)

;;; Customization

(defgroup evie nil
  "Emacs View-mode Improved Editing - Baby-proof modal editing."
  :group 'convenience
  :prefix "evie-")

(defcustom evie-auto-view-files t
  "When non-nil, automatically enable view-mode for opened files."
  :type 'boolean
  :group 'evie)

(defcustom evie-return-to-view-after-save t
  "When non-nil, return to view-mode after saving a file."
  :type 'boolean
  :group 'evie)

(defcustom evie-visual-feedback t
  "When non-nil, change cursor type to indicate current mode."
  :type 'boolean
  :group 'evie)

(defcustom evie-scroll-lines 3
  "Number of lines to scroll with u/d keys."
  :type 'integer
  :group 'evie)

(defcustom evie-excluded-modes
  '()
  "Major modes where EVIE should not auto-enable view-mode."
  :type '(repeat symbol)
  :group 'evie)

(defcustom evie-mode-line-indicator " 👶"
  "Mode line indicator for when EVIE view-mode is active."
  :type 'string
  :group 'evie)

;;; Internal Variables

(defvar evie--original-cursor-type nil
  "Store original cursor type to restore when disabling EVIE.")

(defvar evie--keybindings-applied nil
  "Track whether custom keybindings have been applied.")

;;; Core Functions

(defun evie--apply-keybindings ()
  "Apply EVIE keybindings to view-mode-map."
  (when (and (boundp 'view-mode-map) (not evie--keybindings-applied))
    ;; Emacs-style navigation (without modifiers)
    (define-key view-mode-map (kbd "n") 'next-line)
    (define-key view-mode-map (kbd "p") 'previous-line)
    (define-key view-mode-map (kbd "f") 'forward-char)
    (define-key view-mode-map (kbd "b") 'backward-char)
    (define-key view-mode-map (kbd "a") 'beginning-of-line)
    (define-key view-mode-map (kbd "-") 'end-of-line)
    (define-key view-mode-map (kbd "e") 'end-of-line)
    (define-key view-mode-map (kbd ",") 'beginning-of-buffer)
    (define-key view-mode-map (kbd ".") 'end-of-buffer)
    (define-key view-mode-map (kbd "y") 'evie-scroll-down)
    (define-key view-mode-map (kbd "i") 'evie-enter-edit-mode)
    (define-key view-mode-map (kbd "SPC") 'evie-scroll-down)
    (define-key view-mode-map (kbd "[") 'tab-bar-switch-to-prev-tab)
    (define-key view-mode-map (kbd "]") 'tab-bar-switch-to-next-tab)
    (define-key view-mode-map (kbd "x") 'delete-char)
    (define-key view-mode-map (kbd "v") 'View-scroll-page-forward)
    ;; Vim-style navigation
    (define-key view-mode-map (kbd "j") 'next-line)
    (define-key view-mode-map (kbd "k") 'previous-line)
    (define-key view-mode-map (kbd "h") 'backward-char)
    (define-key view-mode-map (kbd "l") 'forward-char)
    (define-key view-mode-map (kbd "0") 'beginning-of-line)
    (define-key view-mode-map (kbd "$") 'end-of-line)
    
    ;; Buffer navigation
    (define-key view-mode-map (kbd "g") 'beginning-of-buffer)
    (define-key view-mode-map (kbd "G") 'end-of-buffer)
    
    ;; Page scrolling
    (define-key view-mode-map (kbd "u") 'evie-scroll-up)
    (define-key view-mode-map (kbd "d") 'evie-scroll-down)
    
    ;; Mode switching
    (define-key view-mode-map (kbd "o") 'evie-enter-edit-mode)
    
    ;; Window management
    (define-key view-mode-map (kbd ";") 'other-window)
    
    ;; Disable potentially problematic keys
    (define-key view-mode-map (kbd "DEL") nil)
    ;; (define-key view-mode-map (kbd "SPC") nil)
    
    (setq evie--keybindings-applied t)))

(defun evie-scroll-up ()
  "Scroll up by `evie-scroll-lines' lines."
  (interactive)
  (View-scroll-page-backward evie-scroll-lines))

(defun evie-scroll-down ()
  "Scroll down by `evie-scroll-lines' lines."
  (interactive)
  (View-scroll-page-forward evie-scroll-lines))

(defun evie-enter-edit-mode ()
  "Exit view-mode to allow editing."
  (interactive)
  (when view-mode
    (View-exit)
    (message "EVIE: Edit mode activated")))

(defun evie-enter-view-mode ()
  "Enter view-mode for safe navigation."
  (interactive)
  (unless view-mode
    (view-mode 1)
    (message "EVIE: View mode activated - baby-proof engaged!")))

(defun evie--should-auto-enable-p ()
  "Determine if view-mode should be automatically enabled for current buffer."
  (and evie-auto-view-files
       buffer-file-name
       (not (apply 'derived-mode-p evie-excluded-modes))
       (not view-mode)))

(defun evie--setup-visual-feedback ()
  "Setup visual feedback for mode changes."
  (when evie-visual-feedback
    (setq cursor-type (if view-mode 'box 'bar))))

(defun evie--after-save-hook ()
  "Hook function to run after saving files."
  (when (and evie-return-to-view-after-save
             buffer-file-name
             (not view-mode)
             (not (apply 'derived-mode-p evie-excluded-modes)))
    (view-mode 1)))

(defun evie--find-file-hook ()
  "Hook function to run when opening files."
  (when (evie--should-auto-enable-p)
    (view-mode 1)))

(defun evie--view-mode-hook ()
  "Hook function for view-mode activation."
  (evie--setup-visual-feedback)
  (when (and view-mode evie-mode-line-indicator)
    (setq mode-line-process evie-mode-line-indicator)))

(defun evie--emergency-lockdown ()
  "Emergency function to lock down all buffers."
  (interactive)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (and buffer-file-name (not view-mode))
        (view-mode 1))))
  (message "EVIE: Emergency lockdown activated! All file buffers are now read-only."))

;;; Smart Edit Detection

(defun evie--smart-edit-command-p (command)
  "Check if COMMAND should automatically switch to edit mode."
  (memq command '(kill-line
                  yank
                  backward-delete-char-untabify
                  c-electric-backspace
                  backward-kill-word
                  indent-for-tab-command
                  my/comment-or-uncomment
                  undo
                  delete-backward-char
                  delete-char
                  newline)))

(defun evie--pre-command-hook ()
  "Pre-command hook to detect edit intentions."
  (when (and view-mode
             (evie--smart-edit-command-p this-command))
    (evie-enter-edit-mode)))

;;; Minor Mode Definition

;;;###autoload
(define-minor-mode evie-mode
  "Toggle EVIE (Emacs View-mode Improved Editing) mode.

EVIE provides baby-proof modal editing built on view-mode, combining
Emacs and Vim navigation styles while protecting files from accidental
modifications."
  :lighter " EVIE"
  :global t
  :group 'evie
  (if evie-mode
      (evie--enable)
    (evie--disable)))

(defun evie--enable ()
  "Enable EVIE mode."
  ;; Store original cursor type
  (setq evie--original-cursor-type cursor-type)
  
  ;; Enable view-read-only integration
  (setq view-read-only t)
  
  ;; Apply keybindings
  (with-eval-after-load 'view
    (evie--apply-keybindings))
  (evie--apply-keybindings)
  
  ;; Add hooks
  (add-hook 'find-file-hook 'evie--find-file-hook)
  (add-hook 'after-save-hook 'evie--after-save-hook)
  (add-hook 'view-mode-hook 'evie--view-mode-hook)
  (add-hook 'pre-command-hook 'evie--pre-command-hook)
  
  ;; Global keybindings
  (global-set-key (kbd "C-<escape>") 'evie-enter-view-mode)
  (global-set-key (kbd "C-<tab>") 'evie-enter-view-mode)
  (global-set-key (kbd "C-<return>") 'evie-enter-view-mode)
  (global-set-key (kbd "C-<backspace>") 'evie-enter-view-mode)
  (global-set-key (kbd "C-c C-l") 'evie--emergency-lockdown)
  
  (message "EVIE mode enabled - Your Emacs is now baby-proof!"))

(defun evie--disable ()
  "Disable EVIE mode."
  ;; Restore original cursor type
  (when evie--original-cursor-type
    (setq cursor-type evie--original-cursor-type))
  
  ;; Disable view-read-only integration
  (setq view-read-only nil)
  
  ;; Remove hooks
  (remove-hook 'find-file-hook 'evie--find-file-hook)
  (remove-hook 'after-save-hook 'evie--after-save-hook)
  (remove-hook 'view-mode-hook 'evie--view-mode-hook)
  (remove-hook 'pre-command-hook 'evie--pre-command-hook)
  
  ;; Remove global keybindings
  (global-unset-key (kbd "C-<tab>"))
  (global-unset-key (kbd "C-c C-l"))
  
  ;; Reset keybindings flag
  (setq evie--keybindings-applied nil)
  
  (message "EVIE mode disabled"))

;;; Interactive Commands

;;;###autoload
(defun evie-toggle-auto-view ()
  "Toggle automatic view-mode activation for files."
  (interactive)
  (setq evie-auto-view-files (not evie-auto-view-files))
  (message "EVIE auto-view %s" 
           (if evie-auto-view-files "enabled" "disabled")))

;;;###autoload
(defun evie-customize ()
  "Open EVIE customization group."
  (interactive)
  (customize-group 'evie))

(provide 'evie)

;;; evie.el ends here
