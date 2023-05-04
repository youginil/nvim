# Neovim config

## Requirements

- [fd](https://github.com/sharkdp/fd)
- [ripgrep](https://github.com/BurntSushi/ripgrep)

## Installation

```
cd ~/.config
git clone https://github.com/youginil/nvim.git
cd ~/.config/nvim
nvim init.lua
:PackerSync
```

### Cursor Movement

- `h` - left
- `j` - down N lines
- `k` - up N lines
- `l` - right
- `w` - cursor N words forward
- `b` - cursor N words backward
- `e` - cursor forward to the end of word N
- `ge` - go backwards to the end of the previous word
- `0` - to first character in the line
- `^` - to first non-blank character in the line
- `$` - to the next EOL (end of line) position
- `gg` - goto line N (default: first line), on the first non-blank character
- `G` - goto line N (default: last line), on the first non-blank character
- `%` - find the next brace, bracket, comment, or "#if"/ "#else"/"#endif" in this line and go to its match
- `f` - remap to bug-jump, jump to anywhere

### Scrolling

- `<C-d>` - window N lines Downwards (default: 1/2 window)
- `<C-u>` - window N lines Upwards (default: 1/2 window)
- `<C-f>` - window N pages Forwards (downwards)
- `<C-b>` - window N pages Backwards (upwards)
- `zt` - redraw, current line at top of window
- `zz` - redraw, current line at center of window
- `zb` - redraw, current line at bottom of window

### Text Object Motions

- `w` - N words forward
- `W` - N blank-separated WORDs forward
- `e` - forward to the end of the Nth word
- `E` - forward to the end of the Nth blank-separated WORD
- `b` - N words backward
- `B` - N blank-separated WORDs backward
- `ge` - backward to the end of the Nth word
- `gE` - backward to the end of the Nth blank-separated WORD
- `` {op}{vVC-v}i{wW<[{`'"t} ``- operate on inner block.`t` for tag
- `` {op}{vVC-v}a{wW<[{`'"t} ``- operate on block.`t` for tag

### Search & Replace

- `/` - `/{pattern}[/[offset]]<CR>` search forward for the Nth occurrence of {pattern}
- `?` - `?{pattern}[?[offset]]<CR>` search backward for the Nth occurrence of {pattern}
- `/<CR>` - repeat last search, in the forward direction
- `?<CR>` - repeat last search, in the backward direction
- `n` - repeat last search
- `N` - repeat last search, in opposite direction
- `*` - search forward for the identifier under the cursor
- `#` - search backward for the identifier under the cursor

- `<C-;>` - bug-search, search file
- `<C-'>` - bug-search, search text

### Editing

- `a` - append text after the cursor (N times)
- `A` - append text at the end of the line (N times)
- `i` - insert text before the cursor (N times) (also: <Insert>)
- `I` - insert text before the first non-blank in the line (N times)
- `o` - open a new line below the current line, append text (N times)
- `O` - open a new line above the current line, append text (N times)
- `x` - delete N characters under and after the cursor
- `X` - delete N characters before the cursor
- `d` - delete the text that is moved over with {motion}
- `dd` - delete N lines
- `J` - join N-1 lines (delete <EOL>s)
- `y` - yank the text moved over with {motion} into a register
- `yy` - yank N lines into a register
- `p` - put a register after the cursor position (N times)
- `P` - put a register before the cursor position (N times)
- `r` - replace N characters with {char}
- `c` - change the text that is moved over with {motion}
- `cc` - change N lines
- `~` - switch case for N characters and advance cursor
- `<<` - move N lines one shiftwidth left
- `>>` - move N lines one shiftwidth right
- `:[range]s[ubstitute]/{pattern}/{string}/[g][c]` - substitute {pattern} by {string} in [range] lines; with [g], replace all occurrences of {pattern}; with [c], confirm each replacement
- `:[range]s[ubstitute] [g][c]` - repeat previous ":s" with new range and options
- `&` - Repeat previous ":s" on current line without options
- `u` - undo last N changes
- `<C-r>` - redo last N undone changes
- `si` - bug-surround, insert surround char
- `sd` - bug-surround, delete surround char
- `sc` - bug-surround, change surround char
- `<C-=>` - bug-format, formatting

### Visual Mode

- `v` - start highlighting characters } move cursor and use; again to stop
- `V` - start highlighting linewise } operator to affect; again to sop
- `<C-v>` - start highlighting blockwise } highlighted text; again to stop

### Range

- `,` - separates two line numbers
- `.` - the current line
- `$` - the last line in the file
- `%` - equal to 1,$ (the entire file)
- `*` - equal to '<,'> (visual area)

### Repeat

- `.` - Repeat last change, with count replaced with [count]
- `:[range]g[lobal]/{pattern}/[cmd]` - Execute the Ex command [cmd] (default ":p") on the lines within [range] where {pattern} matches.
- `:[range]g[lobal]!/{pattern}/[cmd]` - Execute the Ex command [cmd] (default ":p") on the lines within [range] where {pattern} does NOT match.

### Buffer

- `<C-s>` - save current buffer. equals `:w`
- `<C-0>` - close buffer. equals `:bd`
- `<C-,>` - bug-bufferline. previous buffer
- `<C-.>` - bug-bufferline. next buffer
- `<C-{1-9}>` - bug-bufferline. change to Nth buffer
- `:wa` - write all changed buffers
- `:q!` - quit current buffer, unless changes have been made; Exit Vim when there are no other non-help buffers
- `:qa` - exit Vim, unless changes have been made
- `:qa!` - exit Vim always, discard any changes
- `<C-q>` - quit current window (when one window quit Vim). equals `:q`

### Window

- `:split` - split window into two parts
- `:split {file}` - split window and edit {file} in one of them
- `:vsplit {file}` - same, but split vertically
- `:terminal` - open a terminal window
- `<C-w>j` - move cursor to window below
- `<C-w>k` - move cursor to window above
- `<C-w>h` - move cursor to window left
- `<C-w>l` - move cursor to window right

### Diagnostic

- `<C-i>`- open diagnostic window
- `<C-p>` - vim.diagnostic.goto_prev
- `<C-n>` - vim.diagnostic.goto_next
- `<Leader>d` vim.diagnostic.setloclist

### LSP

- `gd` - vim.lsp.buf.definition
- `<C-h>` - vim.lsp.buf.hover
- `gi` - vim.lsp.buf.implementation
- `<C-k>` - vim.lsp.buf.signature_help
- `gt` - vim.lsp.buf.type_definition
- `gc` - vim.lsp.buf.code_action

### Others

- `<C-l>` - clear and redraw the screen
- `gx` - open link

## TODO

- global Replace
- diff between origin and buffer `vim.diff`
- [a prev parameter
- ]a next parameter
- parameter text object
- Movement at insert mode
- quickfix shortcut
- fix: switch buffer while cursor is in floating window, eg. bug-search
- fix: bug-bufferline multiple windows
- https://github.com/lewis6991/gitsigns.nvim
- https://github.com/sindrets/diffview.nvim
- https://github.com/emmetio/emmet
- https://github.com/nvim-lua/plenary.nvim
- search workspace symbols
- https://github.com/RRethy/vim-illuminate

## Remappable keys

```
C-H
C-I
C-J
C-K
C-N
C-P
C-Q
C-S
C-T
C--
C-=
C-;
C-'
C-,
C-.
C-/
C-0~9
```

