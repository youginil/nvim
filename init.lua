local api = vim.api
local fn = vim.fn
local keymap = vim.keymap
local lsp = vim.lsp

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.smarttab = true
vim.o.expandtab = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.hlsearch = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.foldenable = false
vim.o.laststatus = 3
vim.g.mapleader = " "

-- Mappings
keymap.set({ "n", "v" }, "<Leader><Leader>", function()
	local word = ""
	local mode = fn.mode()
	if mode == "v" then
		local sr, sc = unpack(fn.getpos("."), 2, 3)
		local er, ec = unpack(fn.getpos("v"), 2, 3)
		if sr == er then
			if sc > ec then
				sc, ec = ec, sc
			end
			local line = fn.getline(sr)
			print(sc, ec)
			word = string.sub(line, sc, ec)
			print(word)
		end
	elseif mode == "n" then
		word = fn.expand("<cword>")
	end
	if word ~= "" then
		vim.cmd(string.format("h %s", word))
	end
end, { noremap = true })

keymap.set({ "n", "i" }, "<C-s>", function()
	vim.cmd("w")
end, { noremap = true })

keymap.set({ "n", "i" }, "<C-0>", function()
	vim.cmd("bd")
end, { noremap = true })

keymap.set({ "n", "i" }, "<C-q>", function()
	vim.cmd("q")
end, { noremap = true })

keymap.set("n", "<Tab>h", "<C-w>h", { noremap = true })
keymap.set("n", "<Tab>j", "<C-w>j", { noremap = true })
keymap.set("n", "<Tab>k", "<C-w>k", { noremap = true })
keymap.set("n", "<Tab>l", "<C-w>l", { noremap = true })
keymap.set("n", "<Tab><Tab>", "<C-w>w", { noremap = true })
keymap.set("n", "<Tab>-", "<C-w>-", { noremap = true })
keymap.set("n", "<Tab>=", "<C-w>+", { noremap = true })
keymap.set("n", "<Tab>,", "<C-w><", { noremap = true })
keymap.set("n", "<Tab>.", "<C-w>>", { noremap = true })

keymap.set("n", "<Leader>t", function()
	vim.cmd(":term")
	api.nvim_input("i")
end, { noremap = true })

vim.diagnostic.config({
	signs = false,
})
keymap.set({ "n", "i" }, "<C-y>", vim.diagnostic.open_float, { noremap = true })
keymap.set({ "n", "i" }, "<C-p>", vim.diagnostic.goto_prev, { noremap = true })
keymap.set({ "n", "i" }, "<C-n>", vim.diagnostic.goto_next, { noremap = true })
keymap.set("n", "<Leader>d", vim.diagnostic.setloclist, { noremap = true })

-- Base
local bug = require("bug").setup({
	log_level = os.getenv("NVIM_LOG_LEVEL") or "warn",
})

-- Theme
require("bug-theme").setup({
	colorscheme = os.getenv("NVIM_THEME") or "vscode",
})

-- Pair
local bugpair = require("bug-pair").setup({
	before_insert_pair = function()
		require("bug-cmp").del_placeholder_at_cursor()
		return true
	end,
})

-- Surround
local bug_surround = require("bug-surround")
keymap.set("n", "sc", function()
	bug_surround.change()
end, { noremap = true })

keymap.set("n", "sd", function()
	bug_surround.delete()
end, { noremap = true })

keymap.set({ "n", "v" }, "si", function()
	bug_surround.insert()
end, { noremap = true })

-- Comment
local comment = require("bug-comment")
keymap.set({ "n", "v", "i" }, "<C-/>", comment.toggle_comment, { noremap = true })

-- Bufferline
local bug_bufferline = require("bug-bufferline")

keymap.set({ "n", "i" }, "<C-.>", function()
	api.nvim_input("<Esc>")
	bug_bufferline.next()
end, { noremap = true, silent = true })

