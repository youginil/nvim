local api = vim.api
local fn = vim.fn

vim.o.showtabline = 2

local hls = {
	BufferLine = "TabLineFill",
	BufferLineCurrent = "TabLineSel",
	BufferLineOther = "TabLine",
}

for grp1, grp2 in pairs(hls) do
	if fn.hlexists(grp1) == 0 then
		api.nvim_set_hl(0, grp1, { link = grp2 })
	end
end

local M = {}

-- {bufnr: number; name: string; current: boolean; modified: boolean}[]
local buffers = {}

local function render()
	local bufs = api.nvim_list_bufs()
	local win = api.nvim_get_current_win()
	local cur_bufnr = api.nvim_win_get_buf(win)
	if not vim.bo[cur_bufnr].buflisted then
		return
	end
	buffers = {}
	for _, v in ipairs(bufs) do
		local buf = vim.bo[v]
		if buf.buflisted and api.nvim_buf_is_valid(v) then
			local full_path = vim.trim(api.nvim_buf_get_name(v))
			local name = ""
			if buf.buftype ~= "" then
				name = buf.buftype
			elseif full_path ~= "" then
				local rel_name = fn.fnamemodify(full_path, ":p:.")
				name = fn.pathshorten(rel_name)
			elseif buf.filetype ~= "" then
				name = buf.filetype
			end
			if name == "" then
				name = "[No Name]"
			end
			table.insert(buffers, {
				bufnr = v,
				name = name,
				current = cur_bufnr == v,
				modified = buf.modified,
			})
		end
	end
	local list = {}
	for i, v in ipairs(buffers) do
		local name = " " .. i .. "." .. v.name .. (v.modified and " ●" or "") .. " "
		-- TODO always show selected buffer completely
		local _ = fn.strwidth(name)
		table.insert(list, "%#" .. (v.current and "BufferLineCurrent" or "BufferLineOther") .. "#" .. name)
	end
	vim.o.tabline = table.concat(list, "%#BufferlineOther#│") .. "%#BufferLine#"
	vim.cmd("redrawtabline")
end

function M.navigate(index)
	if M.current_buffer() == nil or type(index) ~= "number" or index <= 0 or index > #buffers then
		return
	end
	api.nvim_win_set_buf(0, buffers[index].bufnr)
end

function M.select()
	vim.ui.input({ prompt = "Buffer > " }, function(index)
		index = tonumber(index)
		M.navigate(index)
	end)
end

function M.current_buffer()
	local bufnr = api.nvim_get_current_buf()
	for i, v in ipairs(buffers) do
		if v.bufnr == bufnr then
			return i
		end
	end
	return nil
end

function M.prev()
	local index = M.current_buffer()
	if index == nil then
		return
	end
	if index == 1 then
		M.navigate(#buffers)
	else
		M.navigate(index - 1)
	end
end

function M.next()
	local index = M.current_buffer()
	if index == nil then
		return
	end
	if index == #buffers then
		M.navigate(1)
	else
		M.navigate(index + 1)
	end
end

local gid = api.nvim_create_augroup("BugBufferline", {})
local timer = nil
api.nvim_create_autocmd({ "BufEnter", "BufModifiedSet", "TermClose" }, {
	group = gid,
	callback = function()
		if timer ~= nil then
			timer:close()
		end
		timer = vim.loop.new_timer()
		timer:start(
			100,
			0,
			vim.schedule_wrap(function()
				timer = nil
				render()
			end)
		)
	end,
})

return M

