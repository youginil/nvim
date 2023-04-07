local api = vim.api
local fn = vim.fn
local fs = vim.fs
local loop = vim.loop

local M = {}

local HI_BLOCK_A = "StatusA"
local HI_BLOCK_B = "StatusB"
local HI_BLOCK_C = "StatusC"

local git_cache = {}

local function update()
	local l_comps = {}
	local r_comps = {}

	table.insert(l_comps, "%#" .. HI_BLOCK_A .. "# %f%m ")

	local bufnr = api.nvim_get_current_buf()
	for _, v in pairs(git_cache) do
		if vim.tbl_contains(v.bufs, bufnr) then
			table.insert(l_comps, "%#" .. HI_BLOCK_B .. "# " .. v.branch .. " ")
			break
		end
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

	local encoding = vim.o.fileencoding
	if encoding ~= "" then
		table.insert(r_comps, "%#" .. HI_BLOCK_C .. "# " .. encoding .. " ")
	end

	local filetype = vim.bo.filetype
	if type(filetype) == "string" and filetype ~= "" then
		table.insert(r_comps, "%#" .. HI_BLOCK_B .. "# " .. filetype .. " ")
	end

	table.insert(r_comps, "%#" .. HI_BLOCK_A .. "# %l:%v %p%% ")

	local line = table.concat(l_comps, "") .. "%#StatusLine#%=" .. table.concat(r_comps, "")
	api.nvim_win_set_option(0, "statusline", line)
end

local function read_branch(git_head_path)
	local git_head = io.open(git_head_path, "r")
	if git_head then
		local head = git_head:read()
		git_head:close()
		local branch, _ = head:match("ref: refs/heads/(.+)$")
		if branch then
			return branch
		end
	end
	return nil
end

local function lookup_vcs(dir, cb)
	local git_path = dir .. "/.git"
	loop.fs_stat(
		git_path,
		vim.schedule_wrap(function(err, stat)
			if err then
				local parent = fs.dirname(dir)
				if parent:find("/") ~= nil and parent ~= dir then
					lookup_vcs(parent, cb)
				end
				return
			end
			if stat.type ~= "directory" then
				return
			end
			local head = git_path .. "/HEAD"
			cb(dir, head)
		end)
	)
end

local function find_branch()
	local bufnr = api.nvim_get_current_buf()
	if not fn.buflisted(bufnr) or vim.bo[bufnr].buftype ~= "" then
		return
	end

	for _, v in pairs(git_cache) do
		if vim.tbl_contains(v.bufs, bufnr) then
			return
		end
	end

	local dir = fs.normalize(fn.expand("%:p:h"))
	for d in fs.parents(api.nvim_buf_get_name(0)) do
		if git_cache[d] then
			table.insert(git_cache[d].bufs, bufnr)
			return
		end
	end

	lookup_vcs(dir, function(git_dir, head)
		if git_cache[git_dir] then
			return
		end
		local w = vim.loop.new_fs_event()
		w:start(
			head,
			{},
			vim.schedule_wrap(function(err, _, status)
				if err then
					w:stop()
					table.remove(git_cache, git_dir)
				elseif status.change then
					git_cache[git_dir].branch = read_branch(head)
				end
				update()
			end)
		)
		local branch = read_branch(head)
		git_cache[git_dir] = { head = head, branch = branch, bufs = { bufnr }, watcher = w }
		update()
	end)
end

local gid = api.nvim_create_augroup("BugStatusline", {})
api.nvim_create_autocmd({ "BufEnter" }, {
	group = gid,
	callback = function()
		find_branch()
		update()
	end,
})

api.nvim_create_autocmd({ "DiagnosticChanged" }, {
	group = gid,
	callback = function()
		update()
	end,
})

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

return M

