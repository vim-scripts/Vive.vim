" Vim plugin for Vim interpreter and virtual executor
" Language:    vim script
" Maintainer:  Dave Silvia <dsilvia@mchsi.com>
" Date:        8/24/2004
"
" Version 2.0
" Date:        9/21/2004
"  Added:
"    -  Menu item for Read Script
"    -  Menu item for Execute Script
"    -  Menu item Vim verbose mode
"    -  Menu item for debug mode
"
" Version 1.3
"  Fixed:
"    -  If command opens new edit
"       buffers, be sure to return
"       to the Vive window/buffer
"       on completion of ViveFunc
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
" Version 1.0 initial release

if !exists("g:ViveBrowseDir")
	let RTdirs=expand(&runtimepath)
	if !exists("*StrListTok")
		runtime plugin/vsutil.vim
	endif
	let RTdir=StrListTok(RTdirs,'b:rtdirs')
	while RTdir != ''
		if glob(RTdir) != ''
			let g:ViveBrowseDir=RTdir
			break
		endif
		let RTdir=StrListTok('','b:rtdirs')
	endwhile
	while RTdir != ''
		let RTdir=StrListTok('','b:rtdirs')
	endwhile
	unlet b:rtdirs
endif
if !exists("g:ViveFileDir")
	let g:ViveFileDir=fnamemodify(expand("~"),":p:h")
endif
if !exists("g:ViveFile")
	let g:ViveFile=fnamemodify(expand(g:ViveFileDir."/.Vive.vim"),":p")
endif
if !exists("g:ViveRsltFile")
	let g:ViveRsltFile=fnamemodify(expand(g:ViveFileDir."/.ViveRsltFile"),":p")
endif
if !exists("g:ViveVimVerboseFile")
	let g:ViveVimVerboseFile=fnamemodify(expand(g:ViveFileDir."/.ViveVimVerboseFile"),":p")
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
if !exists("g:ViveVimVerbose")
	let g:ViveVimVerbose=0
endif
if !exists("g:ViveHilite")
	let g:ViveHilite='DiffAdd'
endif
if !exists("g:ViveInterpret")
	let g:ViveInterpret='<S-Enter>'
endif
if !exists("g:ViveDVive")
	let g:ViveDVive="zv"
endif
if !exists("g:ViveDRslt")
	let g:ViveDRslt="zr"
endif
if !exists("g:ViveDAR")
	let g:ViveDAR="za"
endif
if !exists("g:ViveCLS")
	let g:ViveCLS="zc"
endif
if !exists("g:ViveModeInsert")
	let g:ViveModeInsert=1
endif
if !exists("g:ViveTI")
	let g:ViveTI="zi"
endif
if !exists("g:ViveDBG")
	let g:ViveDBG="zd"
endif
if !exists("g:ViveDebug")
	let g:ViveDebug=0
endif
if !exists("g:ViveQQ")
	let g:ViveQQ='z?'
endif

let g:firstDbgMdMenuCall=1

