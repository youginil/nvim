local api = vim.api

local M = {}

local SymbolKind = {
	[1] = { name = "File", icon = "" },
	[2] = { name = "Module", icon = "" },
	[3] = { name = "Namespace", icon = "" },
	[4] = { name = "Package", icon = "" },
	[5] = { name = "Class", icon = "" },
	[6] = { name = "Method", icon = "" },
	[7] = { name = "Property", icon = "" },
	[8] = { name = "Field", icon = "" },
	[9] = { name = "Constructor", icon = "" },
	[10] = { name = "Enum", icon = "" },
	[11] = { name = "Interface", icon = "" },
	[12] = { name = "Function", icon = "" },
	[13] = { name = "Variable", icon = "" },
	[14] = { name = "Constant", icon = "" },
	[15] = { name = "String", icon = "" },
	[16] = { name = "Number", icon = "" },
	[17] = { name = "Boolean", icon = "" },
	[18] = { name = "Array", icon = "" },
	[19] = { name = "Object", icon = "" },
	[20] = { name = "Key", icon = "" },
	[21] = { name = "Null", icon = "" },
	[22] = { name = "EnumMember", icon = "" },
	[23] = { name = "Struct", icon = "" },
	[24] = { name = "Event", icon = "" },
	[25] = { name = "Operator", icon = "" },
	[26] = { name = "TypeParameter", icon = "" },
}

local flag = 0
local function update(client, bufnr)
	local this_flag = flag
	if client.is_stopped() then
		return
	end
	client.request(
		"textDocument/documentSymbol",
		{ textDocument = vim.lsp.util.make_text_document_params() },
		function(err, symbols)
			if err ~= nil or this_flag ~= flag then
				return
			end
			--             bug.debug(symbols)
			if symbols == nil or #symbols == 0 then
				return
			end
			-- SymbolInformation is deprecated
			if symbols[1].location ~= nil then
				bug.warn("Deprecated symbol format")
				return
			end
			local components = { { name = vim.fn.expand("%:t"), icon = "" } }
			local _, cur_row, cur_col = unpack(vim.fn.getcurpos())
			cur_row = cur_row - 1
			cur_col = cur_col - 1
			while true do
				local matched = false
				for _, v in ipairs(symbols) do
					local r = v.range
					if r.start.line == r["end"].line then
						if cur_row == r.start.line then
							if cur_col >= r.start.character and cur_col <= r["end"].character then
								matched = true
							end
						end
					else
						if
							(cur_row == r.start.line and cur_col >= r.start.character)
							or (cur_row > r.start.line and cur_row < r["end"].line)
							or (cur_row == r["end"].line and cur_col <= r["end"].character)
						then
							matched = true
						end
					end
					if matched then
						table.insert(components, { name = v.name, icon = SymbolKind[v.kind].icon })
						symbols = v.children or {}
						break
					end
				end
				if not matched then
					break
				end
			end
			local bar_coms = {}
			for _, v in ipairs(components) do
				table.insert(bar_coms, " " .. v.icon .. v.name .. " ")
			end
			local wins = api.nvim_list_wins()
			for _, win in ipairs(wins) do
				local buf = api.nvim_win_get_buf(win)
				if buf == bufnr then
					api.nvim_win_set_option(win, "winbar", table.concat(bar_coms, ">"))
					break
				end
			end
		end,
		bufnr
	)
end

function M.attach(client, bufnr)
	local gid = api.nvim_create_augroup("BugWinbar", {})
	api.nvim_clear_autocmds({ buffer = bufnr, group = gid })

	local timer = nil
	api.nvim_create_autocmd({ "CursorMoved" }, {
		group = gid,
		buffer = bufnr,
		callback = function()
			flag = flag + 1
			if timer ~= nil then
				timer:stop()
			end
			timer = vim.loop.new_timer()
			timer:start(
				400,
				0,
				vim.schedule_wrap(function()
					timer = nil
					update(client, bufnr)
				end)
			)
		end,
	})

	api.nvim_create_autocmd({ "BufLeave" }, {
		group = gid,
		buffer = bufnr,
		callback = function()
			flag = flag + 1
		end,
	})

	update(client, bufnr)
end

return M
