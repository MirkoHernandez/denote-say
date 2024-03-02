;;; denote-say.el --- Prepare denote notes for use with a tts engine. -*- lexical-binding: t -*-

;; Copyright (C) 2024 Mirko Hernandez

;; Author: Mirko Hernandez <mirkoh@fastmail.com>
;; Maintainer: Mirko Hernandez <mirkoh@fastmail.com>>
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Version: 0.1.0
;; Keywords: notes tts 
;; URL: https://github.com/MirkoHernandez/denote-say
;; Package-Requires: ((emacs "27.1") (denote "2.0.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This packages provides textual  transformation functions for denote
;; notes to  make them  suitable for  use with a  tts engine.  It also
;; includes functions for  adding and executing tts  commands on those
;; notes.

;;;; Configuration
(defvar denote-say-encoding 'utf-8)
(defvar denote-say-temp-directory (expand-file-name "denote-say" user-emacs-directory))
(defvar denote-say-tts-command 'piper)
(defvar denote-say-play-function 'emms-play-file)

(defvar denote-say-tts-commands
  `((festival . "text2wave -o <audiofile> <textfile>")
    (festival-es . "text2wave -o <audiofile> -eval '(voice_el_diphone) <textfile>")
    (piper . "cat <textfile> | piper --model  en_US-lessac-medium.onnx --length_scale 1.4 --output_file <audiofile> ")
    (piper-fast . "cat <textfile> | piper --model en_US-lessac-medium.onnx --length_scale 0.8 --output_file <audiofile> ")))

;; NOTE: some replacements involve an  added '.' character; this seems
;; to improve the rhythm of some sentences.
(defvar denote-say-org-replacements
  `(("^#[+]title: *\\(.*\\)" .                    "\\1." )
    ("\\(^#[+]date:.*\\|^#[+]filetags: *\\|^#[+]identifier:.*\\)" . "")
    ("^#[+]filetags: *:\\(.*\\):" . "Keywords. \\1.")
    (org-babel-src-block-regexp . "Source Code. \\2")
    (org-block-regexp . "D Block Links. \\4.")
    (org-heading-regexp . "\\2.")
    (org-any-link-re . "\\3.")
    (org-emph-re  . "\\4")
    (org-verbatim-re  . " \\4 ")
    (org-target-regexp  . "\\1")
    ("\""  . "")
    ("\\(<<\\|>>\\)"  . "")
    ("\\(;\\|:\\)"  . ".")))

(defun denote-say-create-tts-command (command  textfile audiofile)
  "Create a string that represents a tts engine command. The command creates an audio file using a text file.
 COMMAND is a key in `denote-say-tts-commands' TEXTFILE is a file
 path,the input to  the tts engine, AUDIOFILE is  the output name
 of the audio file."
  (let* ((str (alist-get command denote-say-tts-commands))
	 (str (replace-regexp-in-string "<textfile>" textfile str)))
    (replace-regexp-in-string "<audiofile>"  audiofile str)))

;;;; Text replacements
;; NOTE: it  would be faster  to iterate the  lines of the  buffer but
;; some replacements involve multi-line regexps  and others need to be
;; done after previous replacements. 
(defun denote-say-org-replace (str replacements)
 "Transforms the string STR using the REPLACEMENTS list."
  (cl-labels ((rec (lst acc)
		(if (null lst)
		    acc
		  (let* ((pair (car lst))
			 (regexp (car pair) )
			 (substitution (cdr  pair)))
		    (rec (cdr lst) 
			 (replace-regexp-in-string (if (symbolp regexp) 
						       (eval regexp)
						     regexp)
						   substitution
						   acc))))))
    (rec replacements str ))) 

(defun denote-say-transform (file)
  "Return string corresponding to the contents of FILE after some replacements.
The string is also encoded using `denote-say-encoding.'" 
  (encode-coding-string
   (denote-say-org-replace
    (get-string-from-file 
     file) denote-say-org-replacements)
   denote-say-encoding))

(defun denote-say-transform-with-links (&optional file)
 "Transform FILE and appends  all the transformations corresponding
with each denote link of that file." 
  (let* ((links (denote-link-return-links file))
	 (text (mapconcat 'denote-say-transform (nreverse links))))
    text))

(defun denote-say-create-txt-file (&optional file links)
 "Create a text file using the content of FILE. If LINKS is non-nil
links are also included." 
  (interactive) 
  (unless (file-exists-p denote-say-temp-directory)
    (make-directory denote-say-temp-directory))
  (let* ((file (or file (buffer-file-name)))
	 (basename (file-name-base file))
	 (textfile (concat denote-say-temp-directory "/" basename ".txt"))
	 (text (if links
		   (denote-say-transform-with-links file)
		 (denote-say-transform file))))
    (write-region text nil  textfile  )))

(defun denote-say-test ()
 "Used for  testing replacements. It  displays the content  of the
current buffer after the replacements from `denote-say-org-replacements' are applied." 
  (interactive)
   (display-message-or-buffer
    (denote-say-org-replace (substring-no-properties (buffer-string))
			    denote-say-org-replacements)))

;;;; TTS
(defun denote-say-create-audio (textfile)
  "Creates an audio file out of TEXTFILE in `denote-say-temp-directory'.
  It uses the command  specified in `denote-say-tts-command'. The
  return is the exit status."
  (let* ((basename (file-name-base textfile ))
	 (audiofile (concat  "'" denote-say-temp-directory "/" basename ".wav'"))
	 (command   (denote-say-create-tts-command denote-say-tts-command
						   (concat "'" textfile "'")  audiofile)))
    (if (file-exists-p audiofile)
	(progn	
	  (delete-file audiofile)
	  (message "Overwriting %s" audiofile))
      (message "Creating %s" audiofile))
    (call-process-shell-command command nil nil)))

;;;; Find denote note helpers
(define-inline denote-say-pretty-format-filename (&optional file)
  "Return a pretty formatted string of a denote note; denote id is
ommited, it includes only signature,  title and keywords. FILE is
a denote note path."
  (inline-quote
   (cons
    (let* ((file (or ,file (buffer-file-name)))
	   (signature (denote-retrieve-filename-signature file))
	   (title (denote-retrieve-filename-title file))
	   (keywords (denote-extract-keywords-from-path file))
	   (keywords-as-string (mapconcat 'identity keywords ", ")))
      (format (concat "%s %s " (if keywords "-" "") "%s")
	      (propertize signature  'face 'font-lock-warning-face)
	      (propertize title 'face 'font-lock-doc-face)
	      (propertize keywords-as-string 'face 'font-lock-note-face)))
    ,file)))

(defun denote-say-find-file ()
  "Find a note  from `denote-directory' using a  pretty printed list
of notes." 
  (let* ((vertico-sort-function 'identity);; Prevents sorting by history
	 (vertico-buffer-mode t)
	 (paths (mapcar #'denote-say-pretty-format-filename
		(denote-directory-files)))
	 (filename (cdr (assoc (completing-read "Note: " paths  nil t) paths))))
      filename))

;;;; Interactive functions
;;;###autoload
(defun denote-say-set-tts-command ()
 "Set `denote-say-tts-command' using some value from the list `denote-say-tts-commands'" 
 (interactive)
  (let* ((tts (completing-read "tts:"   denote-say-tts-commands)))
	 (setq denote-say-tts-command (intern tts))))

;;;###autoload
(defun denote-say-buffer (&optional file)
  "Create and play an audio file from FILE. The files are created in
`denote-say-temp-directory'.  Using  a prefix-argument  the  text
file   created   includes   the    content   of   denote   links.
`denote-say-play-function' is  the function that plays  the audio
file." 
  (interactive)
  (let* ((file (or file (buffer-file-name)))
	 (basename (file-name-base file))
	 (textfile (concat denote-say-temp-directory "/" basename ".txt"))
	 (audiofile (concat denote-say-temp-directory "/" basename ".wav")))
    (if current-prefix-arg
	(denote-say-create-txt-file file t)
      (denote-say-create-txt-file file))
    ;; TODO: Replace this with proper async code. 
    (let ((result (denote-say-create-audio textfile)))
      (if (equal 0 result)
	  (funcall denote-say-play-function
		   audiofile)
	(error "Error in audio conversion." )))))

;;;###autoload
(defun denote-say-find-note (&optional regexp)
  (interactive)
  (denote-say-buffer (denote-say-find-file)))

;;;###autoload
(defun denote-say-buffer-choose-tts (&optional file)
  "Choose a tts engine  from `denote-say-tts-commands' and then call
`denote-say-buffer.'" 
  (interactive)
  (let* ((tts (completing-read "TTS command:"   denote-say-tts-commands))
	 (denote-say-tts-command (intern tts)))
    (when (alist-get denote-say-tts-command denote-say-tts-commands)
      (denote-say-buffer file))))

;;;###autoload
(defun denote-say-find-note-choose-tts (&optional regexp)
  (interactive)
  (denote-say-buffer-choose-tts (denote-say-find-file)))

(provide 'denote-say)
