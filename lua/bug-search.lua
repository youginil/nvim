local api = vim.api
local fn = vim.fn

local BugMenu = require("bug-menu")

local M = {}

local win_max_width = 100
local win_max_height = 30
local win_width = win_max_width
local win_height = win_max_height
local prompt_height = 1

-- {title = "", delay = 300, start = fn(kw, cb(err, item[])), stop = fn, onselect = fn(index)}
local config = {
	title = "",
	delay = 250,
	start = function(kw, cb)
		print(kw, cb)
	end,
	stop = function() end,
	onselect = function(index)
		print(index)
	end,
}

local reg_chars = { "(", ")", "[", "]", "^", "$", "-" }

local function escape(kw)
	for _, char in ipairs(reg_chars) do
		kw = string.gsub(kw, "%" .. char, "\\" .. char)
	end
	return kw
end

local rg_exe = "rg"
local rg_ignores = " --glob='!node_modules/*' --glob='!package-lock.json' --glob='!Cargo.lock' "
local rg_options = " --ignore-case --colors=path:none --colors=line:none --colors=column:none --colors=match:none "

local fd_exe = "fd"

function M.make_file_config()
	local job = nil
	local list = {}

	local function stop_job()
		if job ~= nil then
			fn.jobstop(job)
			job = nil
		end
	end

	return {
		title = "FILE",
		delay = 250,
		start = function(kw, cb)
			stop_job()
			local cmd = fd_exe .. ' -t f -p "' .. kw .. '"'
			job = fn.jobstart(cmd, {
				on_stdout = function(job_id, data)
					if job_id ~= job then
						return
					end
					list = {}
					for i = #data, 1, -1 do
						local v = data[i]
						if v ~= "" then
							table.insert(list, fn.fnamemodify(v, ":p:."))
						end
					end
					cb(nil, list)
				end,
				on_stderr = function(job_id, data)
					if job_id ~= job then
						return
					end
					local msg = table.concat(data, "\n")
					if #msg > 0 then
						bug.error("stderr", job_id, data)
						cb({ msg = msg }, {})
					end
				end,
				on_exit = function(job_id)
					if job_id == job then
						job = nil
					end
				end,
				stdout_buffered = true,
			})
			if job == 0 or job == -1 then
				print(string.format("BugSearch: Invalid command: %s", cmd))
				job = nil
			end
		end,
		stop = stop_job,
		onselect = function(index)
			local file = list[index]
			if file ~= nil then
				vim.cmd("edit " .. file)
				api.nvim_input("<Esc>")
				fn.cursor({ 1, 1 })
			end
		end,
	}
end

function M.make_text_config()
	local job = nil
	local list = {}

	local function stop_job()
		if job ~= nil then
			fn.jobstop(job)
			job = nil
		end
	end

	return {
		title = "TEXT",
		delay = 400,
		start = function(kw, cb)
			stop_job()
			local cmd = rg_exe .. rg_options .. rg_ignores .. '"' .. escape(kw) .. '" --max-columns 500 --column .'
			job = fn.jobstart(cmd, {
				on_stdout = function(job_id, data)
					if job_id ~= job then
						return
					end
					list = {}
					local result = {}
					data = table.slice(data, 1, 200)
					for _, v in ipairs(data) do
						for file, row, col, content in string.gmatch(v, "(.+):(%d+):(%d+):(.+)") do
							local filename = fn.fnamemodify(file, ":p:.")
							content = vim.trim(content)
							table.insert(list, {
								file = file,
								row = row,
								col = col,
							})
							table.insert(result, string.format("%s %s:%s %s", filename, row, col, content))
						end
					end
					cb(nil, result)
				end,
				on_stderr = function(job_id, data)
					if job_id ~= job then
						return
					end
					local msg = table.concat(data, "\n")
					if #msg > 0 then
						bug.error("stderr", job_id, data)
						cb({ msg = msg }, {})
					end
				end,
				on_exit = function(job_id)
					if job_id == job then
						job = nil
					end
				end,
				stdout_buffered = true,
			})
			if job == 0 or job == -1 then
				print(string.format("BugSearch: Invalid command: %s", cmd))
				job = nil
			end
		end,
		stop = stop_job,
		onselect = function(index)
			local item = list[index]
			if item ~= nil then
				vim.cmd("edit " .. item.file)
				api.nvim_input("<Esc>")
				fn.cursor({ item.row, item.col })
			end
		end,
	}
