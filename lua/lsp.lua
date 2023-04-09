local api = vim.api
local fn = vim.fn
local lsp = vim.lsp
local keymap = vim.keymap

local servers = {
	{
		cmd = { "lua-language-server" },
		filetypes = { "lua" },
		root_dir = {
			".luarc.json",
			".luarc.jsonc",
			".luacheckrc",
			".stylua.toml",
			"stylua.toml",
			"selene.toml",
			"selene.yml",
		},
	},
}
local default_config = {
	handlers = {
		["textDocument/publishDiagnostics"] = lsp.with(lsp.diagnostic.on_publish_diagnostics, {
			signs = false,
		}),
	},
	trace = "verbose",
}

local function start_client(bufnr)
	local clients = lsp.get_active_clients({
		bufnr,
	})
	local filetype = vim.bo[bufnr].filetype
	for _, server in ipairs(servers) do
		if vim.tbl_contains(server.filetypes, filetype) then
			local client_exists = false
			for _, client in ipairs(clients) do
				if client.cmd == server.cmd then
					client_exists = true
					break
				end
			end
			if client_exists then
				break
			end

			local cfg = vim.tbl_deep_extend("keep", {
				cmd = server.cmd,
			}, default_config)

			local fields = { "cmd_cwd", "cmd_env", "init_options" }
			for key in ipairs(fields) do
				if vim.tbl_contains(fields, key) then
					cfg[key] = server[key]
				end
			end

			if type(server.root_dir) == "function" then
				cfg.root_dir = server.root_dir()
			elseif type(server.root_dir) == "table" then
				local paths = vim.fs.find(server.root_dir)
				if vim.tbl_count(paths) > 0 then
					cfg.root_dir = vim.fs.dirname(paths[0])
				end
			end
			lsp.start_client(cfg)
		end
	end
end

local function on_list(options)
	fn.setqflist({}, " ", options)
	api.nvim_command("cfirst")
end

lsp.buf.definition({ on_list = on_list })
lsp.buf.references(nil, { on_list = on_list })

api.nvim_create_autocmd("LspAttach", {
	group = api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(args)
		local bufnr = args.buf
		local client = vim.lsp.get_client_by_id(args.data.client_id)

		if client.server_capabilities.completionProvider then
			vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
		end

		if client.server_capabilities.definitionProvider then
			vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc"
		end

		local opt = { noremap = true, silent = true, buffer = bufnr }

		keymap.set("n", "gd", vim.lsp.buf.definition, opt)
		keymap.set({ "n", "i" }, "<C-h>", vim.lsp.buf.hover, opt)
		keymap.set("n", "gi", vim.lsp.buf.implementation, opt)
		keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, opt)
		keymap.set("n", "gt", vim.lsp.buf.type_definition, opt)
		keymap.set("n", "gc", vim.lsp.buf.code_action, opt)
	end,
})

api.nvim_create_autocmd("LspDetach", {
	callback = function(args)
		vim.cmd("setlocal tagfunc< omnifunc<")
	end,
})

-- api.nvim_create_autocmd("LspProgressUpdate", {
-- 	callback = function()
-- 		fn.redrawstatus()
-- 	end,
-- })

-- api.nvim_create_autocmd("LspRequest", {
-- 	callback = function()
-- 		fn.redrawstatus()
-- 	end,
-- })
--
-- api.nvim_create_autocmd("LspTokenUpdate", {
-- 	callback = function()
-- 		--
-- 	end,
-- })

api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		local bufnr = ev.buf
		start_client(bufnr)
	end,
})

