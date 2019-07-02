"=============================================================================
"    Description: 日本語入力固定モード(JpFixMode)
"                 IME/IM Control (Windows/Linux/Mac)
"     Maintainer: fuenor@gmail.com
"                 https://github.com/fuenor/im_control.vim
"                 https://sites.google.com/site/fudist/Home/vim-nihongo-ban/vim-japanese/ime-control
"=============================================================================
scriptencoding utf-8

if exists('g:disable_IM_Control') && g:disable_IM_Control == 1
  finish
endif
if exists('g:loaded_IM_Control') && g:loaded_IM_Control && !exists('fudist')
  finish
endif
if v:version < 700
  finish
endif
let g:loaded_IM_Control = 1

let s:keepcpo = &cpo
set cpo&vim

""""""""""""""""""""""""""""""
" オプション
""""""""""""""""""""""""""""""
" IM制御モード
" ---------------------------------------------------
" IM_CtrlMode = 0 | IM制御が一切行えない場合
" ---------------------------------------------------
" IM_CtrlMode = 1 | IM On/Offが個別制御できる場合
"                 | ※ IMCtrl()の設定が必要
" ---------------------------------------------------
" IM_CtrlMode = 2 | JpFixMode制御のみ
" IM_CtrlMode = 3 | JpFixMode制御+疑似vi協調モード(JpFixMode専用)
"                 |
"                 | ※ IM制御が Toggleしか使用できない場合の補助
"                 |  2 : 挿入モードへの移行時のみToggleを実行。
"                 |  3 : JpFixModeが Onなら、挿入モードでは常に IM Onと
"                 |      仮定して、ノーマルモード移行時に Toggleを実行。
" ---------------------------------------------------
" IM_CtrlMode = 4 | <C-^>でIM制御が行える場合
"                 | ※ WindowsやMacのGVimなど
" ---------------------------------------------------
" IM_CtrlMode = 5 | IBus+PythonでIM制御が行える場合 (廃止)
" ---------------------------------------------------
" IM_CtrlMode = 6 | fcitxの場合
" ---------------------------------------------------

""""""""""""""""""""""""""""""
"  日本語入力固定モードのキー設定
"  inoremap <silent> <C-j> <C-r>=IMState('FixMode')<CR>
"
"  IM_CtrlMode = 4の場合は<C-^>を付加する必要がある
"  inoremap <silent> <C-j> <C-^><C-r>=IMState('FixMode')<CR>

" init
if !exists('g:IM_CtrlMode')
  let g:IM_CtrlMode = 1
  " Windows
  if has('win95') + has('win16') + has('win32') + has('win64')
    let g:IM_CtrlMode = 4
  endif
endif

if g:IM_CtrlMode == 0
  let &cpo=s:keepcpo
  unlet s:keepcpo
  finish
endif

" ---------------------------------------------------
" ステータス行に「日本語入力固定モード」状態表示
" set statusline+=%{IMStatus('[日本語固定]')}
" ---------------------------------------------------
function! IMStatus(msg)
  " let im =  (g:IM_CtrlMode == 4 && mode() == 'i') ? &iminsert : g:IMState
  return g:IMState ? a:msg : ''
endfunction

""""""""""""""""""""""""""""""
" バッファローカルモード(全バッファでローカルにIM制御状態を保持する)
if !exists('g:IM_CtrlBufLocalMode')
  let g:IM_CtrlBufLocalMode = 0
endif
" 全バッファではなく特定バッファでのみ個別にIM制御したい場合は
" 特定バッファでのみ以下を設定。
" let b:IM_CtrlBufLocal = 1
" (例) ファイルタイプ vim (.vimrcやvimスクリプト)はIM個別制御
" au FileType vim let b:IM_CtrlBufLocal = 1

"""""""""""""""""""""""""""""
" JpFixModeの vi協調モード
if !exists('g:IM_vi_CooperativeMode')
  let g:IM_vi_CooperativeMode = 1
endif
" ---------------------------------------------------
"   0 : 使用しない
"   1 : 使用する
"   2 : 使用する(スクリプト使用してIM無効化)
"       IBusのvi協調モードのバグ対策
" ---------------------------------------------------

"""""""""""""""""""""""""""""
" 外部スクリプトを実行する際に非同期で呼び出す。
if !exists('g:IM_CtrlAsync')
  let g:IM_CtrlAsync = '&'
endif

