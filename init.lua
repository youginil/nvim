local api = vim.api
local keymap = vim.keymap

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
keymap.set({ "n", "i", "v" }, "<Up>", "<Nop>")
keymap.set({ "n", "i", "v" }, "<Down>", "<Nop>")
keymap.set({ "n", "i", "v" }, "<Left>", "<Nop>")
keymap.set({ "n", "i", "v" }, "<Right>", "<Nop>")

keymap.set({ "n", "i" }, "<C-s>", function()
	vim.cmd("w")
end, { noremap = true })

keymap.set({ "n", "i" }, "<C-0>", function()
	vim.cmd("bd")
end, { noremap = true })

keymap.set({ "n", "i" }, "<C-q>", function()
	vim.cmd("q")
end, { noremap = true })

-- Diagnostic
vim.diagnostic.config({
	signs = false,
})
keymap.set("n", "d;", vim.diagnostic.open_float, { noremap = true })
keymap.set("n", "d,", vim.diagnostic.goto_prev, { noremap = true })
keymap.set("n", "d.", vim.diagnostic.goto_next, { noremap = true })
keymap.set("n", "d'", vim.diagnostic.setloclist, { noremap = true })

-- Pair
require("bug-pair").setup({
	before_insert_pair = function()
		require("bug-cmp").check_del_placeholder()
		return true
	end,
})

require("plugins")

require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"bash",
		"c",
		"c_sharp",
		"cpp",
		"css",
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

require("bug").setup({
	log_level = 3,
})

require("bug-base")

-- Theme
require("themes/gruvbox")
-- require("themes/vscode")

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
require("bug-comment").setup({
	mode = { "n", "v", "i" },
	key = "<C-/>",
})

-- Bufferline
local bug_bufferline = require("bug-bufferline")
keymap.set("n", "<Leader>b", function()
	bug_bufferline.select()
end, { noremap = true })

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
keymap.set({ "n", "i" }, "<C-;>", function()
	bug_search.search(bug_search.make_file_config())
end, {
	noremap = true,
})
keymap.set({ "n", "i" }, "<C-'>", function()
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
end, {})

keymap.set({ "v", "o" }, "t", function()
	bug_jump.jump_inline(1)
end, {})

keymap.set({ "v", "o" }, "T", function()
	bug_jump.jump_inline(-1)
end, {})

-- Format
local bug_format = require("bug-format")

keymap.set({ "n", "i" }, "<C-=>", function()
	bug_format.format()
end, {
	noremap = true,
})

-- Completion
require("bug-cmp")

-- lspconfig
require("bug-lsp")
-- require("lsp")

-- Outline
local outline = require("bug-outline")
keymap.set({ "n", "i" }, "<C-m>", outline.show)

