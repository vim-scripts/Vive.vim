" Vim plugin for Vim interpreter and virtual executor
" Language:    vim script
" Maintainer:  Dave Silvia <dsilvia@mchsi.com>
" Date:        8/19/2004
"
"
" Version 1.0 initial release
"
" Version 1.1
"  Fixed:
"    -  Problem with multiple windows
"       putting the 'Results:' label
"       in the wrong window.
"  Added:
"    -  Some new command line switches
"    -  Performance enhancements
"
" Version 1.2
"  Fixed:
"    -  If command/function/script
"       invoked from outside Vive
"       requested input, Vive would
"       halt with no indication.
"       Removed 'silent' from Vive
"       function call to correct.
"     - Because Vive does a
"       set buftype=help,
"       if first command contained
"       :r, redirect to g:ViveFile
"       would trip a Warning message
"       about changing a readonly
"       file, but _only_ on the first
"       command.  Now we do a :r
"       command at startup to
"       eliminate the problem.
"       Not sure why this happens,
"       it just does!:-<

if !exists("g:ViveFile")
	let g:ViveFile=fnamemodify(expand("~/.Vive.vim"),":p")
endif
if !exists("g:ViveRsltFile")
	let g:ViveRsltFile=fnamemodify(expand("~/.ViveRsltFile"),":p")
endif
if !exists("g:VivePrmpt")
	let g:VivePrmpt="Vive:"
endif
if !exists("g:ViveRslt")
	let g:ViveRslt="Results:"
endif
if !exists("g:ViveVerbose")
	let g:ViveVerbose=0
endif
if !exists("g:ViveHilite")
	let g:ViveHilite='DiffAdd'
endif
if !exists("g:ViveInterpret")
	let g:ViveInterpret='<S-Enter>'
endif
if !exists("g:ViveDVive")
	let g:ViveDVive='/v'
endif
if !exists("g:ViveDRslt")
	let g:ViveDRslt='/r'
endif
if !exists("g:ViveDAR")
	let g:ViveDAR='/a'
endif
if !exists("g:ViveCLS")
	let g:ViveCLS='/c'
endif
if !exists("g:ViveModeInsert")
	let g:ViveModeInsert=1
endif
if !exists("g:ViveTI")
	let g:ViveTI='/i'
endif
if !exists("g:ViveDBG")
	let g:ViveDBG='/d'
endif
if !exists("g:ViveDebug")
	let g:ViveDebug=0
endif
if !exists("g:ViveQQ")
	let g:ViveQQ='??'
endif

function! s:doGvimMenu()
	if has("gui_running")
		amenu &Vive.&Usage<Tab>?? :call <SID>usage()<CR>
		let s:menuIt='amenu &Vive.Delete\ Vive\ &Statement<TAB>'.g:ViveDVive.' :call <SID>deleteLast("v")<CR>' 
		execute s:menuIt
		let s:menuIt='amenu &Vive.Delete\ Vive\ Statement\ &Results<TAB>'.g:ViveDRslt.' :call <SID>deleteLast("r")<CR>' 
		execute s:menuIt
		let s:menuIt='amenu &Vive.Delete\ &All\ Vive\ Statement\ Results<TAB>'.g:ViveDAR.' :call <SID>deleteAllRslt()<CR>' 
		execute s:menuIt
		let s:menuIt='amenu &Vive.&Clear\ Vive\ Window<TAB>'.g:ViveCLS.' :call <SID>cls()<CR>' 
		execute s:menuIt
		function! s:doMenuIfInsert()
			let g:ViveModeInsert=1-g:ViveModeInsert
			DoIfInsert
			if !g:ViveModeInsert
				:stopinsert
				" clear call to this function from command line
				execute "normal \<C-L>"
			endif
		endfunction
		let s:menuIt='amenu &Vive.Toggle\ &Insert\ Mode<TAB>'.g:ViveTI.' :call <SID>doMenuIfInsert()<CR>'
		execute s:menuIt
		let s:menuIt='amenu &Vive.Toggle\ &Debug\ Mode<TAB>'.g:ViveDBG.' :let g:ViveDebug=1-g:ViveDebug<CR>'
		execute s:menuIt
		amenu &Vive.Set\ &Verbose.&0<TAB>ViveVbose\ 0 :ViveVbose 0<CR>
		amenu &Vive.Set\ &Verbose.&1<TAB>ViveVbose\ 1 :ViveVbose 1<CR>
		amenu &Vive.Set\ &Verbose.&2<TAB>ViveVbose\ 2 :ViveVbose 2<CR>
	endif