keymap.set({ "n", "i" }, "<C-,>", function()
	api.nvim_input("<Esc>")
	bug_bufferline.prev()
end, { noremap = true, silent = true })

for i = 1, 9, 1 do
	keymap.set({ "n", "i" }, "<C-" .. i .. ">", function()
		api.nvim_input("<Esc>")
		bug_bufferline.navigate(i)
	end, { noremap = true })
end

-- StatusLine
local statusline = require("bug-statusline")
statusline.setup()

-- Search
local bug_search = require("bug-search")
keymap.set({ "n", "i" }, "<C-j>", function()
	bug_search.search(bug_search.make_file_config())
end, {
	noremap = true,
})
keymap.set({ "n", "i" }, "<C-t>", function()
	bug_search.search(bug_search.make_text_config())
end, {
	noremap = true,
})

-- Git
local git = require("bug-git")
git.add_update_callback(function()
	statusline.update()
end)
git.update_branch()

-- Jump
local bug_jump = require("bug-jump")

keymap.set({ "n", "v", "o" }, "f", function()
	bug_jump.jump()
end, { noremap = true })

-- Explorer
local explorer = require("bug-explorer")
keymap.set("n", "<C-;>", function()
	explorer.open()
end)

-- Format
local bug_format = require("bug-format")

keymap.set({ "n", "i" }, "<C-=>", function()
	bug_format.format()
end, {
	noremap = true,
})

require("plugins")

require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"bash",
		"c",
		"c_sharp",
		"cpp",
		"css",
		"dart",
		"go",
		"html",
		"java",
		"javascript",
		"json",
		"json5",
		"lua",
		"markdown",
		"php",
		"python",
		"ruby",
		"rust",
		"scss",
		"sql",
		"toml",
		"tsx",
		"typescript",
		"vim",
		"vue",
	},
	highlight = {
		enable = true,
	},
})

-- Treesitter
require("bug-treesitter")

-- Completion
local bugcmp = require("bug-cmp")

-- lspconfig
require("bug-lsp").setup({
	on_attach = function(bufnr)
		local opt = { noremap = true, silent = true, buffer = bufnr }

		keymap.set("n", "gd", lsp.buf.definition, opt)
		keymap.set({ "n", "i" }, "<C-h>", lsp.buf.hover, opt)
		keymap.set("n", "gi", lsp.buf.implementation, opt)
		keymap.set({ "n", "i" }, "<C-k>", lsp.buf.signature_help, opt)
		keymap.set("n", "gt", lsp.buf.type_definition, opt)
		keymap.set("n", "gc", lsp.buf.code_action, opt)
	end,
})

-- Outline
local outline = require("bug-outline")
keymap.set({ "n", "i" }, "<C-'>", outline.show, { noremap = true })

-- Handle keys
keymap.set("i", "<CR>", function()
	if bugcmp.handle_enter() then
		return
	end
	if bugpair.handle_enter() then
		return
	end
	bug.feedkeys("<CR>", "ni")
end, { noremap = true })

keymap.set("i", "<Tab>", function()
	if bugcmp.handle_tab() then
		return
	end
	bug.feedkeys("<Tab>", "ni")
end, { noremap = true })

keymap.set("i", "<S-Tab>", function()
	if bugcmp.handle_shift_tab() then
		return
	end
	bug.feedkeys("<S-Tab>", "ni")
end, { noremap = true })

keymap.set("i", "<BS>", function()
	if bugcmp.handle_backspace() then
		return
	end
	if bugpair.handle_backspace() then
		return
	end
	bug.feedkeys("<BS>", "ni")
end, { noremap = true })

keymap.set("i", "<Up>", function()
	if bugcmp.handle_up() then
		return
	end
	bug.feedkeys("<Up>", "ni")
end)

keymap.set("i", "<Down>", function()
	if bugcmp.handle_down() then
		return
	end
	bug.feedkeys("<Down>", "ni")
end)

