# denote-say

denote-say provides functions for integrating denote notes and any tts
engine that can create audio files.

denote-say provides functionality for two kinds of tasks.

1. Create text files that are suitable for use with a tts engine. This
   primarily involves removing text that won't be easily voiced by a
   tts engine, particularly in org-mode files.
   Examples of problematic text:
   - Links.
   - Source code blocks.
   - Text with emphasis markup.
   - Headers.
   
   A text file can be created by combining multiple denote files
   (files from denote links and dblock links).
  
2. Create audio files from those text files (using a tts engine) in a
   temporary directory and then play them.

# Installation

## Manual

denote-say is not available on ELPA. To install manually, download
`denote-say.el`, then call M-x `package-install-file` on it.

M-x `package-initialize` may be required to recognize the package
after installation (just once after installation).

## Requirements

Denote 2.0.0 or above is required and any tts engine that can create
audio files.

# Configuration

The following variables can be use for configuring denote-say.

#### denote-say-temp-directory

This is where text and audio files are stored. The default value is in
the subdirectory denote-say of `user-emacs-directory`.


#### denote-say-tts-commands

The list of available tts commands. These commands create an audio
file using a text file. The placeholders textfile and audiofile
(enclosed in < >) **must** be used when describing a command.

``` emacs-lisp
(defvar denote-say-tts-commands
  `((festival . "text2wave -o <audiofile> <textfile>")
    (festival-es . "text2wave -o <audiofile> -eval '(voice_el_diphone) <textfile>")
    (piper . "cat <textfile> | piper --model  en_US-lessac-medium.onnx --length_scale 1.4 --output_file <audiofile> ")
    (piper-fast . "cat <textfile> | piper --model en_US-lessac-medium.onnx --length_scale 0.8 --output_file <audiofile> ")))
```

#### denote-say-tts-command

This is the command used to create audio files. The value is a key of
the `denote-say-tts-commands` alist. The default value is `piper`.

#### denote-say-org-replacements

Is the list of replacements that are applied to denote files. The
order of the replacements is important; top entries are applied first.

Some replacements involve adding a '.' character; the output sounds
better in my opinion.

``` emacs-lisp
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
``` 

#### denote-say-play-function

The function used for playing audio files. The default value is
`emms-play-file`.

#### denote-say-ocr-commands

The list of available OCR commands.

``` emacs-lisp
(defvar denote-say-ocr-commands
  `((tesseract . "tesseract <imagefile> <textfile> -l eng")
	(tesseract-spa . "tesseract <imagefile> <textfile> -l spa")))
```

#### denote-say-ocr-command

This is the command used for OCR. The value must be a key of the
`denote-say-ocr-commands` alist. The default value is `tesseract`.

# Usage

#### denote-say-buffer

Creates a text file from the current buffer (using all the
replacements form `denote-say-org-replacements`), then an audio file
using `denote-say-tts-command`, then it plays the audio file using
`denote-say-play-function`.

#### denote-say-buffer-choose-tts

It does the same as `denote-say-buffer` but the tts command is
selected from a prompt.

#### denote-say-set-tts-command

Can be used to change the default tts command.

#### denote-say-find-note

Choose a note from `denote-directory` and call `denote-say-buffer` on
that file.

#### denote-say-find-note-choose-tts 

Like `denote-say-find-note` but allows you to choose the tts command.

## PDF commands

pdf-tools and an ocr program is required for the following commands.

### denote-say-pdf-ocr-page

Use an OCR command on the current PDF page, and then play the
resulting text file.