function! s:doGvimMenu()
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
	let s:menuIt='amenu &Vive.&Usage<TAB>'.g:ViveQQ.' :call <SID>usage()<CR>'
	execute s:menuIt
	if has("browse")
		function! s:browser(Exec)
			let fname=browse(0,'Read File into Vive',g:ViveBrowseDir,'')
			if fname != ''
				execute ':'.line('.')-1.'r '.fname
				if a:Exec
					:call s:GetViveLines()
				endif
			endif
		endfunction
		amenu &Vive.Read\ Script\ &File :call <SID>browser(0)<CR>
		amenu &Vive.Execute\ Script\ &File :call <SID>browser(1)<CR>
	endif
	amenu &Vive.Set\ V&iveVbose.&0<TAB>:ViveVbose\ 0 :ViveVbose 0<CR>
	amenu &Vive.Set\ V&iveVbose.&1<TAB>:ViveVbose\ 1 :ViveVbose 1<CR>
	amenu &Vive.Set\ V&iveVbose.&2<TAB>:ViveVbose\ 2 :ViveVbose 2<CR>
	function! s:doVimVerbose(lvl)
		if a:lvl < 0
			call delete(g:ViveVimVerboseFile)
			return
		endif
		execute 'aunmenu &Vive.Vim\ &Verbose.Current\ Vim\ Verbose\ Level\ is\ '.&verbose
		if a:lvl == 0
			redir END
			set more
			set verbose=0
			amenu &Vive.Vim\ &Verbose.Current\ Vim\ Verbose\ Level\ is\ 0 :<CR>
			return
		endif
		set nomore
		execute 'silent redir >>'.g:ViveVimVerboseFile
		echomsg ">>>>> Setting verbose=".a:lvl." : ".strftime("%c")
		execute 'set verbose='.a:lvl
		execute 'amenu &Vive.Vim\ &Verbose.Current\ Vim\ Verbose\ Level\ is\ '.&verbose.' :<CR>'
	endfunction
	let VimVboseFile=escape(g:ViveVimVerboseFile,' \.')
	amenu &Vive.Vim\ &Verbose.NOTE:\ Vim\ Verbose\ Mode\ output\ is :<CR>
	execute 'amenu &Vive.Vim\ &Verbose.\ :redir\ >>'.VimVboseFile.' :<CR>'
	amenu &Vive.Vim\ &Verbose.-Sep1- <Nop>
	execute 'amenu &Vive.Vim\ &Verbose.&Delete\ '.VimVboseFile.' :call <SID>doVimVerbose(-1)<CR>'
	amenu &Vive.Vim\ &Verbose.==&0\ off<TAB>:set\ verbose=0 :call <SID>doVimVerbose(0)<CR>
	amenu &Vive.Vim\ &Verbose.>=&1\ r/w\ viminfo<TAB>:set\ verbose=1 :call <SID>doVimVerbose(1)<CR>
	amenu &Vive.Vim\ &Verbose.>=&2\ source\ <file><TAB>:set\ verbose=2 :call <SID>doVimVerbose(2)<CR>
	amenu &Vive.Vim\ &Verbose.>=&5\ search\ tags\ file<TAB>:set\ verbose\ 5 :call <SID>doVimVerbose(5)<CR>
	amenu &Vive.Vim\ &Verbose.>=&8\ autocmd\ file<TAB>:set\ verbose=8 :call <SID>doVimVerbose(8)<CR>
	amenu &Vive.Vim\ &Verbose.>=&9\ autocmd\ execution<TAB>:set\ verbose=9 :call <SID>doVimVerbose(9)<CR>
	amenu &Vive.Vim\ &Verbose.>=&12\ function\ execution<TAB>:set\ verbose=12 :call <SID>doVimVerbose(12)<CR>
	amenu &Vive.Vim\ &Verbose.>=&13\ exception\ execution<TAB>:set\ verbose=13 :call <SID>doVimVerbose(13)<CR>
	amenu &Vive.Vim\ &Verbose.>=&14\ finally\ clause<TAB>:set\ verbose=14 :call <SID>doVimVerbose(14)<CR>
	amenu &Vive.Vim\ &Verbose.>=&15\ ex\ command\ execution<TAB>:set\ verbose=15 :call <SID>doVimVerbose(15)<CR>
	amenu &Vive.Vim\ &Verbose.-Sep2- <Nop>
	execute 'amenu &Vive.Vim\ &Verbose.Current\ Vim\ Verbose\ Level\ is\ '.&verbose.' :<CR>'
	amenu &Vive.&Debugging.Select\ Break\ to\ &Delete :call <SID>deselector()<CR>
	amenu &Vive.&Debugging.Delete\ &All\ Breaks :call <SID>delbreaks()<CR>
	function s:DoDebugModeMenu()
		if !g:firstDbgMdMenuCall
			if g:ViveDebug
				let cMode='on'
				amenu &Vive.Debug.Step step<CR>
				amenu &Vive.Debug.Next next<CR>
				amenu &Vive.Debug.Continue cont<CR>
				amenu &Vive.Debug.Abort quit<CR>
				amenu &Vive.Debug.Add\ Break\ In\ This\ Function
					\ execute 'breakadd func '.strpart(matchstr(expand("<sfile>"),'\.\.\w*$'),2)<CR>
				amenu &Vive.Debug.Delete\ Break\ In\ This\ Function
					\ execute 'silent! breakdel func '.strpart(matchstr(expand("<sfile>"),'\.\.\w*$'),2)<CR>
				:debugg
				let b:DebugMenuExists=1
			else
				let cMode='off'
				:0debugg
			endif
			execute ':aunmenu &Vive.&Debugging.Toggle\ Debug\ &Mode\ ['.cMode.']'
			let g:ViveDebug=1-g:ViveDebug
		else
			let g:firstDbgMdMenuCall=0
		endif
		if g:ViveDebug
			let cMode='on'
			amenu &Vive.Debug.Step step<CR>
			amenu &Vive.Debug.Next next<CR>
			amenu &Vive.Debug.Continue cont<CR>
			amenu &Vive.Debug.Abort quit<CR>
			amenu &Vive.Debug.Add\ Break\ In\ This\ Function
				\ execute 'breakadd func '.strpart(matchstr(expand("<sfile>"),'\.\.\w*$'),2)<CR>
			amenu &Vive.Debug.Delete\ Break\ In\ This\ Function
				\ execute 'silent! breakdel func '.strpart(matchstr(expand("<sfile>"),'\.\.\w*$'),2)<CR>
			:debugg
			let b:DebugMenuExists=1
		else
			let cMode='off'
			:0debugg
			if exists("b:DebugMenuExists") && b:DebugMenuExists
				aunmenu &Vive.Debug
				let b:DebugMenuExists=0
			endif
		endif
		let s:menuIt=
			\'amenu &Vive.&Debugging.Toggle\ Debug\ &Mode\ ['.cMode.']<TAB>'.
			\g:ViveDBG.' :call <SID>DoDebugModeMenu()<CR>'
		execute s:menuIt
	endfunction
	function! s:selector()
		let tmpFile=expand(g:ViveFileDir.'/.ViveAddBrk.Tmp')
		let tmpFile=fnamemodify(tmpFile,":p")
		redir @z
		silent function
		redir END
		if &verbose
			execute 'silent redir >>'.g:ViveVimVerboseFile
			echomsg ">>>>> Resetting redir for &verbose=".&verbose." : ".strftime("%c")
		endif
		let @z=substitute(@z,'function \|(\p*)','','g')
		call delete(tmpFile)
		:new
		execute ':edit +set\ noswapfile '.tmpFile
		setlocal modifiable
		map <buffer> a :call <SID>selected()<CR>
		:stopinsert
		let @z=" Press 'a' on the line of function you wish to add a break to\<NL> Or on a non-function line for 'none'\<NL>".@z
		silent put z
		silent :%s/^\s*\n//g
		:w
		setlocal nomodifiable
	endfunction
	function! s:selected()
		let tmpFile=expand(g:ViveFileDir.'/.ViveAddBrk.Tmp')
		let tmpFile=fnamemodify(tmpFile,":p")
		if match(getline('.'),'^ ') == -1
			let funcName=expand("<cword>")
			execute 'breakadd func '.funcName
		endif
		silent bw!
		call delete(tmpFile)
		DoIfInsert
	endfunction
	amenu &Vive.&Debugging.Select\ Function\ to\ &Add\ Break :call <SID>selector()<CR>
	function! s:delbreaks()
		let tmpFile=expand(g:ViveFileDir.'/.ViveDelBrk.Tmp')
		let tmpFile=fnamemodify(tmpFile,":p")
		redir @z
		silent breaklist
		redir END
		if &verbose
			execute 'silent redir >>'.g:ViveVimVerboseFile
			echomsg ">>>>> Resetting redir for &verbose=".&verbose." : ".strftime("%c")
		endif
		call delete(tmpFile)
		:new
		execute ':edit +set\ noswapfile '.tmpFile
		silent put z
		silent :%s/^\s*\n//g
		let eline=line('$')
		let sline=1
		while sline <= eline
			let breakNum=substitute(getline(sline),'^\s\+','','')+0
			if breakNum != 0
				execute 'breakdel '.breakNum
			endif
			let sline=sline+1
		endwhile
		silent bw!
		call delete(tmpFile)
	endfunction
	function! s:deselector()
		let tmpFile=expand(g:ViveFileDir.'/.ViveDelBrk.Tmp')
		let tmpFile=fnamemodify(tmpFile,":p")
		redir @z
		silent breaklist
		redir END
		if &verbose
			execute 'silent redir >>'.g:ViveVimVerboseFile
			echomsg ">>>>> Resetting redir for &verbose=".&verbose." : ".strftime("%c")
		endif
		call delete(tmpFile)
		:new
		execute ':edit +set\ noswapfile '.tmpFile
		setlocal modifiable
		map <buffer> d :call <SID>deselected()<CR>
		:stopinsert
		let @z=" Press 'd' on the line of the break you wish to delete\<NL> Or on a non-break point line for 'none'\<NL>".@z
		silent put z
		silent :%s/^\s*\n//g
		:w
		setlocal nomodifiable
	endfunction
	function! s:deselected()
		let tmpFile=expand(g:ViveFileDir.'/.ViveDelBrk.Tmp')
		let tmpFile=fnamemodify(tmpFile,":p")
		let breakNum=substitute(getline('.'),'^\s\+','','')+0
		if breakNum != 0
			execute 'breakdel '.breakNum
		endif
		silent bw!
		call delete(tmpFile)
		DoIfInsert
	endfunction
	call s:DoDebugModeMenu()
