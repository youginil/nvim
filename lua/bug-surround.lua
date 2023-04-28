local api = vim.api
local fn = vim.fn

local Tag = "<%a+>"
local Brackets = {
	["("] = ")",
	["["] = "]",
	["{"] = "}",
	["<"] = ">",
	["'"] = "'",
	['"'] = '"',
	["`"] = "`",
}
local Quotes = { '"', "'", "`" }

local WordChar = "[a-zA-Z0-9%-_]"

local mark_ns_id = nil
local mark_id = nil

local function set_tip(msg)
	msg = " " .. msg .. " "
	if mark_id ~= nil then
		api.nvim_buf_del_extmark(0, mark_ns_id, mark_id)
	end
	mark_ns_id = api.nvim_create_namespace("")
	local _, cur_row, cur_col = unpack(fn.getcurpos())
	mark_id = api.nvim_buf_set_extmark(0, mark_ns_id, cur_row - 1, cur_col - 1, {
		virt_text = { { msg, "IncSearch" } },
		virt_text_pos = "eol",
		priority = 101,
	})
end

local function clear_tip()
	if mark_id ~= nil then
		api.nvim_buf_del_extmark(0, mark_ns_id, mark_id)
	end
end

local function resolve_input(s)
	if table.index_of(Quotes, s) > 0 then
		return s, s
	end
	if Brackets[s] ~= nil then
		return s, Brackets[s]
	end
	local l, r = table.find(Brackets, s)
	if l ~= nil then
		return l .. " ", " " .. r
	end
	if string.find(s, Tag .. "$") == 1 then
		return s, "</" .. string.sub(s, 2)
	end
end

local function search(line, target, reverse, plain)
	local col_s = nil
	local col_e = nil
	local idx = 1
	while true do
		local s, e = string.find(line, target, idx, plain)
		if s == nil then
			break
		else
			col_s = s
			col_e = e
			idx = e + 1
			if reverse ~= true then
				break
			end
		end
	end
	return col_s, col_e
end

local function search_replace(tar_l, tar_r, rep_l, rep_r)
	bug.info(string.format("%s%s -> %s%s", tar_l, tar_r, rep_l, rep_r))
	local _, cur_row, cur_col = unpack(fn.getcurpos())
	local line = fn.getline(cur_row)
	local line_before_cursor = string.sub(line, 1, cur_col)
	local row_l = cur_row
	local col_s_l, col_e_l = search(line_before_cursor, tar_l, true, true)
	if col_s_l == nil then
		for i = cur_row - 1, 1, -1 do
			row_l = i
			local l = fn.getline(i)
			col_s_l, col_e_l = search(l, tar_l, true, true)
			if col_s_l ~= nil then
				break
			end
		end
	end
	if col_s_l == nil then
		api.nvim_err_writeln("Invalid target char: " .. tar_l)
		return
	end
	local line_after_cursor = string.sub(line, cur_col + 1)
	local row_r = cur_row
	local col_s_r, col_e_r = search(line_after_cursor, tar_r, false, true)
	if col_s_r == nil then
		for i = cur_row + 1, fn.line("$") do
			row_r = i
			col_s_r, col_e_r = search(fn.getline(i), tar_r, false, true)
			if col_s_r ~= nil then
				break
			end
		end
	else
		col_s_r = col_s_r + cur_col
		col_e_r = col_e_r + cur_col
	end
	if col_s_r == nil then
		api.nvim_err_writeln("Invalid target char: " .. tar_l)
		return
	end
	api.nvim_buf_set_text(0, row_r - 1, col_s_r - 1, row_r - 1, col_e_r, { rep_r })
	api.nvim_buf_set_text(0, row_l - 1, col_s_l - 1, row_l - 1, col_e_l, { rep_l })
end