endfunction

let s:thisScript=expand("<sfile>:p")

augroup Vive
	autocmd!
	autocmd VimLeave * call s:isViveRunning(expand("<afile>"))
	autocmd BufDelete * call s:isViveRunning(expand("<afile>"))
augroup END

function! s:doUnMap(name)
	let sname='s:prev'.a:name
	let siname='s:iprev'.a:name
	let gname='g:Vive'.a:name
	execute 'unmap '.{gname}
	execute 'iunmap '.{gname}
	if {sname} != ''
		let {sname}=substitute({sname},'|','|','g')
		execute 'map '.{gname}.' '.{sname}
	endif
	if {siname} != ''
		let {siname}=substitute({siname},'|','|','g')
		execute 'imap '.{gname}.' '.{siname}
	endif
endfunction

function! s:isViveRunning(file)
	if !exists("g:ViveRunning") || a:file != g:ViveFile
		return
	endif
	if has("gui_running")
		aunmenu &Vive
	endif
	execute 'bwipeout '.bufnr(g:ViveFile)
	call s:delFile(g:ViveFile)
	delcommand DoIfInsert
	call s:doUnMap('Interpret')
	call s:doUnMap('DVive')
	call s:doUnMap('DRslt')
	call s:doUnMap('DAR')
	call s:doUnMap('CLS')
	call s:doUnMap('TI')
	call s:doUnMap('DBG')
	call s:doUnMap('QQ')
	unlet g:ViveRunning
endfunction

function! s:usage()
	let savech=&ch
	let maxLines=&lines
	if maxLines < 30
		execute 'set ch='.maxLines
	else
		set ch=30
	endif
	let endInpUsage='  '.g:ViveInterpret
	while strlen(endInpUsage) < 14
		let endInpUsage=endInpUsage.' '
	endwhile
	let delVive='  '.g:ViveDVive
	while strlen(delVive) < 14
		let delVive=delVive.' '
	endwhile
	let delRslt='  '.g:ViveDRslt
	while strlen(delRslt) < 14
		let delRslt=delRslt.' '
	endwhile
	let DAR='  '.g:ViveDAR
	while strlen(DAR) < 14
		let DAR=DAR.' '
	endwhile
	let CLS='  '.g:ViveCLS
	while strlen(CLS) < 14
		let CLS=CLS.' '
	endwhile
	let TI='  '.g:ViveTI
	while strlen(TI) < 14
		let TI=TI.' '
	endwhile
	let DBG='  '.g:ViveDBG
	while strlen(DBG) < 14
		let DBG=DBG.' '
	endwhile
	echo " "
	echohl Title
	echo "              Vim interpreter and virtual executor"
	echo " "
	echohl Statement
	echo "Vive[ -p <prmpt>][ -r <rsltLbl>][ -t <mapSeq>][ -H <HLGrp>]"
	echo "    [ -i][ -v <vboseLvl>][ -h]"
	echohl NonText
	echo "  -p          set prompt to <prmpt>"
	echo "  -r          set result label to <rsltLbl>"
	echo "  -t          set end of input mapping sequence to <mapSeq>"
	echo "  -H          set highlight group for prompt/label to <HLGrp>"
	echo "  -i          toggle insert mode (default is insert mode)"
	echo "  -v          set verbose level to <vboseLvl>"
	echo "  -h          produces this message {or press ??}"
	echo "  You can set verbose on the fly with the command ViveVbose lvl"
	echo "  Values set by the above switches may be set in your vimrc"
	echo "  See: ".s:thisScript
	echo "       for the global variables you may set"
	echo " "
	echohl Title
	echo "NOTE: 'tags' for context sensitive help is enabled in Vive"
	echo " "
	echohl Statement
	echo "Commands:"
	echohl NonText
	echo endInpUsage."to indicate end of input for interpretation"
	echo delVive."to delete cursor contained complete Vive statement"
	echo delRslt."to delete cursor contained result of Vive statement"
	echo DAR."to delete results of all Vive statements"
	echo CLS."to clear the interpreter buffer"
	echo TI."to toggle insert mode (default is insert mode)"
	echo DBG."to toggle debug mode (default is no debug mode)"
	echo " "
	echohl Cursor
	echo "        Press a key to continue"
	call getchar()
	echohl None
	set ch=1
	if expand("<sfile>") =~# '^function <SNR>\d\+_usage$'
		"called from within Vive by key mapping, go back to insert mode
		DoIfInsert
	endif
	let &ch=savech
