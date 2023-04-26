local api = vim.api
local fn = vim.fn
local lsp = vim.lsp
local keymap = vim.keymap
local levels = vim.log.levels

local M = {}

local SymbolKind = {
	[1] = { name = "File", icon = "❤" },
	[2] = { name = "Module", icon = "➑" },
	[3] = { name = "Namespace", icon = "➑" },
	[4] = { name = "Package", icon = "➑" },
	[5] = { name = "Class", icon = "©" },
	[6] = { name = "Method", icon = "⇅" },
	[7] = { name = "Property", icon = "➤" },
	[8] = { name = "Field", icon = "➤" },
	[9] = { name = "Constructor", icon = "⇅" },
	[10] = { name = "Enum", icon = "✣" },
	[11] = { name = "Interface", icon = "♂" },
	[12] = { name = "Function", icon = "⇅" },
	[13] = { name = "Variable", icon = "►" },
	[14] = { name = "Constant", icon = "▷" },
	[15] = { name = "String", icon = "✍" },
	[16] = { name = "Number", icon = "¾" },
	[17] = { name = "Boolean", icon = "◑" },
	[18] = { name = "Array", icon = "∞" },
	[19] = { name = "Object", icon = "○" },
	[20] = { name = "Key", icon = "»" },
	[21] = { name = "Null", icon = "⊗" },
	[22] = { name = "EnumMember", icon = "➔" },
	[23] = { name = "Struct", icon = "©" },
	[24] = { name = "Event", icon = "✈" },
	[25] = { name = "Operator", icon = "±" },
	[26] = { name = "TypeParameter", icon = "▼" },
}

local kinds_nochildren = { 6, 9, 12, 18 }

-- {{line = 1, character = 1}}
local symbol_positions = {}

local function make_line(symbol, indent)
	local cfg = SymbolKind[symbol.kind]
	local icon = cfg.icon
	table.insert(symbol_positions, symbol.range.start)
	return " " .. string.rep("\t", indent) .. icon .. " " .. symbol.name .. (symbol.deprecated and "✘" or "")
end

local function sort_symbols(symbols)
	table.sort(symbols, function(a, b)
		local pa = a.range.start
		local pb = b.range.start
		if pa.line == pb.line then
			return pa.character < pb.character
		end
		return pa.line < pb.line
	end)
end

local function make_lines(symbol, indent)
	local lines = { make_line(symbol, indent) }
	if symbol.children and #symbol.children > 0 and (not vim.tbl_contains(kinds_nochildren, symbol.kind)) then
		sort_symbols(symbol.children)
		for _, v in ipairs(symbol.children) do
			local child_lines = make_lines(v, indent + 1)
			for _, line in ipairs(child_lines) do
				table.insert(lines, line)
			end
		end
	end
	return lines
end

local client = nil
local req = nil
function M.show()
	if client then
		client.cancel_request(req)
		client = nil
		req = nil
	end
	local bufnr = api.nvim_get_current_buf()
	local clients = lsp.get_active_clients({
		bufnr,
	})
	client = clients[1]
	if #clients == 0 then
		vim.notify("No LSP client", levels.INFO, {})
		return
	end
	req = client.request(
		"textDocument/documentSymbol",
		{ textDocument = vim.lsp.util.make_text_document_params() },
		function(err, symbols)
			client = nil
			req = nil
			if err then
				vim.notify(err, levels.ERROR, {})
				return
			end
			-- 			bug.debug(symbols)
			if symbols == nil or #symbols == 0 then
				return
			end
			-- SymbolInformation is deprecated
			if symbols[1].location ~= nil then
				vim.notify("Deprecated symbol format", levels.WARN, {})
				return
			end
			symbol_positions = {}
			local lines = {}
			sort_symbols(symbols)
			for _, v in ipairs(symbols) do
				local item_lines = make_lines(v, 0)
				for _, line in ipairs(item_lines) do
					table.insert(lines, line)
				end
			end
			if #lines > 0 then
				local buf = api.nvim_create_buf(false, true)
				local vim_width = vim.o.columns
				local vim_height = vim.o.lines
				local top = 5
				local left = vim_width / 4
				api.nvim_open_win(buf, true, {
					relative = "editor",
					width = vim_width / 2,
					height = vim_height - top * 2,
					row = top,
					col = left,
					style = "minimal",
					noautocmd = true,
				})
				api.nvim_buf_set_lines(buf, 0, #lines, false, lines)

				keymap.set({ "n", "i" }, "q", function()
					api.nvim_buf_delete(buf, { force = true })
				end, { buffer = buf, noremap = true })

				keymap.set({ "n", "i" }, "<Esc>", function()
					api.nvim_buf_delete(buf, { force = true })
				end, { buffer = buf, noremap = true })

				keymap.set({ "n" }, "<CR>", function()
					local _, lnum = unpack(fn.getcurpos())
					if #symbol_positions >= lnum then
						local pos = symbol_positions[lnum]
						api.nvim_buf_delete(buf, { force = true })
						fn.cursor(pos.line + 1, pos.character + 1)
					end
				end, { buffer = buf, noremap = true })
			end
		end,
		bufnr
	)
end

return M