end

local result_menu = nil
local result_menu_row = 0
local result_menu_col = 0
local result_menu_width = 0
local result_menu_height = 0
local prompt_win = nil
local prompt_buf = nil

local prev_win = nil

local keyword = ""
local search_timer = nil

local group_id = nil
local ns = api.nvim_create_namespace("bug-search")
local tip_mark = nil

local function set_tip(tip)
	if tip_mark ~= nil then
		api.nvim_buf_del_extmark(prompt_buf, ns, tip_mark)
		tip_mark = nil
	end
	if tip == nil then
		return
	end
	tip_mark = api.nvim_buf_set_extmark(
		prompt_buf,
		ns,
		0,
		0,
		{ virt_text = { { tip, "NormalFloat" } }, virt_text_pos = "right_align" }
	)
end

local function close_result()
	if result_menu ~= nil then
		result_menu:close()
		result_menu = nil
	end
end

local function close()
	keyword = ""
	bug.info("Close BugSearch")
	close_result()
	api.nvim_buf_delete(prompt_buf, { force = true })
	api.nvim_input("<Esc>")
end

local function process()
	close_result()
	local sign = fn.prompt_getprompt(prompt_buf)
	local kw = string.sub(fn.getline("."), #sign + 1)
	kw = string.lower(vim.trim(kw))
	if kw == keyword then
		return
	end
	keyword = kw
	if #kw == 0 then
		set_tip()
		return
	end
	set_tip("･･･")
	if search_timer ~= nil then
		search_timer:close()
	end
	search_timer = vim.loop.new_timer()
	search_timer:start(
		config.delay,
		0,
		vim.schedule_wrap(function()
			search_timer = nil
			config.stop()
			config.start(keyword, function(err, list)
				if err ~= nil then
					set_tip("ERROR")
					return
				end
				if kw ~= keyword then
					return
				end
				if #list == 0 then
					set_tip("NO MATCHED")
				else
					set_tip()
					result_menu = BugMenu:new({
						row = result_menu_row,
						col = result_menu_col,
						width = result_menu_width,
						height = result_menu_height,
						lines = list,
						index = 1,
					})
				end
			end)
		end)
	)
end

local function open_selection()
	if result_menu == nil then
		return
	end
	local index = result_menu.index
	close()
	api.nvim_set_current_win(prev_win)
	config.onselect(index)
end

local function register_events()
	group_id = api.nvim_create_augroup("BugSearch", {})
	api.nvim_create_autocmd({ "TextChangedI" }, {
		group = group_id,
		buffer = prompt_buf,
		callback = function()
			process()
		end,
	})

	vim.keymap.set({ "i" }, "<Tab>", function()
		if result_menu ~= nil then
			result_menu:next()
		end
	end, { buffer = prompt_buf, noremap = true })

	vim.keymap.set({ "i" }, "<S-Tab>", function()
		if result_menu ~= nil then
			result_menu:prev()
		end
	end, { buffer = prompt_buf, noremap = true })

	vim.keymap.set({ "i", "n" }, "<Esc>", function()
		close()
	end, { buffer = prompt_buf, noremap = true })

	vim.keymap.set("i", "<CR>", function()
		open_selection()
	end, { buffer = prompt_buf, noremap = true })
end

function M.search(cfg)
	if vim.tbl_contains(api.nvim_list_wins(), prompt_win) then
		return
	end
	config = cfg
	prev_win = api.nvim_get_current_win()
	local vim_width = vim.o.columns
	local vim_height = vim.o.lines
	win_width = math.min(win_max_width, vim_width)
	win_height = math.min(win_max_height, vim_height)
	local win_top = (vim_height - win_height) / 2
	local win_left = (vim_width - win_width) / 2

	result_menu_row = win_top + prompt_height
	result_menu_col = win_left
	result_menu_width = win_width
	result_menu_height = win_height - prompt_height

	prompt_buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_option(prompt_buf, "buftype", "prompt")
	fn.prompt_setprompt(prompt_buf, " " .. config.title .. " > ")
	prompt_win = api.nvim_open_win(prompt_buf, true, {
		relative = "editor",
		row = win_top,
		col = win_left,
		width = win_width,
		height = prompt_height,
		style = "minimal",
	})

	vim.cmd("startinsert")

	register_events()
end

return M