endfunction

function! s:doMap(name,val)
	let sname='s:prev'.a:name
	let siname='s:iprev'.a:name
	let gname='g:Vive'.a:name
	let {sname}=maparg({gname})
	let {siname}=maparg({gname},'i')
	execute 'map <silent> '.{gname}.' '.a:val.'<CR>'
	execute 'imap <silent> '.{gname}.' <Esc>'.a:val.'<CR>'
endfunction

command! -nargs=1 ViveVbose let g:ViveVerbose=<args>
command! -nargs=* Vive call s:Vive(<f-args>)

" Vive initialization function
function! s:Vive(...)
	let g:ViveRunning=1
	if a:0
		let argNr=1
		while argNr <= a:0
			let thisArg='a:'.argNr
			if stridx('prHvt',{thisArg}[1]) != -1
				let argNr=argNr+1
				if argNr > a:0
					break
				endif
				let thisParm='a:'.argNr
			endif
			if {thisArg}[1] ==# 'p'
				let g:VivePrmpt={thisParm}
			elseif {thisArg}[1] ==# 'r'
				let g:ViveRslt={thisParm}
			elseif {thisArg}[1] ==# 'H'
				let g:ViveHilite={thisParm}
			elseif {thisArg}[1] ==# 'v'
				let g:ViveVerbose={thisParm}
			elseif {thisArg}[1] ==# 't'
				let g:ViveInterpret={thisParm}
			elseif {thisArg}[1] ==# 'i'
				let g:ViveModeInsert=1-g:ViveModeInsert
			elseif {thisArg}[1] ==# 'h'
				call s:usage()
				return
			endif
			let argNr=argNr+1
		endwhile
	endif
	if getline(1) !~ '^\%$'
		new
	endif
	command! DoIfInsert if g:ViveModeInsert | :startinsert! | endif
	call s:doMap('Interpret',':call <SID>GetViveLines()')
	call s:doMap('DVive',':call <SID>deleteLast("v")')
	call s:doMap('DRslt',':call <SID>deleteLast("r")')
	call s:doMap('DAR',':call <SID>deleteAllRslt()')
	call s:doMap('CLS',':call <SID>cls()')
	call s:doMap('TI',':let g:ViveModeInsert=1-g:ViveModeInsert | DoIfInsert')
	call s:doMap('DBG',':let g:ViveDebug=1-g:ViveDebug')
	call s:doMap('QQ',':call <SID>usage()')
	call s:doGvimMenu()
	call s:delFile(g:ViveFile)
	execute 'edit '.g:ViveFile
	set hidden noswapfile nonumber buftype=help syntax=vim filetype=vim
	" do this little diddy because if the first redir to the file is a ':r',
	" (which sets readonly???) it causes a Warning.
	" So, we do it on purpose and correct the problem
	silent :r !ls
	normal u
	set noreadonly
	" Put the highlight link first to fool syntax clear into thinking we've got
	" a group named VivePrmpt if one doesn't already exist.  It's cheaper
	" than doing an hlexists() conditional, besides, we have to do the
	" highlight link anyway.
	let HLCmd='highlight link VivePrmpt '.g:ViveHilite
	execute HLCmd
	syntax clear VivePrmpt
	let s:synCmd='syntax match VivePrmpt "^'.g:VivePrmpt.'$\|^'.g:ViveRslt.'$"'
	execute s:synCmd
	call setline(1,g:VivePrmpt)
	normal o
	call setline(2,"\<Tab>")
	" If they decide they didn't want Vive and quit right away, don't prompt to
	" save modified file
	set nomodified
	DoIfInsert
endfunction

