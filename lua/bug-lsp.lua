local api = vim.api
local lsp = vim.lsp
local fn = vim.fn

local M = {}

local config = {
	on_attach = nil,
}

local capabilities = lsp.protocol.make_client_capabilities()
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
local servers = {
	{ "html" },
	{ "cssls" },
	{ "jsonls" },
	{ "tsserver" },
	{ "rust_analyzer" },
	{ "pyright" },
	{
		"lua_ls",
		{
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
					library = api.nvim_get_runtime_file("", true),
				},
				telemetry = {
					enable = false,
				},
			},
		},
	},
}
for _, server in pairs(servers) do
	local cfg = require("lspconfig")[server[1]]
	local cmd = cfg.document_config.default_config.cmd[1]
	if fn.executable(cmd) == 1 then
		cfg.setup({
			flags = {
				debounce_text_changes = 150,
			},
			capabilities = capabilities,
			settings = server[2],
		})
	end
end

api.nvim_create_autocmd("LspAttach", {
	group = api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local bufnr = ev.buf
		local client = lsp.get_client_by_id(ev.data.client_id)
		-- use treesitter highlight
		client.server_capabilities.semanticTokensProvider = nil
		api.nvim_set_option_value("omnifunc", "v:lua.vim.lsp.omnifunc", { buf = bufnr })

		if type(config.on_attach) then
			config.on_attach(bufnr, ev.data.client_id)
		end
	end,
})

function M.setup(cfg)
	if type(cfg) == "table" then
		config = vim.tbl_deep_extend("force", config, cfg)
	end
end

return M