" JpFixMode切替時に IMCtrl('Toggle')を実行する。
if !exists('g:IM_JpFixModeAutoToggle')
  let g:IM_JpFixModeAutoToggle = 0
endif
" ---------------------------------------------------
"   0 : Toggleを実行しない(Toggleではなく、モードに合わせてOn, Offを実行する)
"   1 : IMCtrl('Toggle')を実行
"   2 : IMCtrl('On')のみ実行
"   3 : IMCtrl('Off')のみ実行
"   4 : 何もしない
" ---------------------------------------------------

" モードフック
augroup InsertHookIM
  autocmd!
  autocmd InsertEnter * call IMState('Enter')
  autocmd InsertLeave * call IMState('Leave')
  autocmd BufEnter    * call <SID>BufEnter()
  autocmd BufLeave    * call <SID>BufLeave()
augroup END

if &ttimeoutlen < 0
  set timeout ttimeoutlen=100
endif

""""""""""""""""""""""""""""""
" IM制御用関数サンプル(要xvkbd)
" 環境に合わせたIM制御を行う必要がある場合は
" .vimrcで IMCtrl(cmd)を定義します。
""""""""""""""""""""""""""""""
" function! IMCtrl(cmd)
"   let cmd = a:cmd
"   if cmd == 'On'
"     let res = system('xvkbd -text "\[Control]\[Shift]\[Insert]" > /dev/null 2>&1 ')
"   elseif cmd == 'Off'
"     let res = system('xvkbd -text "\[Control]\[Shift]\[Delete]" > /dev/null 2>&1 ')
"   elseif cmd == 'Toggle'
"     let res = system('xvkbd -text "\[Control]\[space]" > /dev/null 2>&1 ')
"   endif
"   return ''
" endfunction

" 「日本語入力固定モード」状態表示のメッセージ
" %sは「日本語入力固定モード」がローカルかどうかに置き換えられる
if !exists('g:IM_CtrlMsg')
  let g:IM_CtrlMsg = 'JpFixMode%s : '
endif

""""""""""""""""""""""""""""""
" main
""""""""""""""""""""""""""""""
if !exists('g:IMState')
  let g:IMState = 0
endif
function! IMState(cmd)
  if s:init()
    return
  endif

  let l:IM_CtrlMode = g:IM_CtrlMode
  let cmd = a:cmd
  if cmd == 'Enter'
    if g:IMState
      let cmd = l:IM_CtrlMode == 1 ? 'On' : 'Toggle'
    endif
  elseif cmd == 'Leave'
    if g:IM_vi_CooperativeMode == 0
      return ''
    else
      let cmd = l:IM_CtrlMode == 1 ? 'Off' : ''
      if l:IM_CtrlMode == 3 && g:IMState
        " 疑似vi協調モード
        let cmd = 'Toggle'
      endif
    endif
  elseif cmd == 'FixMode'
    let g:IMState = g:IMState == 0 ? 2 : 0
    let msg = (exists('b:IM_CtrlBufLocal') && b:IM_CtrlBufLocal) ? '(local)' : ''
    let msg = printf(g:IM_CtrlMsg, msg)
    let cmd = g:IMState ? 'On' : 'Off'
    redraw| echo msg.cmd
    if l:IM_CtrlMode > 1
      let cmd = ''
    endif
    if g:IM_JpFixModeAutoToggle == 1
      let cmd = 'Toggle'
    elseif g:IM_JpFixModeAutoToggle == 2 && cmd == 'Off'
      let cmd = ''
    elseif g:IM_JpFixModeAutoToggle == 3 && cmd == 'On'
      let cmd = ''
    elseif g:IM_JpFixModeAutoToggle == 4
      let cmd = ''
    endif
  endif
  call IMCtrl(cmd)
  return ''
endfunction

""""""""""""""""""""""""""""""
" IM制御用関数(fcitx)
if (g:IM_CtrlMode == 6)
  if !exists('*IMCtrl')
  silent! function IMCtrl(cmd)
    let cmd = a:cmd
    if cmd == 'On'
      call system('fcitx-remote -o > /dev/null 2>&1 '.g:IM_CtrlAsync)
    elseif cmd == 'Off'
      call system('fcitx-remote -c > /dev/null 2>&1 '.g:IM_CtrlAsync)
    elseif cmd == 'Toggle'
      call system('fcitx-remote -t > /dev/null 2>&1 '.g:IM_CtrlAsync)
    endif
    return ''
  endfunction
  endif
  let g:IM_vi_CooperativeMode = 1
  let g:IM_JpFixModeAutoToggle = 0