endfunction

let s:thisScript=expand("<sfile>:p")

let g:cmdlineHit=0

augroup Vive
	autocmd!
	autocmd VimLeave * call s:isViveRunning(expand("<afile>"))
	autocmd BufDelete * call s:isViveRunning(expand("<afile>"))
augroup END

function! s:doMap(name,val)
	let sname='s:prev'.a:name
	let siname='s:iprev'.a:name
	let gname='g:Vive'.a:name
	let {sname}=maparg({gname})
	let {siname}=maparg({gname},'i')
	execute 'map <silent> '.{gname}.' '.a:val.'<CR>'
	execute 'imap <silent> '.{gname}.' <Esc>'.a:val.'<CR>'
endfunction

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
	echo "  -h          produces this message {or press ".g:ViveQQ."}"
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
	call s:doMap('DBG',':call <SID>DoDebugModeMenu()')
	call s:doMap('QQ',':call <SID>usage()')
	if has("gui_running")
		call s:doGvimMenu()
	endif
	call s:delFile(g:ViveFile)
	execute 'edit '.g:ViveFile
	set hidden noswapfile nonumber buftype=help syntax=vim filetype=vim
	" do this little diddy because if the first redir to the file is a ':r',
	" (which sets readonly???) it causes a Warning.
	" So, we do it on purpose and correct the problem
	silent :r !ls
	silent normal u
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

