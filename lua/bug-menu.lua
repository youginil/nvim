local api = vim.api
local fn = vim.fn

local bug = require("bug")

local M = {}

local ns = api.nvim_create_namespace("BugMenu")

function M:new(options, handle_line)
	self.__index = self
	local buf = api.nvim_create_buf(false, true)
	local o = vim.tbl_extend("force", {
		relative = "editor",
		row = 0,
		col = 0,
		width = 100,
		height = 100,
		lines = {},
		index = 1,
		hls = {}, -- {[index] = "highlight"}
		onselect = nil,
		-- internal
		buf = buf,
		start_index = 1,
		end_index = 1,
		marks = {},
		scroll_height = 0,
	}, options)
	o.length = #o.lines
	if o.height > o.length then
		o.height = o.length
	end
	if o.index - o.start_index + 1 > o.height then
		o.start_index = o.index - o.height + 1
	end
	o.end_index = o.start_index + o.height - 1
	if o.height < o.length then
		o.scroll_height = math.floor(o.height / o.length * o.height)
		if o.scroll_height < 1 then
			o.scroll_height = 1
		end
	end
	local win = api.nvim_open_win(o.buf, false, {
		relative = o.relative,
		row = o.row,
		col = o.col,
		width = o.width,
		height = o.height,
		style = "minimal",
		noautocmd = true,
	})
	o.win = win
	setmetatable(o, self)
	if handle_line == nil then
		o:handle_line(function(s, _, avail_width)
			local w = fn.strdisplaywidth(s)
			while w >= avail_width do
				s = string.sub(s, 0, -2)
				w = fn.strdisplaywidth(s)
			end
			return s .. string.rep(" ", avail_width - w)
		end)
	else
		o:handle_line(handle_line)
	end
	api.nvim_win_set_option(o.win, "winhl", "Normal:Pmenu")
	o:render()
	return o
end

function M:handle_line(cb)
	local avail_width = self.width - (self.height == self.length and 2 or 3)
	for index, line in ipairs(self.lines) do
		self.lines[index] = " " .. cb(line, index, avail_width) .. " "
	end
end

function M:render(first)
	api.nvim_buf_set_lines(
		self.buf,
		0,
		self.end_index - self.start_index + 1,
		false,
		bug.tbl_slice(self.lines, self.start_index, self.end_index)
	)
	for index, hl in pairs(self.hls) do
		if index >= self.start_index and index <= self.end_index then
			api.nvim_buf_add_highlight(self.buf, -1, hl, index - self.start_index, 0, -1)
		end
	end
	api.nvim_buf_add_highlight(self.buf, -1, "PmenuSel", self.index - self.start_index, 0, -1)
	if #self.marks > 0 then
		for _, mark in ipairs(self.marks) do
			api.nvim_buf_del_extmark(self.buf, ns, mark)
		end
		self.marks = {}
	end
	if self.height < self.length then
		local top = math.ceil((self.start_index - 1) / self.length * self.height)
		if self.scroll_height + top > self.height then
			top = self.height - self.scroll_height
		end
		for i = top, top + self.scroll_height - 1, 1 do
			local mark = api.nvim_buf_set_extmark(self.buf, ns, i, 0, {
				end_row = i,
				end_col = 0,
				virt_text = { { " ", "PmenuThumb" } },
				virt_text_pos = "right_align",
			})
			table.insert(self.marks, mark)
		end
	end
	if self.onselect ~= nil then
		self.onselect(self.index, first)
	end
end

function M:close()
	api.nvim_win_close(self.win, true)
	api.nvim_buf_delete(self.buf, { force = true })
end

function M:confirm()
	self:close()
	return self.index
end

function M:prev()
	if self.index == 1 then
		self.index = self.length
		self.end_index = self.length
		self.start_index = self.end_index - self.height + 1
	elseif self.index == self.start_index then
		self.index = self.index - 1
		self.start_index = self.index
		self.end_index = self.end_index - 1
	else
		self.index = self.index - 1
	end
	self:render()
end

function M:next()
	if self.index == self.length then
		self.index = 1
		self.start_index = 1
		self.end_index = self.start_index + self.height - 1
	elseif self.index == self.end_index then
		self.index = self.index + 1
		self.end_index = self.index
		self.start_index = self.start_index + 1
	else
		self.index = self.index + 1
	end
	self:render()
end

return M