endif

""""""""""""""""""""""""""""""
" IM制御用関数(デフォルト)
if !exists('*IMCtrl')
  if executable('xvkbd')
    function! IMCtrl(cmd)
      let cmd = a:cmd
      if cmd == 'On'
        let res = system('xvkbd -text "\[Control]\[Shift]\[Insert]" > /dev/null 2>&1 '.g:IM_CtrlAsync)
      elseif cmd == 'Off'
        let res = system('xvkbd -text "\[Control]\[Shift]\[Delete]" > /dev/null 2>&1 '.g:IM_CtrlAsync)
      elseif cmd == 'Toggle'
        let res = system('xvkbd -text "\[Control]\[space]" > /dev/null 2>&1 '.g:IM_CtrlAsync)
      endif
      return ''
    endfunction
  else
    function! IMCtrl(cmd)
      let cmd = a:cmd
      if cmd == 'On'
        echo 'IMCtrl(stub) : On'
      elseif cmd == 'Off'
        echo 'IMCtrl(stub) : Off'
      elseif cmd == 'Toggle'
        echo 'IMCtrl(stub) : Toggle'
      elseif cmd == 'stub'
        return 1
      endif
      return ''
    endfunction
  endif
endif

""""""""""""""""""""""""""""""
" 初期化
function s:init()
  if g:IM_CtrlMode == 0
    return 1
  endif
  if IMCtrlInit()
    return 1
  endif
  if g:IM_CtrlBufLocalMode && !exists('b:IM_CtrlBufLocal')
    let b:IM_CtrlBufLocal = 1
    call s:BufEnter()
  elseif exists('b:IM_CtrlBufLocal') && b:IM_CtrlBufLocal && !exists('b:IMState')
    call s:BufEnter()
  endif
  return 0
endfunction

" ユーザ定義用
" .vimrc で IMCtrlInit() を設定すると自由に初期化処理が設定可能
" 1 を返すと「日本語入力固定モード」の処理を行わなくなる。
if !exists('*IMCtrlInit')
silent! function IMCtrlInit()
  return 0
endfunction
endif

" バッファローカルモード
function s:BufEnter()
  if exists('b:IM_CtrlBufLocal')
    let b:IMStateSave = b:IM_CtrlBufLocal
    if b:IM_CtrlBufLocal
      let b:IMState = g:IMState
      let g:IMState = 0
      let g:IMState = !exists('b:IMStateLocal') ? 0 : b:IMStateLocal
    endif
  endif
endfunction

" バッファローカルモード
function s:BufLeave()
  if exists('b:IMStateSave') && b:IMStateSave
    let b:IMStateLocal = g:IMState
    let g:IMState = b:IMState
    let b:IMStateSave = 0
  endif
endfunction

if g:IM_CtrlMode != 4
  let &cpo=s:keepcpo
  unlet s:keepcpo
  finish
endif

" MacVim-kaoriya対策
if !exists('g:IM_CtrlMacVimKaoriya')
  let g:IM_CtrlMacVimKaoriya = has('gui_macvim') && has('kaoriya')
endif
if g:IM_CtrlMacVimKaoriya
  au GUIEnter * set noimdisableactivate
endif

"----------------------------------------
" for Windows / <C-^>
"----------------------------------------
if (has('gui_running') && (has('multi_byte_ime') || has('xim')))
  au GUIEnter * set iminsert=0 imsearch=0
endif

function! IMState(cmd)
  if s:init()
    return ''
  endif
  let cmd = a:cmd
  if cmd == 'Enter'
    let &iminsert = g:IMState
  elseif cmd == 'Leave'
    set iminsert=0 imsearch=0
  elseif cmd == 'FixMode'
    let msg = (exists('b:IM_CtrlBufLocal') && b:IM_CtrlBufLocal) ? '(local)' : ''
    let msg = printf(g:IM_CtrlMsg, msg)
    let g:IMState = g:IMState == 2 ? 0 : 2
    echo msg . (g:IMState ? 'On' : 'Off')
  elseif cmd == 'Toggle'
    let &iminsert = 0
  endif
  return ''
endfunction

let &cpo=s:keepcpo
unlet s:keepcpo
