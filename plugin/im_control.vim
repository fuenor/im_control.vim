"=============================================================================
"    Description: 日本語入力固定モード(JpFixMode)
"                 IME/IM Control (Windows/Linux/Mac)
"     Maintainer: fuenor@gmail.com
"                 https://github.com/fuenor/im_control.vim
"                 https://sites.google.com/site/fudist/Home/vim-nihongo-ban/vim-japanese/ime-control
"        CAUTION: WindowsまたはIBus+Pythonが使える環境以外ではxvkbd等なんらかの
"                 IM制御方法を用意する必要があります。
"=============================================================================
let s:version = 116
scriptencoding utf-8

if exists('g:disable_IM_Control') && g:disable_IM_Control == 1
  finish
endif
if exists('g:IM_Control_version') && g:IM_Control_version < s:version
  let g:loaded_IM_Control = 0
endif
if exists('g:loaded_IM_Control') && g:loaded_IM_Control && !exists('fudist')
  finish
endif
if v:version < 700 || &cp
  finish
endif
let g:loaded_IM_Control = 1
let g:IM_Control_version = s:version

""""""""""""""""""""""""""""""
" オプション
""""""""""""""""""""""""""""""
" IM制御モード
" ---------------------------------------------------
" | 0 | 何もしない                                    |
" ---------------------------------------------------
"  IM制御が一切行えない場合
" ---------------------------------------------------
" | 1 | On/Off個別制御                                |
" ---------------------------------------------------
"  IM On/Offが個別制御できる場合
" ---------------------------------------------------
" | 2 | JpFixMode制御のみ                             |
" | 3 | JpFixMode制御+疑似vi協調モード(JpFixMode専用) |
" ---------------------------------------------------
"  IM制御が Toggleしか使用できない場合の補助
"  2 : 挿入モードへの移行時のみJpFixMode制御を行う。
"  3 : JpFixModeが Onなら、挿入モードでは常に IM Onと
"      仮定して、ノーマルモード移行時に Toggleを実行。
" ---------------------------------------------------
" | 4 | <C-^>でIM制御が行える場合
" ---------------------------------------------------
" ---------------------------------------------------
" | 5 | IBus+PythonでIM制御が行える場合
" ---------------------------------------------------
"  起動後に内部設定が行われ IM_CtrlMode=1に自動変更される。

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
  finish
endif

" IBus+Python
if g:IM_CtrlMode == 5
  if !exists('g:IM_CtrlIBusPython')
    let g:IM_CtrlIBusPython = 1
  endif
  let g:IM_CtrlMode = 1
endif
if g:IM_CtrlMode != 1
  let g:IM_CtrlIBusPython = 0
endif

" ---------------------------------------------------
" ステータス行に「日本語入力固定モード」状態表示
" set statusline+=%{IMStatus('[日本語固定]')}
" ---------------------------------------------------
function! IMStatus(msg)
  let im =  (g:IM_CtrlMode == 4 && mode() == 'i') ? &iminsert : g:IMState
  return im ? a:msg : ''
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

" JpFixMode切替時に Toggleも実行する。
if !exists('g:IM_JpFixModeAutoToggle')
  let g:IM_JpFixModeAutoToggle = 0
endif