local function get_input(prev_tip, use_tag_abbr)
	local s = ""
	while true do
		local tip = prev_tip .. (#s > 0 and " " .. s or s)
		if #tip > 0 then
			set_tip(tip)
		end
		vim.cmd("redraw")
		local ok, c = pcall(fn.getchar)
		if not ok or c == 27 then
			clear_tip()
			return nil
		end
		s = s .. fn.nr2char(c)
		if use_tag_abbr == true and s == "t" then
			local _, cur_row, cur_col = unpack(fn.getcurpos())
			local line = fn.getline(cur_row)
			local line_before_cursor = string.sub(line, 1, cur_col)
			local col_s, col_e = search(line_before_cursor, Tag, true, false)
			if col_s == nil then
				for i = cur_row - 1, 1, -1 do
					line = fn.getline(i)
					col_s, col_e = search(line, Tag, true, false)
					if col_s ~= nil then
						break
					end
				end
			end
			if col_s ~= nil then
				s = string.sub(line, col_s, col_e)
			end
		end
		local l, r = resolve_input(s)
		if l ~= nil then
			return l, r
		end
	end
	return nil
end

local function insert_pair(range, txt_l, txt_r)
	local _, cur_row, cur_col = unpack(fn.getcurpos())
	local line = fn.getline(cur_row)
	local lr = cur_row
	local lc = cur_col
	local rr = cur_row
	local rc = cur_col
	if type(range) == "string" then
		if range == "w" then
			local line_before_cursor = string.sub(line, 1, cur_col)
			local line_after_cursor = string.sub(line, cur_col + 1)
			for i = cur_col, 1, -1 do
				if string.find(string.sub(line_before_cursor, i, i), WordChar) == nil then
					break
				else
					lc = i
				end
			end
			for i = 1, #line_after_cursor do
				if string.find(string.sub(line_after_cursor, i, i), WordChar) == nil then
					break
				else
					rc = cur_col + i
				end
			end
		elseif range == "l" then
			local pre_white_spaces = string.gsub(line, "(%s*)[^%s].*$", "%1")
			lc = #pre_white_spaces == #line and #line or (#pre_white_spaces + 1)
			rc = #line
		else
			api.nvim_err_writeln("Invalid insert mode")
			return
		end
	else
		lr, lc, rr, rc = unpack(range)
	end
	if lr == rr and lc == rc and #line == 0 then
		return
	end
	api.nvim_buf_set_text(0, rr - 1, rc, rr - 1, rc, { txt_r })
	api.nvim_buf_set_text(0, lr - 1, lc - 1, lr - 1, lc - 1, { txt_l })
end

local M = {}

function M.change()
	if not vim.bo.buflisted then
		return
	end
	local tar_l, tar_r = get_input("Change by:", true)
	if tar_l == nil then
		return
	end
	local rep_l, rep_r = get_input("Change " .. tar_l .. " to", true)
	if rep_l == nil then
		return
	end
	search_replace(tar_l, tar_r, rep_l, rep_r)
	clear_tip()
end

function M.delete()
	if not vim.bo.buflisted then
		return
	end
	local tar_l, tar_r = get_input("Delete by", true)
	if tar_l == nil then
		return
	end
	search_replace(tar_l, tar_r, "", "")
	clear_tip()
end

function M.insert()
	if not vim.bo.buflisted then
		return
	end
	if vim.fn.mode() == "v" then
		local ss = fn.getpos("v")
		local se = fn.getpos(".")
		local s = get_input("Wrap Selection by", false)
		if s ~= nil then
			local txt_l, txt_r = resolve_input(s)
			if txt_l ~= nil then
				insert_pair({ ss[2], ss[3], se[2], se[3] }, txt_l, txt_r)
			end
		end
	else
		local ok, c = pcall(fn.getchar)
		if not ok or c == 27 then
			return nil
		end
		local range = fn.nr2char(c)
		local s
		if range == "w" then
			s = get_input("Wrap Word by", false)
		elseif range == "l" then
			s = get_input("Wrap Line by", false)
		end
		if s ~= nil then
			local txt_l, txt_r = resolve_input(s)
			if txt_l ~= nil then
				insert_pair(range, txt_l, txt_r)
			end
		end
	end
	clear_tip()
end

return M

