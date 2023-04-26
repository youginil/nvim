local M = {}

local api = vim.api
local fn = vim.fn

local CommentSymbols = {
	javascript = "//",
	json = "//",
	lua = "--",
	rust = "//",
	typescript = "//",
	typescriptreact = "//",
	yaml = "#",
	python = "#",
}

local function escape_lua_symbol(symbol)
	return string.gsub(symbol, "([%-])", "%%%1")
end

local function escape_vim_symbol(symbol)
	return string.gsub(symbol, "([%-/])", "\\%1")
end

function M.toggle_comment()
	local symbol = CommentSymbols[vim.bo.filetype]
	if symbol == nil then
		return
	end
	local mode = api.nvim_get_mode()["mode"]
	local sl, el, line
	local matched = true
	if mode == "n" then
		sl = fn.getpos(".")[2]
		el = sl
		line = fn.getline(".")
	elseif mode == "v" or mode == "V" then
		sl = fn.getpos(".")[2]
		el = fn.getpos("v")[2]
		if sl > el then
			sl, el = el, sl
			line = fn.getline("v")
		else
			line = fn.getline(".")
		end
	else
		matched = false
	end
	if matched then
		local lua_symbol = escape_lua_symbol(symbol)
		local vim_symbol = escape_vim_symbol(symbol)
		local reg = string.match(line, "^%s*" .. lua_symbol) and "s/^\\(\\s*\\)" .. vim_symbol .. "\\s\\?/\\1/"
			or "s/^/" .. vim_symbol .. " /"
		local cmd = sl .. "," .. el .. reg
		vim.cmd(cmd)
		api.nvim_input("<Esc>")
		api.nvim_command("noh")
	end
end

return M

