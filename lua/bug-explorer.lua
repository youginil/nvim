local fn = vim.fn
local api = vim.api
local uv = vim.loop
local keymap = vim.keymap
local levels = vim.log.levels
local path = require("bug-path")

local exclude_files = { ".DS_Store", ".git" }

local M = {}

local cwd = ""
local lines = {}
local buffer = nil
local reading = false
local opened = false

local function make_line(file)
	return "  "
		.. string.rep("    ", file.depth)
		.. (file.isdir and (file.isopen and "▼ " or "▶ ") or "")
		.. file.name
end

local function read_dir(dir)
	if reading then
		return
	end
	reading = true
	uv.fs_opendir(
		dir,
		vim.schedule_wrap(function(err, fd)
			if err then
				vim.notify(err, levels.ERROR, {})
			else
				local files = {}
				while true do
					local entries = uv.fs_readdir(fd)
					if entries then
						for _, entry in ipairs(entries) do
							if not vim.tbl_contains(exclude_files, entry.name) then
								table.insert(files, {
									name = entry.name,
									path = dir .. path.sep .. entry.name,
									isdir = entry.type == "directory",
									isopen = false,
									depth = 0,
								})
							end
						end
					else
						break
					end
				end
				table.sort(files, function(a, b)
					if a.isdir then
						if b.isdir then
							return a.name < b.name
						end
						return true
					end
					if b.isdir then
						return false
					end
					return a.name < b.name
				end)
				local start_idx = -1
				local initial = #lines == 0
				if initial then
					lines = files
					start_idx = 0
				else
					for idx, item in ipairs(lines) do
						if item.isdir and item.path == dir then
							local depth = item.depth + 1
							local ii = idx + 1
							for i = #files, 1, -1 do
								local file = files[i]
								file.depth = depth
								table.insert(lines, ii, file)
							end
							start_idx = idx
							break
						end
					end
				end
				if start_idx >= 0 then
					local list = {}
					for _, file in ipairs(files) do
						table.insert(list, make_line(file))
					end
					api.nvim_buf_set_lines(buffer, start_idx, start_idx, false, list)
					if initial then
						fn.cursor({ 1, 1 })
					end
				end
			end
			uv.fs_closedir(fd)
			reading = false
		end)
	)
end

local function close()
	api.nvim_buf_delete(buffer, { force = true })
	lines = {}
	buffer = nil
	reading = false
	opened = false
end

function M.open()
	if opened then
		return
	end
	opened = true
	local vim_width = vim.o.columns
	local vim_height = vim.o.lines
	local top = 5
	local left = vim_width / 4
	buffer = api.nvim_create_buf(false, true)

	api.nvim_open_win(buffer, true, {
		relative = "editor",
		width = vim_width / 2,
		height = vim_height - top * 2,
		row = top,
		col = left,
		style = "minimal",
		noautocmd = true,
	})

	local opt = { buffer = buffer }

	keymap.set({ "n", "i" }, "q", function()
		close()
	end, opt)

	keymap.set({ "n", "i" }, "<Esc>", function()
		close()
	end, opt)

	keymap.set({ "n", "i" }, "<CR>", function()
		local curpos = fn.getcurpos()
		local row = curpos[2]
		local file = lines[row]
		if file.isdir then
			if file.isopen then
				local si = row
				local ei = row
				local depth = file.depth + 1
				for i = si + 1, #lines do
					if lines[i].depth == depth then
						ei = i
					else
						break
					end
				end
				if si ~= ei then
					api.nvim_buf_set_lines(buffer, si, ei, false, {})
					for _ = si + 1, ei do
						table.remove(lines, si + 1)
					end
				end
				file.isopen = false
			else
				file.isopen = true
				read_dir(file.path)
			end
			api.nvim_buf_set_lines(buffer, row - 1, row, false, { make_line(file) })
		else
			close()
			vim.cmd("edit " .. file.path)
		end
	end, opt)

	read_dir(cwd)
end

local gid = api.nvim_create_augroup("BugExplorer", { clear = true })

api.nvim_create_autocmd({ "VimEnter" }, {
	group = gid,
	callback = function()
		cwd = fn.getcwd()
	end,
})

return M

