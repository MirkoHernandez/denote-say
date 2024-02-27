# denote-say

denote-say provides convenient functions for integrating denote notes
and any tts engine that can create audio files.

denote-say provides functionality for two kinds of tasks.
- Using denote notes, create text files that are suitable for use with
   a tts engine. This primarily involves removing text that won't be
   easily voiced by a tts engine, particularly in org-mode files.
   Examples:
   - Links
   - Source code blocks.
   - Text with emphasis markup.
   - Headers.
- Create audio files from those text files (using a tts command) in a
   temporary directory and then play them.

# Installation

## Manual

denote-say is not available on any ELPA. To install manually, download
`denote-say.el`, then call M-x `package-install-file` on it.

M-x `package-initialize` may be required to recognize the package
after installation (just once after installation).

## Requirements

Denote 2.0.0 or above is required and any tts engine that can create
audio files.

# Configuration

The following variables can be use for configuring denote-say.


`denote-say-temp-directory`

This is where text and audio files are stored. The default value is in
the subdirectory denote-say of `user-emacs-directory`.


`denote-say-tts-commands`

The list of available tts commands. These commands create an audio
file using a text file. The placeholders textfile and audiofile
(and the enclosing < >) **must** be used when describing a command.

``` emacs-lisp
(defvar denote-say-tts-commands
  `((festival . "text2wave -o <audiofile> <textfile>")
    (festival-es . "text2wave -o <audiofile> -eval '(voice_el_diphone) <textfile>")
    (piper . "cat <textfile> | piper --model  en_US-lessac-medium.onnx --length_scale 1.4 --output_file <audiofile> ")
    (piper-fast . "cat <textfile> | piper --model en_US-lessac-medium.onnx --length_scale 0.8 --output_file <audiofile> ")))
```


`denote-say-tts-command`

This is the command used to create audio files. The value is a key of
the `denote-say-tts-commands` alist.


`denote-say-play-function`

Function that plays the audio file. The default is `emms-play-file`.


`denote-say-org-replacements`

Is the list of replacements that are applied to denote files. The
order of the replacements is important. Top entries are applied first.

# Usage

`denote-say-buffer`

Creates a text file from the current buffer (using all the
replacements form `denote-say-org-replacements`), then an audio file
using `denote-say-tts-command`, then it plays the audio file using
`denote-say-play-function`.


`denote-say-buffer-choose-tts`

It does the same as `denote-say-buffer` but the tts command is
selected from a prompt.


`denote-say-set-tts-command`

Can be used to change the tts command.
