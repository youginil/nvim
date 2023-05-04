local api = vim.api
local uv = vim.loop
local fs = vim.fs
local fn = vim.fn

local path = require("bug-path")
local bug = require("bug")

local M = {}

-- {[git_dir] = {bufs = {}}}
local git_cache = {}
local update_callbacks = {}

function M.get_branch(bufnr)
	for _, v in pairs(git_cache) do
		if vim.tbl_contains(v.bufs, bufnr) then
			return v.branch
		end
	end
end

function M.find_git_dir(file)
	file = uv.fs_realpath(file)
	for dir in fs.parents(file) do
		if fn.isdirectory(path.join(dir, ".git")) == 1 then
			return dir
		end
	end
	return nil
end

function M.read_branch(git_dir, cb)
	local head_file = path.join(git_dir, ".git", "HEAD")
	uv.fs_open(head_file, "r", 755, function(err, fd)
		if err then
			cb(err)
			return
		end
		uv.fs_fstat(fd, function(e0, stat)
			if e0 then
				cb(e0)
				return
			end
			uv.fs_read(fd, stat.size, 0, function(e1, data)
				if e1 then
					cb(e1)
					return
				end
				uv.fs_close(fd, function(e2)
					if e2 then
						cb(e2)
						return
					end
					local branch, _ = data:match("ref: refs/heads/(.+)[$\n]")
					cb(nil, branch)
				end)
			end)
		end)
	end)
end

function M.update_branch()
	local bufnr = api.nvim_get_current_buf()

	for _, v in pairs(git_cache) do
		if vim.tbl_contains(v.bufs, bufnr) then
			return
		end
	end

	local file = fn.expand("%:p")
	if not file then
		return
	end

	local git_dir = M.find_git_dir(file)
	if git_dir == nil then
		return
	end

	if git_cache[git_dir] == nil then
		M.read_branch(git_dir, function(err, branch)
			if err then
				bug.error(err)
				git_cache[git_dir] = nil
				return
			end
			local w = vim.loop.new_fs_event()
			w:start(
				path.join(git_dir, ".git", "HEAD"),
				{},
				vim.schedule_wrap(function(e1, _, status)
					if err then
						bug.error(e1)
						w:stop()
						git_cache[git_dir] = nil
					elseif status.change then
						M.read_branch(git_dir, function(e0, b0)
							if e0 then
								bug.error(e0)
								w:stop()
								git_cache[git_dir] = nil
								return
							end
							git_cache[git_dir].branch = b0
							for _, cb in ipairs(update_callbacks) do
								vim.schedule_wrap(function()
									cb()
								end)
							end
						end)
					end
				end)
			)
			git_cache[git_dir] = { branch = branch, bufs = { bufnr }, watcher = w }
			for _, cb in ipairs(update_callbacks) do
				vim.schedule_wrap(function()
					cb()
				end)
			end
		end)
	else
		table.insert(git_cache[git_dir].bufs, bufnr)
		for _, cb in ipairs(update_callbacks) do
			cb()
		end
	end
end

function M.add_update_callback(cb)
	table.insert(update_callbacks, cb)
end

api.nvim_create_autocmd("BufEnter", {
	callback = function()
		M.update_branch()
	end,
})

return M

