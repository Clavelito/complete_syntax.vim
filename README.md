## complete\_syntax.vim
Keyword completion is performed using syntax highlighting files.  
It can also be used when syntax off.  
It is not set to omnifunc.  
Use CTRL-N and CTRL-P as you would for completion in the current buffer.
### Configuration
Add the following line to vimrc.
~~~vim
autocmd FileType * if exists(':CompleteSyntax') == 2 | exe 'CompleteSyntax' | endif
~~~
### License
Apache License, Version2.0
### Author
Clavelito
