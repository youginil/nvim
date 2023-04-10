local api = vim.api
local loop = vim.loop
local fs = vim.fs
local fn = vim.fn
local path = require("bug-path")

local M = {}

function M.find_git_dir(file)
	file = loop.fs_realpath(file)
	for dir in fs.parents(file) do
		if fn.isdirectory(dir .. path.sep .. ".git") == 1 then
			return dir
		end
	end
	return nil
end

return M

