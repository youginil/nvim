local api = vim.api
local uv = vim.loop
local locals = require("nvim-treesitter.locals")
local utils = require("nvim-treesitter.ts_utils")

local M = {}

local ns_id = api.nvim_create_namespace("BugTreesitter")
local group_id = api.nvim_create_augroup("BugTreesitter", { clear = true })

local marks = {}

local function clear_marks()
	api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
end

local function hlsame()
	local node = utils.get_node_at_cursor()
	if not node then
		return
	end

	local refs = {}

	local bufnr = api.nvim_get_current_buf()
	local def_node, scope = locals.find_definition(node, bufnr)
	if def_node ~= node then
		local range = { def_node:range() }
		table.insert(refs, {
			{ range[1], range[2] },
			{ range[3], range[4] },
		})
	end

	local usages = locals.find_usages(def_node, scope, bufnr)
	for _, nd in ipairs(usages) do
		local range = { nd:range() }
		table.insert(refs, {
			{ range[1], range[2] },
			{ range[3], range[4] },
		})
	end

	for _, v in ipairs(refs) do
		local mk = api.nvim_buf_set_extmark(
			0,
			ns_id,
			v[1][1],
			v[1][2],
			{ end_row = v[2][1], end_col = v[2][2], hl_group = "SameNode" }
		)
		table.insert(marks, mk)
	end
end

local events = { "CursorMoved", "CursorMovedI", "TextChanged", "BufEnter" }
local pattern = { "*.lua", "*.ts", "*.tsx", "*.js", "*.rs", "*.py" }

local timer = nil
api.nvim_create_autocmd(events, {
	group = group_id,
	pattern = pattern,
	callback = function()
		if timer ~= nil then
			timer:close()
		end
		timer = uv.new_timer()
		timer:start(
			300,
			0,
			vim.schedule_wrap(function()
				timer = nil
				hlsame()
			end)
		)
	end,
})

api.nvim_create_autocmd(events, {
	group = group_id,
	pattern = pattern,
	callback = function()
		clear_marks()
	end,
})

return M

