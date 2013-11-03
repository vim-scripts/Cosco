" ===============================================
" Examples on how to use it (also on the README):
" ===============================================

" autocmd FileType c,cpp,css,java,javascript,perl,php,jade nmap <silent> ,; :call cosco#commaOrSemiColon()<CR>
" autocmd FileType c,cpp,css,java,javascript,perl,php,jade inoremap <silent> ,; <ESC>:call cosco#commaOrSemiColon()"<CR>a
" command! CommaOrSemiColon call cosco#commaOrSemiColon()


" ==============
" Main function:
" ==============

function! cosco#commaOrSemiColon()
    let b:wasExtensionExecuted = 0

    let b:originalLineNum = line('.')
    let b:currentLine = getline(b:originalLineNum)
    let b:currentLineLastChar = matchstr(b:currentLine, '.$')
    let b:currentLineFirstChar = matchstr(b:currentLine, '^.')
    let b:currentLineIndentation = indent(b:originalLineNum)

    if (s:hasUnactionableLines())
        return
    endif

    let b:originalCursorPosition = getpos('.')

    let b:nextLine = s:getNextNonBlankLine(b:originalLineNum)
    let b:prevLine = s:getPrevNonBlankLine(b:originalLineNum)

    let b:nextLineIndentation = indent(s:getNextNonBlankLineNum(b:originalLineNum))
    let b:prevLineIndentation = indent(s:getPrevNonBlankLineNum(b:originalLineNum))

    let b:prevLineLastChar = matchstr(b:prevLine, '.$')
    let b:nextLineLastChar = matchstr(b:nextLine, '.$')
    let b:nextLineFirstChar = matchstr(s:strip(b:nextLine), '^.')

    call s:filetypeOverrides()

    if (b:wasExtensionExecuted)
        call setpos('.', b:originalCursorPosition)
        return
    endif

    if b:prevLineLastChar == ','
        if b:nextLineFirstChar =~ '[}\])]'
            exec("s/[,;]\\?$//e")
        elseif b:nextLineLastChar == ','
            exec("s/[,;]\\?$/,/e")
        elseif b:nextLineIndentation < b:currentLineIndentation
            exec("s/[,;]\\?$/;/e")
        elseif b:nextLineIndentation == b:currentLineIndentation
            exec("s/[,;]\\?$/,/e")
        endif
    elseif b:prevLineLastChar == ';'
        exec("s/[,;]\\?$/;/e")
    elseif b:prevLineLastChar == '{'
        if b:nextLineLastChar == ','
            " TODO idea: externalize this into a "javascript" extension:
            if s:strip(b:nextLine) =~ '^var'
                exec("s/[,;]\\?$/;/e")
            endif
            exec("s/[,;]\\?$/,/e")
        " TODO idea: externalize this into a "javascript" extension:
        elseif s:strip(b:prevLine) =~ '^var'
            if b:nextLineFirstChar == '}'
                exec("s/[,;]\\?$//e")
            endif
        else
            exec("s/[,;]\\?$/;/e")
        endif
    elseif b:prevLineLastChar == '['
        if b:nextLineFirstChar == ']'
            exec("s/[,;]\\?$//e")
        elseif b:currentLineLastChar =~ '[}\])]'
            exec("s/[,;]\\?$/;/e");
        else
            exec("s/[,;]\\?$/,/e")
        endif
    elseif b:prevLineLastChar == '('
        if b:nextLineFirstChar == ')'
            exec("s/[,;]\\?$//e")
        else
            exec("s/[,;]\\?$/,/e")
        endif
    elseif b:nextLineFirstChar == ']'
        exec("s/[,;]\\?$//e")
    else
        exec("s/[,;]\\?$/;/e")
    endif

    call setpos('.', b:originalCursorPosition)
endfunction

" =================
" Helper functions:
" =================

function! s:strip(string)
    return substitute(a:string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! s:getNextNonBlankLineNum(lineNum)
    return s:getFutureNonBlankLineNum(a:lineNum, 1, line('$'))
endfunction

function! s:getPrevNonBlankLineNum(lineNum)
    return s:getFutureNonBlankLineNum(a:lineNum, -1, 1)
endfunction

function! s:getNextNonBlankLine(lineNum)
    return getline(s:getNextNonBlankLineNum(a:lineNum))
endfunction

function! s:getPrevNonBlankLine(lineNum)
    return getline(s:getPrevNonBlankLineNum(a:lineNum))
endfunction

function! s:getFutureNonBlankLineNum(lineNum, direction, limitLineNum)
    if (a:lineNum == a:limitLineNum)
        return ''
    endif

    let l:futureLineNum = a:lineNum + (1 * a:direction)
    let l:futureLine = s:strip(getline(l:futureLineNum))

    if (l:futureLine == '')
        return s:getFutureNonBlankLineNum(l:futureLineNum, a:direction, a:limitLineNum)
    endif

    return l:futureLineNum
endfunction

function! s:hasUnactionableLines()
    if (s:strip(b:currentLine) == '' || b:currentLineLastChar =~ '[{[(]')
        return 1
    endif
endfunction

function! s:filetypeOverrides()
    try
        exec 'call filetypes#'.&ft.'#parse()'
    catch
        " No filetypes for the current buffer filetype
    endtry
endfunction
