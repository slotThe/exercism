;;; exercism.el --- Interface with exercism -*- lexical-binding: t; -*-

;; Copyright (C) 2021, 2022  Tony Zorman
;;
;; Author: Tony Zorman <soliditsallgood@mailbox.org>
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))
;; Homepage: https://gitlab.com/slotThe/dotfiles

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; TODO

;;; Code:

(eval-when-compile (require 'cl-lib))

;;;; Vars

(defgroup exercism nil
  "Interface for the exercism website."
  :group 'applications)

(defcustom exercism-visit-url nil
  "Visit the respective exercism URL when submitting?"
  :group 'exercism
  :type 'boolean)

(defcustom exercism-workspace (string-remove-suffix
                               "\n"
                               (shell-command-to-string "exercism workspace"))
  "The exercism workspace path.
Defaults to what invoking \"exercism workspace\" as a shell
command would return.  When customized, invoke \"exercism
configure -w\" to also tell the command line utility about the
change of workspace."
  :group 'exercism
  :type 'string
  :set (lambda (symbol value)
         (make-process
          :name "exercism-configure"
          :command `("/bin/sh" "-c" ,(concat "exercism configure -w " value)))
         (custom-set-default symbol value)))

(defconst exercism-url "http[s]://exercism.\\(com\\|org\\|io\\)")

;;;; Functions

(defun exercism-from-selection ()
  "Return an exercism url from a selection, if possible.
First try the primary selection and then the clipboard."
  (cl-flet ((exercism-valid-url (url)
              (when-let ((valid (string-match-p exercism-url url)))
                url)))
    (or (exercism-valid-url (gui-get-primary-selection))
        (exercism-valid-url (gui-get-selection 'CLIPBOARD)))))

(defun exercism--get-lang-exercise (url)
  "From an exercism URL, get the language and exercise name."
  (let ((reply (split-string url "/")))
    (mapcar (lambda (this)
              (cadr (seq-drop-while (lambda (el) (not (equal el this)))
                                    reply)))
            '("tracks" "exercises"))))

;;;###autoload
(defun exercism-submit ()
  "Submit the current buffer as a solution."
  (interactive)
  (save-buffer)
  (let ((file (file-name-nondirectory (buffer-file-name))))
    (with-temp-buffer
      (shell-command (format "exercism submit ./%s" file) (current-buffer))
      (when exercism-visit-url
        (goto-char (point-max))
        (backward-char 2)
        (browse-url-at-point)))))

;;;###autoload
(defun exercism-new (lang name)
  "Download and open an exercise.
LANG is the desired language (or \"track\").  NAME is the name of
the exercise as one would give it to the exercism command line
utility; i.e., as it appears in the url on the website."
  (interactive (pcase-let* ((reply (or (exercism-from-selection)
                                       (read-string "URL: ")))
                            (`(,lang ,name) (exercism--get-lang-exercise reply)))
                 (list lang name)))
  (when (and name lang)
    (with-temp-buffer
      (shell-command (format "exercism download --exercise=%s --track=%s" name lang)
                     (current-buffer))
      (goto-char (point-max)) (backward-char) (insert "/")
      (find-file-at-point))))

(provide 'exercism)
;;; exercism.el ends here