" elnum == ending line number
" clnum == current line number
" olnum == origin line number
function! s:GetViveLines()
	let elnum=search('^\('.g:ViveRslt.'\|'.g:VivePrmpt.'\)$\|\%$','W')
	if elnum == 0
		let elnum=line('$')
	endif
	if elnum != line('$')
		let elnum=elnum-1
	endif
	execute 'normal '.elnum.'G'
	let olnum=elnum
	let clnum=search('^'.g:VivePrmpt.'$','bW')
	let clnum=clnum+1
	execute clnum.','.elnum.'yank "'
	let funcBody=substitute(@","\<NL>\\+$",'','')
	if funcBody =~ '^\s*$'
		normal j
		DoIfInsert
		return
	endif
	let @"="function! ViveFunc()\<NL>".@"."endfunction\<NL>"
	silent :@"
	execute 'normal '.olnum.'G'
	normal o
	let olnum=olnum+1
	let clnum=line('.')
	call setline(clnum,g:ViveRslt)
	call s:RedirNoEcho()
	delfunction ViveFunc
	execute 'normal '.olnum.'G'
	let saveCPO=&cpoptions
	"don't need any compatibility options to read the file
	set cpoptions=
	execute 'silent :r '.g:ViveRsltFile
	"reading the file sets readonly; correct this
	set noreadonly
	let &cpoptions=saveCPO
	call s:delFile(g:ViveRsltFile)
	let elnum=search('^\('.g:ViveRslt.'\|'.g:VivePrmpt.'\)$\|\%$','W')
	if elnum == 0
		let elnum=line('$')
	elseif elnum != line('$')
		let elnum=elnum-1
	endif
	execute 'normal '.elnum.'G'
	normal o
	let clnum=line('.')
	if clnum == line('$')
		normal o
		let clnum=line('$')
		call setline(clnum,g:VivePrmpt)
		normal o
		let clnum=line('.')
		call setline(clnum,"\<Tab>")
	else
		let endInterpret=olnum-1
		execute 'normal '.endInterpret.'G'
	endif
	DoIfInsert
endfunction

function! s:RedirNoEcho()
	let savemore=&more
	set nomore
	call s:delFile(g:ViveRsltFile)
	execute 'redir! >'.g:ViveRsltFile
	if g:ViveVerbose
		echo "Function definition is:"
		:function ViveFunc
		echo " "
	endif
	if g:ViveVerbose <= 1
		if !g:ViveDebug
			call ViveFunc()
		else
			:debug call ViveFunc()
		endif
	endif
	redir END
	let &more=savemore
	"this avoids the final 'Hit Enter' prompt if it's there.  For some reason
	"'set nomore' doesn't turn the last one off.
	execute line('$').' append | . '
endfunction

function! s:deleteLast(type)
	let slnum=line('.')
	if slnum == 2 && line('$') == 2
		DoIfInsert
		return
	endif
	if a:type == 'v'
		let termline=g:VivePrmpt
	else
		let termline=g:ViveRslt
	endif
	let clnum=search('^'.g:VivePrmpt,'W')
	if clnum == 0
		execute 'normal '.slnum.'G'
		let clnum=search('^'.g:VivePrmpt,'bW')
	endif
	let clnum=clnum-1
	execute 'normal '.clnum.'G'
	if a:type == 'r'
		let vlnum=search('^'.g:VivePrmpt,'bW')
		execute 'normal '.clnum.'G'
		let rlnum=search('^'.g:ViveRslt,'bW')
		execute 'normal '.clnum.'G'
	endif
	if a:type == 'r' && rlnum > vlnum  || a:type != 'r'
		execute 'normal '.clnum.'G'
		normal ma
		let clnum=search('^'.termline,'bW')
		if clnum != 0
			execute 'normal '.clnum.'G'
			normal d'a
		endif
	endif
	normal gg
	normal G
	DoIfInsert
endfunction

function! s:cls()
	normal gg
	normal ma
	normal G
	silent normal d'a
	call setline(1,g:VivePrmpt)
	normal o
	call setline(2,"\<Tab>")
	DoIfInsert
endfunction

function! s:deleteAllRslt()
	normal gg
	let rslt=search(g:ViveRslt,'W')
	while rslt != 0
		let erslt=search('^\('.g:ViveRslt.'\|'.g:VivePrmpt.'\)$','W')
		if erslt == 0
			break
		endif
		let erslt=erslt-1
		execute rslt.','.erslt.'d'
		normal gg
		let rslt=search(g:ViveRslt,'W')
	endwhile
	normal G
	DoIfInsert
endfunction

function! s:delFile(fname)
	let fname=glob(a:fname)
	if fname == ''
		return
	endif
	let failure=delete(fname)
	if !failure
		return
	endif
	echohl Warningmsg
	echomsg expand("<sfile>").": Could not delete <".fname.">"
	echomsg "Reason: ".v:exception
	echohl Cursor
	echomsg "        Press a key to continue"
	echohl None
	call getchar()
endfunction
