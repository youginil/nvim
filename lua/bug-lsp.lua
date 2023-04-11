local api = vim.api
local keymap = vim.keymap
local lsp = vim.lsp

local M = {}

local attach_callbacks = {}

function M.attach(...)
	for _, cb in ipairs({ ... }) do
		table.insert(attach_callbacks, cb)
	end
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
local cmpItem = capabilities.textDocument.completion.completionItem
cmpItem.snippetSupport = true
cmpItem.preselectSupport = true
cmpItem.insertReplaceSupport = true
cmpItem.labelDetailsSupport = true
cmpItem.deprecatedSupport = true
cmpItem.commitCharactersSupport = true
cmpItem.tagSupport = { valueSet = { 1 } }
cmpItem.resolveSupport = {
	properties = {
		"documentation",
		"detail",
		"additionalTextEdits",
	},
}

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
local servers = { "html", "cssls", "jsonls", "tsserver", "rust_analyzer", "pyright" }
for _, server in pairs(servers) do
	require("lspconfig")[server].setup({
		flags = {
			debounce_text_changes = 150,
		},
		capabilities = capabilities,
	})
end

require("lspconfig").lua_ls.setup({
	capabilities = capabilities,
	flags = {
		debounce_text_changes = 150,
	},
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
				-- path = runtime_path,
			},
			diagnostics = {
				globals = { "vim" },
			},
			completion = {
				callSnippet = "Replace",
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			},
			telemetry = {
				enable = false,
			},
		},
	},
})

api.nvim_create_autocmd("LspAttach", {
	group = api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local bufnr = ev.buf
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

		local opt = { noremap = true, silent = true, buffer = bufnr }

		keymap.set("n", "gd", vim.lsp.buf.definition, opt)
		keymap.set({ "n", "i" }, "<C-h>", vim.lsp.buf.hover, opt)
		keymap.set("n", "gi", vim.lsp.buf.implementation, opt)
		keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, opt)
		keymap.set("n", "gt", vim.lsp.buf.type_definition, opt)
		keymap.set("n", "gc", vim.lsp.buf.code_action, opt)

		for _, cb in ipairs(attach_callbacks) do
			cb(client, bufnr)
		end
	end,
})

--[[ params are nil
-- https://github.com/linrongbin16/lsp-progress.nvim
local function progress_handler(err, result, ctx, config)
	bug.debug(err, result, ctx, config)
end

local old_progress_handler = lsp.handlers["$/progress"]
if old_progress_handler then
	lsp.handlers["$/progress"] = function(...)
		progress_handler(...)
		old_progress_handler(...)
	end
else
	lsp.handlers["$/progress"] = progress_handler
end
]]--

return M

