vim9script noclear

# Author:      Clavelito <maromomo@hotmail.com>
# Last Change: Thu, 24 Feb 2022 06:09:51 +0900
# License:     https://www.apache.org/licenses/LICENSE-2.0
#
# Description: Keyword completion is performed using syntax highlighting files.
#              It can also be used when syntax off.
#              It is not set to omnifunc. Use CTRL-N and CTRL-P as you would
#              for completion in the current buffer.
#
#              autocmd FileType * CompleteSyntax


if exists('g:loaded_complete_syntax')
  finish
endif
g:loaded_complete_syntax = 0

command CompleteSyntax complete_syntax#Complete_syntax()
