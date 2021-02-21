if exists('g:loaded_substitute') || 1
	finish
endif
let g:loaded_substitute = 1

command! -bar -range -nargs=* S call s:Substitute(<line1>, <line2>, <f-args>)
cabbrev <expr> s getcmdtype() == ':' ? 'S' : 's'

function! s:Substitute(line1, line2, ...) abort
	let l:a000 = join(copy(a:000))
	if a:0 > 0 && l:a000[0] =~ '[[:punct:]]'
		" TODO: handle escaped delimiters
		let l:patterns = split(l:a000, l:a000[0], 1)
		if len(l:patterns) >= 3
			let l:patterns[2] = substitute(l:patterns[2], '\\n', '\\r', 'g')
		endif
		let l:a000 = join(l:patterns, l:a000[0])
	endif
	execute a:line1.','.a:line2.'substitute' l:a000
endfunction

function! s:SubstituteHighlight(leave) abort
	if expand('<afile>') != ':'
		return
	endif

	if !exists('s:sub_ids')
		let s:sub_ids = {}
	else
		for [l:wid, l:mid] in items(s:sub_ids)
			if win_id2win(l:wid) != 0
				call matchdelete(l:mid, l:wid)
			endif
			unlet s:sub_ids[l:wid]
		endfor
	endif

	if a:leave
		unlet s:sub_ids
		return
	endif

	" TODO: handle range, custom delimiters, and escaped delimiters
	let l:cmd = getcmdline()
	if l:cmd[0] != 'S' || l:cmd[1] != '/'
		return
	endif

	let l:pattern = split(l:cmd, '/', 1)[1]

	if empty(l:pattern)
		redraw
		return
	endif

	let l:wnr = winnr()
	windo let s:sub_ids[win_getid()] = matchadd('IncSearch', l:pattern, 0, -1, {'window': winnr()})
	execute l:wnr.'wincmd' 'w'
	redraw
endfunction

augroup SUBSTITUTE
	autocmd!
	autocmd CmdlineChanged * call s:SubstituteHighlight(0)
	autocmd CmdlineLeave   * call s:SubstituteHighlight(1)
augroup END
