vim9script noclear

# Author:      Clavelito <maromomo@hotmail.com>
# Last Change: Wed, 03 May 2023 12:07:10 +0900
# Version:     0.2
# License:     http://www.apache.org/licenses/LICENSE-2.0
#
# Description: Keyword completion is performed using syntax highlighting files.
#              It can also be used when syntax off.
#              It is not set to omnifunc. Use CTRL-N and CTRL-P as you would
#              for completion in the current buffer.

if exists('g:loaded_complete_syntax') && !!g:loaded_complete_syntax
  finish
endif
g:loaded_complete_syntax = 1

const cpo_save = &cpo
set cpo&vim

export def Complete_syntax(): void
  if !empty(FileReadableList())
    augroup CompleteSyntax
      autocmd!
      autocmd BufEnter * SelectCompleteBuffer(true)
    augroup END
    SetMap()
  endif
enddef

const temp_dir = !!getenv('TEMP') && isdirectory(getenv('TEMP'))
      ? getenv('TEMP') : '/tmp'
const runtime_path = split(&runtimepath, ',')
const beginpt = '^\s*syn\=\%(tax\)\=\s\+keyword\s\+\S\+'
const sourcept = '^\s*runtime!\=\s\+syntax/\([a-z0-9]\+[.]vim\)\s*$'
const complete_syntax_pid = '#' .. getpid()
var lasttype: string

def SetMap(): void
  inoremap <buffer> <C-P> <C-R>=<SID>SelectCompleteBuffer()<CR><Esc>a<C-P>
  inoremap <buffer> <C-N> <C-R>=<SID>SelectCompleteBuffer()<CR><Esc>a<C-N>
  SelectCompleteBuffer(true)
enddef

def CompleteSyntaxFile(): void
  if empty(&filetype)
    return
  endif
  var bn = complete_syntax_pid .. &filetype
  var save_dir = getcwd()
  exec 'silent cd ' .. temp_dir
  if !bufexists(bn) && &modifiable && &ft != 'qf' && &ft != 'netrw'
    var bufnr = bufadd(bn)
    setbufvar(bufnr, '&swapfile', 0)
    silent bufload(bufnr)
    var lines: list<string>
    var sum = 0
    for fn in FileReadableList()
      lines = GetWordsList(fn)
      setbufline(bufnr, sum + 1, lines)
      sum += len(lines)
    endfor
    setbufvar(bufnr, 'complete', complete_syntax_pid)
  endif
  exec 'silent cd ' .. save_dir
  SelectCompleteBuffer()
enddef

def GetWordsList(fn: string): list<string>
  var wordlist: list<string>
  var sum = 1
  var flag = 0
  for line in readfile(fn)
    if line =~# beginpt
      extend(wordlist, ParseLine(line, beginpt))
      flag = sum + 1
    elseif flag == sum && line =~ '^\s*\\'
      extend(wordlist, ParseLine(line, '^\s*\\'))
      flag = sum + 1
    elseif line =~# sourcept
      var rtp = substitute(fn, '[^/]\+$', '', '')
      var fn2 = substitute(line, sourcept, rtp .. '\1', '')
      if filereadable(fn2)
        extend(wordlist, GetWordsList(fn2))
      endif
    endif
    sum += 1
  endfor
  return wordlist
enddef

def ParseLine(line: string, pt: string): list<string>
  var str = substitute(line, pt
        .. '\|\s\%(nextgroup\|containedin\)=\S\+'
        .. '\|\s\%(skipempty\|skipwhite\|skipnl\|contained\)\>', '', 'g')
  str = substitute(str, '\s\(\S\+\)\[\(\S\+\)\]', ' \1 \1\2', 'g')
  return split(str)
enddef

def SelectCompleteBuffer(...args: list<bool>): string
  if !empty(args) && lasttype == &filetype
    return ''
  endif
  lasttype = &filetype
  const compbufpt = complete_syntax_pid .. &filetype .. '$'
  var flag = 0
  for dic in getbufinfo()
    if VariableCompleteExists(dic)
      if dic['name'] =~# compbufpt
        setbufvar(dic['bufnr'], '&buflisted', 1)
        flag = 1
      else
        setbufvar(dic['bufnr'], '&buflisted', 0)
      endif
      if empty(getbufvar(dic['bufnr'], '&buftype'))
        setbufvar(dic['bufnr'], '&buftype', 'nofile')
      endif
      if !empty(dic['windows'])
        setbufvar(dic['bufnr'], '&hidden', 1)
        bnext
        SelectCompleteBuffer(true)
      endif
    endif
  endfor
  if !flag && empty(args)
    CompleteSyntaxFile()
    iunmap <buffer> <C-P>
    iunmap <buffer> <C-N>
  endif
  return ''
enddef

def FileReadableList(): list<string>
  var flist: list<string>
  var fname: list<string>
  for rtp in runtime_path
    if isdirectory(rtp .. '/syntax/' .. &filetype)
      fname = split(system(
              'ls ' .. rtp .. '/syntax/' .. &filetype .. '/*.vim'), '\n')
    endif
    fname = add(fname, rtp .. '/syntax/' .. &filetype .. '.vim')
    for fn in fname
      if filereadable(fn)
        flist = add(flist, fn)
      endif
    endfor
  endfor
  return flist
enddef

def VariableCompleteExists(dic: dict<any>): bool
  return has_key(dic['variables'], 'complete')
      && dic['variables']['complete'] == complete_syntax_pid
enddef

&cpo = cpo_save
# vim: sw=2 et
