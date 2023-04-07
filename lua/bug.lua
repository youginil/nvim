local api = vim.api
local fn = vim.fn

local M = {}

local log_file = io.open(fn.stdpath("config") .. "/debug.log", "a+")

local events = {
	-- 	"BufRead",
	-- 	"BufNewFile",
	-- 	"BufReadPre",
	-- 	"BufReadPost",
	-- 	"FilterReadPre",
	-- 	"FilterReadPost",
	-- 	"FileReadPre",
	-- 	"FileReadPost",
	-- 	"BufAdd",
	-- 	"BufEnter",
	-- 	"BufDelete",
	-- 	"BufUnload",
	-- 	"BufFilePost",
	-- 	"BufFilePre",
	-- 	"BufHidden",
	-- 	"BufLeave",
	-- 	"BufModifiedSet",
	-- 	"BufNew",
	-- 	"BufWinEnter",
	-- 	"BufReadCmd",
	-- 	"BufWritePost",
	-- 	"BufWinLeave",
	-- 	"BufWipeout",
	-- 	"BufWrite",
	-- 	"BufWritePre",
	-- 	"BufWriteCmd",
	-- 	"ChanInfo",
	-- 	"ChanOpen",
	-- 	"CmdUndefined",
	-- 	"CmdlineChanged",
	-- 	"CmdlineEnter",
	-- 	"CmdlineLeave",
	-- 	"CmdwinEnter",
	-- 	"CmdwinLeave",
	-- 	"ColorScheme",
	-- 	"ColorSchemePre",
	-- 	"CompleteChanged",
	-- 	"CompleteDonePre",
	-- 	"CompleteDone",
	-- 	"CursorHold",
	-- 	"CursorHoldI",
	-- 	"CursorMoved",
	-- 	"CursorMovedI",
	-- 	"DiffUpdated",
	-- 	"DirChanged",
	-- 	"FileAppendCmd",
	-- 	"FileAppendPost",
	-- 	"FileAppendPre",
	-- 	"FileChangedRO",
	-- 	"ExitPre",
	-- 	"QuitPre",
	-- 	"VimLeavePre",
	-- 	"WinClosed",
	-- 	"FileChangedShell",
	-- 	"FocusGained",
	-- 	"FileChangedShellPost",
	-- 	"FileReadCmd",
	-- 	"FileType",
	-- 	"FileWriteCmd",
	-- 	"filewritepost",
	-- 	"filewritepre",
	-- 	"filterwritepost",
	-- 	"filterwritepre",
	-- 	"focuslost",
	-- 	"funcundefined",
	-- 	"uienter",
	-- 	"vimenter",
	-- 	"uileave",
	-- 	"insertchange",
	-- 	"insertcharpre",
	-- 	"insertenter",
	-- 	"insertleavepre",
	-- 	"insertleave",
	-- 	"menupopup",
	-- 	"optionset",
	-- 	"quickfixcmdpre",
	-- 	"quickfixcmdpost",
	-- 	"remotereply",
	-- 	"sessionloadpost",
	-- 	"shellcmdpost",
	-- 	"signal",
	-- 	"shellfilterpost",
	-- 	"sourcepre",
	-- 	"sourcepost",
	-- 	"sourcecmd",
	-- 	"spellfilemissing",
	-- 	"stdinreadpost",
	-- 	"stdinreadpre",
	-- 	"swapexists",
	-- 	"syntax",
	-- 	"tabenter",
	-- 	"winenter",
	-- 	"tableave",
	-- 	"winleave",
	-- 	"tabnew",
	-- 	"tabnewentered",
	-- 	"tabclosed",
	-- 	"termopen",
	-- 	"termenter",
	-- 	"termleave",
	-- 	"termclose",
	-- 	"termresponse",
	-- 	"textchanged",
	-- 	"textchangedi",
	-- 	"textchangedp",
	-- 	"textyankpost",
	-- 	"user",
	-- 	"vimleave",
	-- 	"vimresized",
	-- 	"vimresume",
	-- 	"vimsuspend",
	-- 	"winnew",
	-- 	"winscrolled",
}

local _ = {
	"ModeChanged",
	"SearchWrapped",
	"RecordingEnter",
	"RecordingLeave",
	"FileExplorer",
	"UserGettingBored",
}

local LogLevels = {
	["debug"] = 0,
	["info"] = 1,
	["warn"] = 2,
	["error"] = 3,
}

local log_level = 0

local function log(tp, ...)
	if LogLevels[tp] < log_level then
		return
	end
	local msg = ""
	for _, v in ipairs({ ... }) do
		msg = msg .. " " .. (type(v) == "table" and vim.inspect(v) or string.format("%s", v))
	end
	local time = os.date("%Y-%m-%d %H:%M:%S")
	local trace = debug.traceback()
	local stack = type(trace) == "string" and vim.split(debug.traceback(), "\n") or trace
	stack = table.slice(stack, 4, 4)
	for i, v in ipairs(stack) do
		stack[i] = vim.trim(v)
	end
	local str = string.format("%s [%s] %s\n%s\n", time, tp, msg, "\27[37m" .. table.concat(stack, "\n") .. "\27[0m")
	log_file:write(str)
	log_file:flush()
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
	opt = type(opt) == "table" and opt or {}
	if type(opt.log_level) == "number" then
		log_level = opt.log_level
	end
end

local gid = api.nvim_create_augroup("BugDebug", {})
for _, evt in ipairs(events) do
	api.nvim_create_autocmd(evt, {
		group = gid,
		callback = function()
			M.debug(evt)
		end,
	})
end

bug = M

return M
