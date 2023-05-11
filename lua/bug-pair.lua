local fn = vim.fn

local bug = require("bug")

local M = {}

local char_pairs = {
	["("] = ")",
	["["] = "]",
	["{"] = "}",
	["'"] = "'",
	['"'] = '"',
	["`"] = "`",
}

local QuotePairs = { "'", '"', "`" }
local BracketPairs = { "(", "[", "{" }

local default_config = {
	before_insert_pair = function()
		return true
	end,
}

local config = default_config

local function divide_line()
	local pos = fn.getpos(".")
	local row = pos[2]
	local col = pos[3]
	local line = fn.getline(row)
	local l = string.sub(line, 1, col - 1)
	local r = string.sub(line, col)
	return l, r
end

local function in_blank_brackets()
	local lstr, rstr = divide_line()
	for _, char in ipairs(BracketPairs) do
		local s1 = string.gmatch(lstr, "%" .. char .. "(%s*)$")()
		if s1 ~= nil then
			local s2 = string.gmatch(rstr, "(%s*)" .. "%" .. char_pairs[char] .. ".*$")()
			if s2 ~= nil then
				return true, s1, s2, char
			end
		end
	end
	return false
end

local function single_count(str, char, another, order)
	local c = 0
	local same = char == another
	local st = order == 1 and 1 or #str
	local ed = order == 1 and #str or 1
	local de = order == 1 and 1 or -1
	for i = st, ed, de do
		local s = string.sub(str, i, i)
		if same then
			if s == char then
				c = c == 1 and 0 or 1
			end
		elseif s == char then
			c = c + 1
		elseif s == another then
			c = math.max(0, c - 1)
		end
	end
	return c
end

local function in_quotes(l, r)
	for _, char in ipairs(QuotePairs) do
		local lc = single_count(l, char, char, 1)
		if lc == 1 then
			local rc = single_count(r, char, char, -1)
			if rc == 1 then
				return true
			end
		end
	end
	return false
end

function M.handle_pair(char)
	if not vim.bo.buflisted then
		bug.feedkeys(char, "n")
		return
	end
	bug.info("Handle Pair")
	local right_char = char_pairs[char]
	local l, r = divide_line()
	if in_quotes(l, r) then
		bug.feedkeys(char, "n")
		return
	end
	local lc = single_count(l, char, right_char, 1)
	local rc = single_count(r, right_char, char, -1)
	if lc >= rc or rc == 0 then
		if config.before_insert_pair() == true then
			bug.feedkeys(char .. right_char .. "<Left>", "n")
		else
			bug.feedkeys(char, "n")
		end
	else
		bug.feedkeys(char, "n")
	end
end

function M.handle_enter()
	bug.info("Handle Enter")
	local y = in_blank_brackets()
	if y then
		bug.feedkeys("<CR><Esc>O", "n")
		return true
	end
	return false
end

function M.handle_backspace()
	bug.info("Handle Backspace")
	local l, r = divide_line()
	if #l > 0 and #r > 0 then
		local lchar = string.sub(l, #l, #l)
		local rchar = string.sub(r, 1, 1)
		if char_pairs[lchar] ~= nil and char_pairs[lchar] == rchar then
			l = string.sub(l, 1, #l - 1)
			r = string.sub(r, 2, #r)
			local lc = single_count(l, lchar, rchar, 1)
			local rc = single_count(r, rchar, lchar, -1)
			if not in_quotes(l, r) and lc <= rc then
				bug.feedkeys("<BS><Right><BS>", "n")
				return true
			end
		end
	end
	return false
end

function M.setup(opt)
	if type(opt) ~= "table" then
		opt = {}
	end
	config = vim.tbl_deep_extend("force", default_config, opt)
	return M
end

for char, _ in pairs(char_pairs) do
	vim.keymap.set("i", char, function()
		M.handle_pair(char)
	end, { noremap = true })
end

return M

