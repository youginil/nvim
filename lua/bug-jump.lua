local api = vim.api
local fn = vim.fn
local levels = vim.log.levels

local bug = require("bug")

api.nvim_set_hl(0, "BugJumpKey", { link = "IncSearch" })
--api.nvim_set_hl(0, "BugJumpUnmatched", { link = "Normal" })
api.nvim_set_hl(0, "BugJumpUnmatched", {})
api.nvim_set_hl(0, "BugJumpKeyNext", { link = "IncSearch" })

local ns_dim = nil
local ns_hint = nil

local priority_dim = 101
local priority_hint = 102

local KeyPrefix = { "", ";", "'", ",", ".", "/", "`", "\\", "-", "=" }
local KeyPool = (function()
	local pool = {}
	local exclude = { "j" }
	local si = fn.char2nr("a")
	local ei = fn.char2nr("z")
	for i = si, ei do
		local char = fn.nr2char(i)
		if not vim.tbl_contains(exclude, char) then
			table.insert(pool, char)
		end
	end
	local digitals = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
	for _, i in ipairs(digitals) do
		table.insert(pool, i)
	end
	return pool
end)()

local mark_dim_id = nil

-- {{row = 1, col = 1, key = "1", mark = 1}, ...}
local matched_hints = {}

local function dim(buf, start_row, start_col, end_row, end_col)
	bug.info("Dim", start_row, start_col, end_row, end_col)
	ns_dim = api.nvim_create_namespace("")
	mark_dim_id = api.nvim_buf_set_extmark(buf, ns_dim, start_row - 1, start_col - 1, {
		end_row = end_row - 1,
		end_col = end_col,
		hl_group = "BugJumpUnmatched",
		hl_eol = true,
		priority = priority_dim,
	})
end

local function clear_dim_mark(buf)
	bug.info("Clear dim mark")
	api.nvim_buf_del_extmark(buf, ns_dim, mark_dim_id)
end

local function delete_hint(buf, hints, pos)
	api.nvim_buf_del_extmark(buf, ns_hint, hints[pos].mark)
	table.remove(hints, pos)
end

local function clear_hint_marks(buf)
	bug.info("Clear hint marks")
	for _, item in ipairs(matched_hints) do
		api.nvim_buf_del_extmark(buf, ns_hint, item.mark)
	end
end

local function on_exit(buf)
	clear_hint_marks(buf)
	clear_dim_mark(buf)
	api.nvim_buf_clear_namespace(buf, ns_dim, 1, -1)
	api.nvim_buf_clear_namespace(buf, ns_hint, 1, -1)
	bug.info("Exit")
end

