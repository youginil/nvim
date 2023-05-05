local api = vim.api
local fn = vim.fn

local M = {}

local config = {
	log_level = "warn",
}

function M.tbl_index_of(list, element)
	if not vim.tbl_islist(list) then
		error("Parameter is not a LIST", 2)
		return -1
	end
	for i, v in ipairs(list) do
		if v == element then
			return i
		end
	end
	return -1
end

function M.tbl_slice(list, start_index, end_index)
	if type(end_index) ~= "number" then
		end_index = #list
	elseif end_index < 0 then
		end_index = #list + end_index + 1
	end
	end_index = math.min(#list, end_index)
	start_index = math.max(1, start_index)
	local result = {}
	if start_index <= end_index then
		for i = start_index, end_index do
			table.insert(result, list[i])
		end
	end
	return result
end

function M.tbl_find(t, value)
	for k, v in pairs(t) do
		if v == value then
			return k, v
		end
	end
end

function M.feedkeys(keys, mode)
	api.nvim_feedkeys(api.nvim_replace_termcodes(keys, true, false, true), mode, false)
end

local logfile = io.open(fn.stdpath("config") .. "/debug.log", "a+")

local LogLevels = {
	["debug"] = 0,
	["info"] = 1,
	["warn"] = 2,
	["error"] = 3,
}

local function log(tp, ...)
	if LogLevels[tp] < LogLevels[config.log_level] or logfile == nil then
		return
	end
	local msg = ""
	for _, v in ipairs({ ... }) do
		msg = msg .. " " .. (type(v) == "table" and vim.inspect(v) or string.format("%s", v))
	end
	local time = os.date("%Y-%m-%d %H:%M:%S")
	local trace = debug.traceback()
	local stack = type(trace) == "string" and vim.split(debug.traceback(), "\n") or trace
	stack = M.tbl_slice(stack, 4, 4)
	for i, v in ipairs(stack) do
		stack[i] = vim.trim(v)
	end
	local str = string.format("%s [%s] %s\n%s\n", time, tp, msg, "\27[37m" .. table.concat(stack, "\n") .. "\27[0m")
	logfile:write(str)
	logfile:flush()
end

function M.debug(...)
	log("debug", ...)
end

function M.info(...)
	log("info", ...)
end

function M.warn(...)
	log("warn", ...)
end

function M.error(...)
	log("error", ...)
end

function M.gn()
	local stack = fn.synstack(fn.line("."), fn.col("."))
	local result = fn.synIDattr(stack[1], "name")
	print(vim.inspect(result))
end

function M.setup(opt)
	if type(opt) == "table" then
		config = vim.tbl_deep_extend("force", config, opt)
	end
	if LogLevels[config.log_level] == nil then
		M.error("Invalid log_level", config.log_level)
		config.log_level = "error"
	end
	return M
end

return M

