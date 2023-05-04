local api = vim.api
local fn = vim.fn
local lsp = vim.lsp

local buggit = require("bug-git")
local bug = require("bug")

local M = {}

local HI_BLOCK_A = "StatusA"
local HI_BLOCK_B = "StatusB"
local HI_BLOCK_C = "StatusC"

-- {[client_id] = ''}
local client_progress = {}

function M.update()
	local l_comps = {}
	local r_comps = {}

	table.insert(l_comps, "%#" .. HI_BLOCK_A .. "# %f%m ")

	local bufnr = api.nvim_get_current_buf()
	local branch = buggit.get_branch(bufnr)
	if branch then
		table.insert(l_comps, "%#" .. HI_BLOCK_B .. "# " .. branch .. " ")
	end

	local severity = vim.diagnostic.severity
	local diag = {
		[severity.ERROR] = { 0, "✘" },
		[severity.WARN] = { 0, "⚠" },
		[severity.INFO] = { 0, "𝖎" },
		[severity.HINT] = { 0, "♥" },
	}
	for _, item in ipairs(vim.diagnostic.get(0, {})) do
		diag[item.severity][1] = diag[item.severity][1] + 1
	end
	local diag_list = {}
	local diag_severities = { severity.ERROR, severity.WARN, severity.INFO, severity.HINT }
	for _, level in ipairs(diag_severities) do
		local n, char = unpack(diag[level])
		if n > 0 then
			table.insert(diag_list, char .. " " .. n)
		end
	end
	if #diag_list > 0 then
		table.insert(l_comps, "%#" .. HI_BLOCK_C .. "# " .. table.concat(diag_list, " ") .. " ")
	end

	local lsp_progress = ""
	local clients = lsp.get_active_clients({ bufnr })
	for _, client in ipairs(clients) do
		local progress = client_progress[client.id]
		if progress then
			lsp_progress = progress
		end
	end

	local encoding = vim.o.fileencoding
	if encoding ~= "" then
		table.insert(r_comps, "%#" .. HI_BLOCK_C .. "# " .. encoding .. " ")
	end

	local filetype = vim.bo.filetype
	if type(filetype) == "string" and filetype ~= "" then
		table.insert(r_comps, "%#" .. HI_BLOCK_B .. "# " .. filetype .. " ")
	end

	table.insert(r_comps, "%#" .. HI_BLOCK_A .. "# %l:%v %p%% ")

	local line = table.concat(l_comps, "") .. "%#StatusLine# " .. lsp_progress .. " %=" .. table.concat(r_comps, "")
	api.nvim_win_set_option(0, "statusline", line)
end

function M.setup()
	local is_light = vim.o.background == "light"
	local hls = {
		[HI_BLOCK_A] = is_light and { bg = "#0451A5", fg = "#FFFFFF" } or { bg = "#8bba7f", fg = "#282828" },
		[HI_BLOCK_B] = is_light and { bg = "#098658", fg = "#FFFFFF" } or { bg = "#504945", fg = "#a9b665" },
		[HI_BLOCK_C] = is_light and { bg = "#F3F3F3", fg = "#343434" } or { bg = "#282828", fg = "#e2cca9" },
	}
	for group, setting in pairs(hls) do
		if fn.hlexists(group) == 0 then
			vim.api.nvim_set_hl(0, group, setting)
		end
	end
end

-- https://github.com/linrongbin16/lsp-progress.nvim
local function progress_handler(err, result, ctx)
	if err then
		bug.error(err)
		return
	end
	local client_id = ctx.client_id
	local value = result.value
	-- 	local token = result.token
	local p = nil
	if value.kind == "begin" or value.kind == "report" then
		if type(value.percentage) == "number" then
			p = { percent = value.percentage, message = value.message }
		end
	end
	if p then
		local client = lsp.get_client_by_id(client_id)
		client_progress[client_id] = string.format("[%s] %s", client.name, p.percent)
			.. "%%"
			.. (p.message and " " .. p.message or "")
	-- 		bug.debug(client_progress[client_id])
	else
		client_progress[client_id] = nil
	end
	M.update()
end

local old_handler = lsp.handlers["$/progress"]
if old_handler then
	lsp.handlers["$/progress"] = function(...)
		progress_handler(...)
		return old_handler(...)
	end
else
	lsp.handlers["$/progress"] = progress_handler
end

local gid = api.nvim_create_augroup("BugStatusline", {})

api.nvim_create_autocmd({ "BufEnter" }, {
	group = gid,
	callback = function()
		M.update()
	end,
})

api.nvim_create_autocmd({ "DiagnosticChanged" }, {
	group = gid,
	callback = function()
		M.update()
	end,
})

return M