"""""""""""""""""""""""""""""
" IBusのPythonによる制御方法指定
if !exists('g:IM_CtrlIBusPython')
  let g:IM_CtrlIBusPython = 0
endif
" IBusを Pythonで切替可能可能な場合に設定するオプション
" CAUTION: current_input_contxt は current_input_context のtypoと思われる
"          IBusのアップデートで修正されるかもしれないので要注意
" ---------------------------------------------------
"   0 : 使用しない
"   1 : 常にPythonスクリプト制御を使用する
"   2 : 常にPythonインターフェイス制御を使用する
"   3 : Pythonインターフェイスか外部スクリプトを自動設定
" ---------------------------------------------------

" 自動生成するpythonスクリプト保存場所
if !exists('g:IM_CtrlIBusPythonFileDir')
  let g:IM_CtrlIBusPythonFileDir = fnamemodify(tempname(), ':h')
endif

" 使用するPythonインターフェイス
if !exists('g:IM_CtrlIBusPythonVer')
  let g:IM_CtrlIBusPythonVer = 'python'
  " if !has('python') && has('python3')
  "   let g:IM_CtrlIBusPythonVer = 'python3'
  " endif
endif

" JpFixModeの切り替えにPyIBusToggleEx()を使用する
if !exists('g:IM_CtrlIBusPythonToggleEx')
  let g:IM_CtrlIBusPythonToggleEx = 0
endif

" モードフック
augroup InsertHookIM
  autocmd!
  autocmd InsertEnter * call IMState('Enter')
  autocmd InsertLeave * call IMState('Leave')
  autocmd BufEnter    * call <SID>BufEnter()
  autocmd BufLeave    * call <SID>BufLeave()
augroup END

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
  let cmd = a:cmd
  if cmd == 'Enter'
    if g:IMState
      let cmd = g:IM_CtrlMode == 1 ? 'On' : 'Toggle'
      if g:IM_CtrlIBusPython
        let cmd = ''
        call PyIBusEnableEx()
      endif
    endif
  elseif cmd == 'Leave'
    if g:IM_vi_CooperativeMode == 0
      return ''
    elseif g:IM_vi_CooperativeMode == 2 && g:IM_CtrlIBusPython
      let cmd = ''
      call PyIBusDisableEx()
    else
      let cmd = g:IM_CtrlMode == 1 ? 'Off' : ''
      if g:IM_CtrlMode == 3 && g:IMState
        " 疑似vi協調モード
        let cmd = 'Toggle'
      endif
    endif
  elseif cmd == 'FixMode'
    let g:IMState = g:IMState == 0 ? 2 : 0
    let msg = (exists('b:IM_CtrlBufLocal') && b:IM_CtrlBufLocal) ? '(local)' : ''
    let msg = printf(g:IM_CtrlMsg, msg)
    if g:IM_CtrlIBusPythonToggleEx
      call PyIBusToggleEx()
      let cmd = g:IMState ? 'On' : 'Off'
      redraw| echo msg.cmd
      return ''
    endif
    let cmd = g:IMState ? 'On' : 'Off'
    redraw| echo msg.cmd
    if g:IM_CtrlMode > 1
      let cmd = ''
    endif
    if g:IM_JpFixModeAutoToggle == 1
      let cmd = 'Toggle'
    endif
  endif
  call IMCtrl(cmd)
  return ''
endfunction

""""""""""""""""""""""""""""""
" IM制御用関数(デフォルト)
silent! function IMCtrl(cmd)
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
silent! function IMCtrlInit()
  return 0
endfunction

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

""""""""""""""""""""""""""""""
" PythonでIBusの制御

if IM_CtrlIBusPython
  function! IMCtrl(cmd)
    let cmd = a:cmd
    if cmd == 'On'
      call PyIBusEnable()
    elseif cmd == 'Off'
      call PyIBusDisable()
    elseif cmd == 'Toggle'
      call PyIBusToggle()
    endif
    return ''
  endfunction
endif

function! PyIBusEnable()
exe g:IM_CtrlIBusPythonVer.' << EOF'
import ibus
bus = ibus.Bus()
ic  = ibus.InputContext(bus, bus.current_input_contxt())
if not ic.is_enabled():
  ic.enable()
EOF
endfunction

function! PyIBusDisable()
exe g:IM_CtrlIBusPythonVer.' << EOF'
import ibus
bus = ibus.Bus()
ic  = ibus.InputContext(bus, bus.current_input_contxt())
if ic.is_enabled():
  ic.disable()
EOF
endfunction

function! PyIBusToggle()
exe g:IM_CtrlIBusPythonVer.' << EOF'
import ibus
bus = ibus.Bus()
ic  = ibus.InputContext(bus, bus.current_input_contxt())
if ic.is_enabled():
  ic.disable()
else:
  ic.enable()
EOF
endfunction

function! PyIBusToggleEx()
exe g:IM_CtrlIBusPythonVer.' << EOF'
import ibus,vim
bus = ibus.Bus()
ic  = ibus.InputContext(bus, bus.current_input_contxt())
if ic.is_enabled():
  ic.disable()
  vim.command("let g:IMState=0")
else:
  ic.enable()
  vim.command("let g:IMState=2")
EOF
endfunction
" IBusのvi協調モード対策にInsertEnter時に使用するIM有効化コマンド
silent! function PyIBusEnableEx()
  " 外部をコマンドを実行するなら & を付けて非同期で実行すること
  call IMCtrl('On')
endfunction
" IBusのvi協調モード対策にInsertLeave時に使用するIM無効化コマンド
silent! function PyIBusDisableEx()
  " 外部をコマンドを実行するなら & を付けて非同期で実行すること
  call IMCtrl('Off')
endfunction

if IM_CtrlIBusPython == 3
  if !has(g:IM_CtrlIBusPythonVer)
    " Pythonインターフェイスがない
    let IM_CtrlIBusPython = 1
  elseif !has('gui_running')
    " 非GUIではすべてPythonインターフェイスを使用する
    let IM_CtrlIBusPython = 2
  endif
endif
if IM_CtrlIBusPython == 0 || !has(g:IM_CtrlIBusPythonVer)
  let IM_CtrlIBusPythonToggleEx = 0
endif

let s:pydir = expand(g:IM_CtrlIBusPythonFileDir)
if g:IM_CtrlIBusPython == 1 || g:IM_CtrlIBusPython == 3 || (g:IM_CtrlIBusPython == 2 && g:IM_vi_CooperativeMode == 2)
  if isdirectory(s:pydir) == 0
    call mkdir(s:pydir, 'p')
  endif
  let s:pyfile = s:pydir . '/ibus-enable.py'
  if !filereadable(s:pyfile)
    call writefile(['import ibus', 'bus = ibus.Bus()', 'ic = ibus.InputContext(bus, bus.current_input_contxt())', 'ic.enable()'], expand(s:pyfile))
  endif
  let s:pyfile = s:pydir . '/ibus-disable.py'
  if !filereadable(s:pyfile)
    call writefile(['import ibus', 'bus = ibus.Bus()', 'ic = ibus.InputContext(bus, bus.current_input_contxt())', 'ic.disable()'], expand(s:pyfile))
  endif
  let s:pyfile = s:pydir . '/ibus-toggle.py'
  if !filereadable(s:pyfile)
    call writefile(['import ibus', 'bus = ibus.Bus()', 'ic = ibus.InputContext(bus, bus.current_input_contxt())', 'if ic.is_enabled():', '  ic.disable()', 'else:', '  ic.enable()'], expand(s:pyfile))
  endif
  let s:pydir = escape(s:pydir, ' ')
  if g:IM_CtrlIBusPython == 1
    function! PyIBusEnable()
      let res = system('python '.s:pydir.'/ibus-enable.py '.g:IM_CtrlAsync)
    endfunction
    function! PyIBusDisable()
      let res = system('python '.s:pydir.'/ibus-disable.py '.g:IM_CtrlAsync)
    endfunction
    function! PyIBusToggle()
      let res = system('python '.s:pydir.'/ibus-toggle.py '.g:IM_CtrlAsync)
    endfunction
    function! PyIBusEnableEx()
      call PyIBusEnable()
    endfunction
  elseif g:IM_CtrlIBusPython == 3
    function! PyIBusEnableEx()
      let res = system('python '.s:pydir.'/ibus-enable.py '.g:IM_CtrlAsync)
    endfunction
  endif
  if g:IM_vi_CooperativeMode == 2
    function! PyIBusDisableEx()
      let res = system('python '.s:pydir.'/ibus-disable.py &')
    endfunction
  endif
endif

" For your eyes only.
if exists('g:fudist')
  inoremap <silent> <C-j> <C-r>=IMState('FixMode')<CR>
endif

if g:IM_CtrlMode != 4
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
silent! inoremap <silent> <ESC> <ESC>
silent! inoremap <silent> <C-[> <ESC>

function! IMState(cmd)
  if s:init()
    return
  endif
  let cmd = a:cmd
  if cmd == 'Enter'
    let &iminsert = g:IMState
  elseif cmd == 'Leave'
    let g:IMState = &iminsert
    set iminsert=0 imsearch=0
  elseif cmd == 'FixMode'
    let msg = (exists('b:IM_CtrlBufLocal') && b:IM_CtrlBufLocal) ? '(local)' : ''
    let msg = printf(g:IM_CtrlMsg, msg)
    echo msg . (&iminsert == 2 ? 'On' : 'Off')
  endif
  return ''
endfunction

" For your eyes only.
if exists('g:fudist')
  inoremap <silent> <C-j> <C-^><C-r>=IMState('FixMode')<CR>
endif