local function draw_hints(buf)
	bug.info("Draw hints")
	if #matched_hints == 0 then
		return
	end
	ns_hint = api.nvim_create_namespace("")
	for _, item in ipairs(matched_hints) do
		local key = item.key
		item.mark = api.nvim_buf_set_extmark(buf, ns_hint, item.row - 1, item.col - 1, {
			virt_text = #key > 1 and {
				{ string.sub(key, 1, 1), "BugJumpKey" },
				{ string.sub(key, 2, #key), "BugJumpKeyNext" },
			} or { { key, "BugJumpKey" } },
			virt_text_pos = "overlay",
			priority = priority_hint,
		})
	end
end

local function search_line(row, kw, line, start_col, end_col)
	line = string.lower(line)
	local matched = {}
	if end_col == nil then
		end_col = #line
	end
	while true do
		local s, e = string.find(line, kw, start_col, true)
		if s == nil then
			break
		else
			table.insert(matched, {
				row = row,
				col = s,
			})
			start_col = e + 1
		end
	end
	return matched
end

local function handle_input(buf, cb)
	if #matched_hints == 0 then
		return
	end
	while true do
		vim.cmd("redraw")
		bug.info("Wait user to select...")
		local ok, c = pcall(vim.fn.getchar)
		if not ok then
			return
		end
		local char = fn.nr2char(c)
		bug.info("User select ", char, c)
		-- check first
		local exists = false
		for _, item in ipairs(matched_hints) do
			if string.sub(item.key, 1, 1) == char then
				exists = true
				break
			end
		end
		if exists then
			clear_hint_marks(buf)
			for i = #matched_hints, 1, -1 do
				local item = matched_hints[i]
				if string.sub(item.key, 1, 1) == char then
					item.key = string.sub(item.key, 2)
				else
					delete_hint(buf, matched_hints, i)
				end
			end
			if #matched_hints == 1 then
				cb({ matched_hints[1].row, matched_hints[1].col })
				return
			else
				draw_hints(buf)
			end
		else
			vim.notify("No match", levels.WARN, {})
			return
		end
	end
end

local function search(start_row, start_col, end_row, end_col, kw, cb)
	if start_row >= end_row and start_col >= end_col then
		return
	end
	kw = string.lower(kw)
	local buf = api.nvim_get_current_buf()
	local lines = api.nvim_buf_get_lines(buf, start_row - 1, end_row, true)
	matched_hints = {}
	local line_matched = search_line(start_row, kw, lines[1], start_col)
	vim.list_extend(matched_hints, line_matched)
	for row = start_row + 1, end_row - 1 do
		local line = lines[row - start_row + 1]
		line_matched = search_line(row, kw, line, 1)
		vim.list_extend(matched_hints, line_matched)
	end
	if #lines > 1 then
		line_matched = search_line(end_row, kw, lines[#lines], 1, end_col)
		vim.list_extend(matched_hints, line_matched)
	end
	if #matched_hints == 0 then
		return
	end
	if #matched_hints == 1 then
		cb({ matched_hints[1].row, matched_hints[1].col })
		return
	end
	api.nvim_exec2("nohl", {})
	dim(buf, start_row, start_col, end_row, end_col)
	local curpos = fn.getpos(".")
	local index_before_cursor = 0
	for i, item in ipairs(matched_hints) do
		if item.row < curpos[2] or (item.row == curpos[2] and item.col < curpos[3]) then
			index_before_cursor = i
		else
			break
		end
	end
	local max_key_count = #KeyPrefix * #KeyPool
	if #matched_hints > max_key_count then
		local flag = 1
		while #matched_hints > max_key_count do
			if flag > 0 and index_before_cursor ~= 1 then
				table.remove(matched_hints, 1)
				index_before_cursor = index_before_cursor - 1
			end
			if flag < 0 and index_before_cursor ~= #matched_hints then
				table.remove(matched_hints, #matched_hints)
			end
			flag = -flag
		end
	end
	local key_list = {}
	for _, prefix in ipairs(KeyPrefix) do
		for _, v in ipairs(KeyPool) do
			table.insert(key_list, prefix .. v)
			if #key_list >= #matched_hints then
				break
			end
		end
		if #key_list >= #matched_hints then
			break
		end
	end
	local index_after_cursor = index_before_cursor + 1
	local ki = 1
	while ki <= #key_list do
		if index_after_cursor <= #matched_hints then
			matched_hints[index_after_cursor].key = key_list[ki]
			index_after_cursor = index_after_cursor + 1
			ki = ki + 1
		end
		if index_before_cursor >= 1 then
			matched_hints[index_before_cursor].key = key_list[ki]
			index_before_cursor = index_before_cursor - 1
			ki = ki + 1
		end
	end
	draw_hints(buf)
	handle_input(buf, cb)
	on_exit(buf)
end

local function get_char()
	local ok, c = pcall(vim.fn.getchar)
	if not ok then
		return nil
	end
	return fn.nr2char(c)
end

local M = {}

function M.jump()
	local kw = get_char()
	if kw == nil then
		return
	end
	local win = api.nvim_get_current_win()
	local info = fn.getwininfo(win)[1]
	local line = fn.getline(info.botline)
	search(info.topline, 1, info.botline, #line, kw, function(pos)
		fn.cursor(pos)
	end)
end

function M.setup(opts)
	if type(opts) ~= "table" then
		return
	end
end

return M

