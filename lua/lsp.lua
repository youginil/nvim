local api = vim.api
local fn = vim.fn
local lsp = vim.lsp
local keymap = vim.keymap
local git = require("bug-git")

local servers = {
	{
		name = "lua_ls",
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
	},
}

local default_capabilities = lsp.protocol.make_client_capabilities()
local cmpItem = default_capabilities.textDocument.completion.completionItem
cmpItem.commitCharactersSupport = true
cmpItem.deprecatedSupport = true
cmpItem.preselectSupport = true
cmpItem.snippetSupport = true

local default_config = {
	handlers = {
		["textDocument/publishDiagnostics"] = lsp.with(lsp.diagnostic.on_publish_diagnostics, {
			signs = false,
		}),
	},
	settings = vim.empty_dict(),
	init_options = vim.empty_dict(),
	capabilities = default_capabilities,
	trace = "verbose",
}

local function start_client(bufnr)
	local clients = lsp.get_active_clients({
		bufnr,
	})
	local filetype = vim.bo[bufnr].filetype
	for _, server in ipairs(servers) do
		local root_dir = nil
		if type(server.root_dir) == "function" then
			root_dir = server.root_dir()
		elseif type(server.root_dir) == "table" then
			local paths = vim.fs.find(server.root_dir)
			if vim.tbl_count(paths) > 0 then
				root_dir = vim.fs.dirname(paths[1])
			end
		end
        -- TODO: root_dir workspace_folders
		if root_dir == nil then
			root_dir = git.find_git_dir(fn.expand("%:p"))
			if root_dir == nil then
				root_dir = fn.getcwd()
			end
		end

		if vim.tbl_contains(server.filetypes, filetype) then
			local reuse = false
			for _, client in ipairs(clients) do
				if client.name == server.name and client.config.root_dir == root_dir then
					reuse = true
					lsp.buf_attach_client(bufnr, client.id)
					break
				end
			end

			if not reuse then
				local cfg = vim.tbl_deep_extend("keep", {
					name = server.name,
					cmd = server.cmd,
					root_dir,
					on_error = function(code, ...)
						bug.error("Client error", { code, desc = lsp.rpc.client_errors[code] }, { ... })
					end,
					before_init = function(initialize_params, config)
						bug.debug("Client before init", initialize_params, config)
					end,
					on_init = function(client, initialize_result)
						lsp.buf_attach_client(bufnr, client.id)
						bug.info("Client init", client.name, initialize_result)
					end,
					on_exit = function(code, signal, client_id)
						bug.info("Client exit", { code, signal, client_id })
					end,
					on_attach = function(client, buf)
						bug.info("Client attach", { client = client.name, buf })
					end,
				}, default_config)

				local fields = { "cmd_cwd", "cmd_env", "settings", "init_options", "capabilities" }
				for _, key in ipairs(fields) do
					if server[key] ~= nil then
						cfg[key] = server[key]
					end
				end

				lsp.start_client(cfg)
			end
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

