local fn = vim.fn
local api = vim.api
local uv = vim.loop
local keymap = vim.keymap
local levels = vim.log.levels

local FileType = {
	File = 1,
	Directory = 2,
}

local M = {}

local cwd = ""
-- {{name = '', type = FileType, children = {}}}
local files = {}
local opend_dirs = {}
local start_file_index = nil
local buffer = nil

local function read_dir(dir)
	uv.fs_opendir(dir, function(err, data)
		if err then
			vim.notify(err, levels.ERROR, {})
			return
		end
		uv.fs_readdir(data, function(e1, entries)
			if err then
				vim.notify(e1, levels.ERROR, {})
			elseif entries == nil then
				vim.notify("No file", levels.INFO, {})
			else
				--
			end
			uv.fs_closedir(data)
		end)
	end)
end

local function close()
	api.nvim_buf_delete(buffer, { force = true })
	files = {}
	start_file_index = nil
	buffer = nil
end

function M.open()
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
	})

	local opt = { buffer = buffer }

	keymap.set({ "n", "i" }, "q", function()
		close()
	end, opt)

	keymap.set({ "n", "i" }, "<Esc>", function()
		close()
	end, opt)

	keymap.set({ "n", "i" }, "<CR>", function()
		--
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