function! s:saveVive()
	let s:ViveWin=bufwinnr(g:ViveFile)
	let s:ViveBuf=bufnr(g:ViveFile)
	let s:clnum=line('.')
	let s:ccnum=col('.')
endfunction

function! s:restoreVive()
	if winnr() != s:ViveWin
		execute s:ViveWin.'wincmd w'
	endif
	if bufname(bufnr('')) != g:ViveFile
		execute 'b'.s:ViveBuf
	endif
	call cursor(s:clnum,s:ccnum)
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
	execute 'silent '.clnum.','.elnum.'yank "'
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
	call s:saveVive()
	call s:RedirNoEcho()
	call s:restoreVive()
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
			:breakadd func ViveFunc
			if has("gui_running")
				call s:doGvimDebug()
			endif
			:debug call ViveFunc()
			:silent! breakdel func ViveFunc
		endif
	endif
	redir END
	if &verbose
		execute 'silent redir >>'.g:ViveVimVerboseFile
		echomsg ">>>>> Resetting redir for &verbose=".&verbose." : ".strftime("%c")
	endif
	let &more=savemore
	"this avoids the final 'Hit Enter' prompt if it's there.  For some reason
	"'set nomore' doesn't turn the last one off.
	execute line('$').' append | . '
endfunction

function! s:doGvimDebug()
	if has("gui_win32")
		tearoff &Vive.Debug
	elseif has("gui_gtk")
		popup &Vive.Debug
	endif
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
