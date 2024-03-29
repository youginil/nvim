local api = vim.api
local fn = vim.fn
local lsp = vim.lsp
local uv = vim.loop

local BugMenu = require("bug-menu")
local bug = require("bug")

local highlights = {
	BugCmpNormal = "NormalFloat",
	BugCmpPlaceholder = "Visual",
	BugCmpDeprecated = "ErrorMsg",
	BugCmpFloatBorder = "NormalFloat",
}

for grp1, grp2 in pairs(highlights) do
	if fn.hlexists(grp1) == 0 then
		api.nvim_set_hl(0, grp1, { link = grp2 })
	end
end

local CompletionTriggerKind = {
	Invoked = 1,
	TriggerCharacter = 2,
	TriggerForIncompleteCompletions = 3,
}

local CompletionItemKind = {
	{ "❞" }, -- "Text"
	{ "⥯" }, -- "Method"
	{ "⇅" }, -- "Function"
	{ "⇕" }, -- "Constructor"
	{ "➝" }, -- "Field"
	{ "◇" }, -- "Variable"
	{ "©" }, -- "Class"
	{ "𝖎" }, -- "Interface"
	{ "✤" }, -- "Module"
	{ "➤" }, -- "Property"
	{ "Ω" }, -- "Unit"
	{ "◉" }, -- "Value"
	{ "◕" }, -- "Enum"
	{ "⊙" }, -- "Keyword"
	{ "⅍" }, -- "Snippet"
	{ "♠" }, -- "Color"
	{ "⌘" }, -- "File"
	{ "&" }, -- "Reference"
	{ "♪" }, -- "Folder"
	{ "◔" }, -- "EnumMember"
	{ "◆" }, -- "Constant"
	{ "❖" }, -- "Struct"
	{ "ė" }, -- "Event"
	{ "÷" }, -- "Operator"
	{ "τ" }, -- "TypeParameter"
}
for _, item in ipairs(CompletionItemKind) do
	table.insert(item, fn.strdisplaywidth(item[1]))
end

local InsertTextFormat = {
	PlainText = 1,
	Snippet = 2,
}

local MarkupKind = {
	PlainText = "plaintext",
	Markdown = "markdown",
}

local CompletionItemTag = {
	Deprecated = 1,
}

-- TODO more variables at https://code.visualstudio.com/docs/editor/userdefinedsnippets
local snip_vars = {
	["TM_SELECTED_TEXT"] = function()
		return ""
	end,
	["TM_CURRENT_LINE"] = function()
		return api.nvim_get_current_line()
	end,
	["TM_CURRENT_WORD"] = function()
		return fn.expand("<cword>")
	end,
	["TM_LINE_INDEX"] = function()
		return "" .. (fn.getcurpos()[2] - 1)
	end,
	["TM_LINE_NUMBER"] = function()
		return "" .. fn.getcurpos()[2]
	end,
	["TM_FILENAME"] = function()
		return fn.expand("%:t")
	end,
	["TM_FILENAME_BASE"] = function()
		return fn.expand("%:t:r")
	end,
	["TM_DIRECTORY"] = function()
		local p = fn.expand("%:p")
		return fn.fnamemodify(p, ":h")
	end,
	["TM_FILEPATH"] = function()
		return fn.expand("%:p")
	end,
}

-- {[bufnr] = [group_id]}
local groups = {}
local group_flag = 1

local function group_exists(bufnr)
	if bufnr == nil then
		bufnr = api.nvim_get_current_buf()
	end
	return groups[tostring(bufnr)] ~= nil
end

local lsp_manager = {
	client = nil,
	trigger_chars = {},
	req_ids = {},
}

function lsp_manager:client_available()
	if self.client ~= nil and vim.lsp.client_is_stopped(self.client.id) then
		self.req_ids = {}
		self.client = nil
	end
	local buf = api.nvim_get_current_buf()
	if self.client ~= nil then
		local buffers = vim.lsp.get_buffers_by_client_id(self.client.id)
		if not vim.tbl_contains(buffers, buf) then
			self.client = nil
			self.req_ids = {}
		end
	end
	if self.client == nil then
		for _, client in ipairs(vim.lsp.get_active_clients()) do
			local buffers = vim.lsp.get_buffers_by_client_id(client.id)
			if vim.tbl_contains(buffers, buf) then
				self.client = client
				if client.server_capabilities.completionProvider then
					self.trigger_chars = client.server_capabilities.completionProvider.triggerCharacters or {}
				end
				break
			end
		end
	end
	return self.client ~= nil
end

function lsp_manager:request(method, params, callback)
	if self.req_ids[method] ~= nil then
		self.client.cancel_request(self.req_ids[method])
		self.req_ids[method] = nil
	end
	local req_id
	_, req_id = self.client.request(method, params, function(err, result)
		if req_id ~= self.req_ids[method] then
			return
		end
		self.req_ids[method] = nil
		if err ~= nil then
			return
		end
		callback(result)
	end)
	self.req_ids[method] = req_id
end

function lsp_manager:complete(triggerKind, triggerCharacter, cb)
	bug.info("LSP completion")
	if not self:client_available() then
		return
	end
	local params = vim.lsp.util.make_position_params(0, self.client.offset_encoding)
	params.context = {
		triggerKind = triggerKind,
		triggerCharacter = triggerCharacter,
	}
	self:request("textDocument/completion", params, function(result)
		cb(result)
	end)
end

function lsp_manager:resolve(item, cb)
	bug.info("LSP resolve")
	if not self:client_available() then
		return
	end
	self:request("completionItem/resolve", item, function(result)
		cb(result)
	end)
end

local cmp_cursor = nil
local cmp_result = {}
local cmp_menu = nil
local cmp_win_w = 0
local cmp_win_h = 0
local cmp_win_t = 0
local cmp_win_l = 0
local cmp_doc_flag = 0
local cmp_doc_win = nil
local cmp_doc_buf = nil
local cmp_placeholder_ns = api.nvim_create_namespace("BugCmp")
local cmp_group_id = api.nvim_create_augroup("BugCmp", { clear = true })
-- {id: number; pid: number}
local cmp_placeholders = {}
local inserting_cmp_text = false

local function clear_placeholders()
	for _, m in ipairs(cmp_placeholders) do
		local mpos = api.nvim_buf_get_extmark_by_id(0, cmp_placeholder_ns, m.id, { details = true })
		if vim.tbl_isempty(mpos) then
			bug.warn("Placeholder should not be empty")
		else
			local sr = mpos[1]
			local sc = mpos[2]
			local er = mpos[3].end_row
			local ec = mpos[3].end_col
			if sr == er and sc + 1 == ec and api.nvim_buf_get_text(0, sr, sc, er, ec, {})[1] == " " then
				api.nvim_buf_set_text(0, sr, sc, er, ec, { "" })
			end
		end
		api.nvim_buf_del_extmark(0, cmp_placeholder_ns, m.id)
	end
	cmp_placeholders = {}
end

local function close_doc_win()
	if cmp_doc_win ~= nil then
		api.nvim_win_close(cmp_doc_win, true)
		cmp_doc_win = nil
		api.nvim_buf_delete(cmp_doc_buf, { force = true })
		cmp_doc_buf = nil
	end
end

local function close()
	bug.info("Close")
	cmp_result = {}
	if cmp_menu ~= nil then
		cmp_menu:close()
		cmp_menu = nil
	end
	close_doc_win()
	cmp_doc_flag = 0
end

local function open_doc_win(item)
	local doc = ""
	local stylized = false
	if item.documentation ~= nil then
		if type(item.documentation) == "string" then
			doc = item.documentation
		else
			doc = item.documentation.value
			if item.documentation.kind == MarkupKind.Markdown then
				stylized = true
			end
		end
	end
	if doc == "" or doc == nil then
		return
	end
	local lines = {}
	for _, l in ipairs(vim.split(doc, "\n")) do
		table.insert(lines, l)
	end
	local vim_width = vim.o.columns
	local vim_height = vim.o.lines
	local r_gap = vim_width - cmp_win_w - cmp_win_l
	local l_gap = cmp_win_l
	local is_right = r_gap >= l_gap
	local max_gap = is_right and r_gap or l_gap
	local max_width = max_gap - 2
	cmp_doc_buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_lines(cmp_doc_buf, 0, -1, false, {})
	local new_lines = stylized
			and lsp.util.stylize_markdown(cmp_doc_buf, lines, { max_width = max_width, max_height = vim_height })
		or lines
	local doc_height = #new_lines
	local doc_width = max_width
	local max_doc_width = 0
	for _, line in ipairs(new_lines) do
		local l = fn.strdisplaywidth(line)
		if l > max_doc_width then
			max_doc_width = l
			if max_doc_width > max_width then
				doc_height = doc_height + math.ceil(l / max_width) - 1
			end
		end
	end
	if max_doc_width < doc_width then
		doc_width = max_doc_width
	end
	cmp_doc_win = api.nvim_open_win(cmp_doc_buf, false, {
		relative = "editor",
		width = doc_width,
		height = doc_height,
		row = cmp_win_t - math.max(0, doc_height - (vim_height - cmp_win_t)),
		col = is_right and (cmp_win_l + cmp_win_w) or (cmp_win_l - doc_width - 2),
		style = "minimal",
		border = { "", "", "", " ", "", "", "", " " },
		noautocmd = true,
	})
	api.nvim_set_option_value("winhl", "Normal:BugCmpNormal,FloatBorder:BugCmpFloatBorder", { win = cmp_doc_win })
end

local function open_win()
	bug.info("Open result window")
	if cmp_menu ~= nil or #cmp_result == 0 then
		return
	end
	cmp_win_w = 0
	local gap_size = fn.strdisplaywidth(" ") * 3
	for _, item in ipairs(cmp_result) do
		local w = nil
		local kd = nil
		for i, v in ipairs(CompletionItemKind) do
			if i == item.kind then
				w = fn.strdisplaywidth(item.label) + v[2] + gap_size
				kd = v
			end
		end
		if w == nil then
			w = fn.strdisplaywidth(item.label) + gap_size
		end
		item._kind = kd
		if w > cmp_win_w then
			cmp_win_w = w
		end
	end
	local vim_width = vim.o.columns
	local vim_height = vim.o.lines
	local wininfo = fn.getwininfo(api.nvim_get_current_win())[1]
	cmp_win_w = math.min(cmp_win_w, math.floor(vim_width * 0.5))
	cmp_win_h = #cmp_result
	local cur_row, cur_col = unpack(cmp_cursor)
	local u_gap = cur_row - wininfo.topline + wininfo.winrow
	-- long lines
	local total_columns = wininfo.width - wininfo.textoff
	for i = wininfo.topline, cur_row - 1 do
		local l = fn.getline(i)
		local c = math.ceil(fn.strdisplaywidth(l) / total_columns)
		if c > 1 then
			u_gap = u_gap + c - 1
		end
	end
	local cur_col_str = string.sub(fn.getline("."), 1, cur_col - 1)
	local cur_col_width = fn.strdisplaywidth(cur_col_str)
	local c = math.floor(cur_col_width / total_columns)
	if c > 1 then
		u_gap = u_gap + c - 1
	end
	local d_gap = vim_height - (u_gap + 1)
	local l_gap = cur_col_width % total_columns + wininfo.textoff + wininfo.wincol - 1
	local r_gap = vim_width - l_gap
	local cmp_below = d_gap >= cmp_win_h or d_gap >= u_gap
	cmp_win_h = math.min(cmp_win_h, cmp_below and d_gap or u_gap - 1)
	cmp_win_t = cmp_below and u_gap or (u_gap - cmp_win_h - 1)
	cmp_win_l = r_gap >= cmp_win_w and l_gap or (l_gap - cmp_win_w)
	local cmp_idx_selected = 1
	if not cmp_below then
		local middle = math.floor(#cmp_result / 2)
		for i = 1, middle do
			cmp_result[i], cmp_result[#cmp_result - i + 1] = cmp_result[#cmp_result - i + 1], cmp_result[i]
		end
		cmp_idx_selected = #cmp_result
	end
	local lines = {}
	for _, item in ipairs(cmp_result) do
		table.insert(lines, item.label)
	end
	local hls = {}
	for i, v in ipairs(cmp_result) do
		if v.deprecated == true or (v.tags ~= nil and vim.tbl_contains(v.tags, CompletionItemTag.Deprecated)) then
			hls[i] = "BugCmpDeprecated"
		end
	end
	cmp_menu = BugMenu:new({
		relative = "editor",
		row = cmp_win_t,
		col = cmp_win_l,
		width = cmp_win_w,
		height = cmp_win_h,
		index = cmp_idx_selected,
		lines = lines,
		hls = hls,
		onselect = function(idx)
			if cmp_doc_flag == 0 then
				cmp_doc_flag = 1
				return
			end
			cmp_doc_flag = cmp_doc_flag + 1
			local doc_flag = cmp_doc_flag
			close_doc_win()
			local current_item = cmp_result[idx]
			if current_item.documentation ~= nil then
				open_doc_win(current_item)
			else
				lsp_manager:resolve(cmp_result[idx], function(item)
					if doc_flag ~= cmp_doc_flag then
						return
					end
					open_doc_win(item)
				end)
			end
		end,
	}, function(label, index, avail_width)
		local item = cmp_result[index]
		local kd = item._kind == nil and { "", 0 } or item._kind
		local max_label_width = avail_width - kd[2] - 1
		while fn.strdisplaywidth(label) > max_label_width do
			label = string.sub(label, 1, #label - 1)
		end
		local space_count = max_label_width - fn.strdisplaywidth(label)
		return label .. string.rep(" ", space_count) .. " " .. kd[1]
	end)
end

local function get_trigger_word()
	local curpos = fn.getcurpos()
	local line = api.nvim_get_current_line()
	local word = ""
	for i = curpos[3] - 1, 1, -1 do
		local char = string.sub(line, i, i)
		if string.find(char, "[0-9a-zA-Z_%-]") == nil then
			break
		else
			word = char .. word
		end
	end
	return word, curpos[2], curpos[3] - #word, curpos[3] - 1
end

local cmp_timer = nil
local cmp_flag = 0

local function complete(kind, char)
	bug.info(string.format("Trigger completion. kind: %d, char: %s", kind, char))
	local cursor = fn.getcurpos()
	cmp_cursor = { cursor[2], cursor[3] }
	if cmp_timer ~= nil then
		cmp_timer:close()
	end
	cmp_flag = cmp_flag + 1
	local current_flag = cmp_flag
	cmp_timer = uv.new_timer()
	cmp_timer:start(
		200,
		0,
		vim.schedule_wrap(function()
			cmp_timer = nil
			lsp_manager:complete(kind, char, function(result)
				bug.info("Process result...")
				if current_flag ~= cmp_flag or result == nil then
					bug.info("Cancel: replaced by another completion")
					return
				end
				if api.nvim_get_mode().mode ~= "i" then
					return
				end
				cursor = fn.getcurpos()
				if cursor[2] ~= cmp_cursor[1] or cursor[3] ~= cmp_cursor[2] then
					bug.info("Cancel: cursor moved.", cmp_cursor, cursor)
					return
				end
				if cmp_result.isIncomplete == true then
					bug.info("Cancel: incomplete")
					return
				end
				-- TODO: handling CompletionList isIncomplete
				cmp_result = result.items == nil and result or result.items
				-- TODO https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/matcher.lua
				local word, cur_row, _, cur_col_end = get_trigger_word()
				if #word > 0 and #cmp_result > 0 then
					bug.info("Filter by trigger word: ", word)
					for i = #cmp_result, 1, -1 do
						local item = cmp_result[i]
						local filter_text = item.filterText == nil and item.label or item.filterText
						local same_with_current = false
						local textEdit = item.textEdit
						if textEdit == nil then
							same_with_current = item.label == word
						else
							local range = textEdit.range == nil and item.textEdit.replace or item.textEdit.range
							same_with_current = textEdit.newText == word
								and range.start.line == cur_row - 1
								and range.start.line == range["end"].line
								and range["end"].character == cur_col_end
								and (range["end"].character - range.start.character == #word)
						end
						if same_with_current or string.find(filter_text, word, 1, true) == nil then
							table.remove(cmp_result, i)
						end
					end
					if #cmp_result == 0 then
						return
					end
				end
				if #cmp_result > 0 and cmp_result[1].sortText ~= nil then
					table.sort(cmp_result, function(a, b)
						local at = a.sortText == nil and "" or a.sortText
						local bt = b.sortText == nil and "" or b.sortText
						return vim.stricmp(at, bt) < 0
					end)
				end
				for i, v in ipairs(cmp_result) do
					if v.preselect == true then
						local item = table.remove(cmp_result, i)
						table.insert(cmp_result, 1, item)
						break
					end
				end
				open_win()
			end)
		end)
	)
end

local function parse_snippet(text)
	-- TODO A trick
	text = string.gsub(text, "\t", string.rep(" ", vim.o.tabstop))
	-- {{line: string, placeholders: {{id: number, range: {number, number}, choice: string[]}} }} 0-based
	local result = {}
	local function add_placeholder(index, id, s, sd, e, ed, choice)
		local item = result[index]
		local l = item.line
		item.line = string.sub(l, 1, s) .. string.sub(l, s + sd + 1, e - ed) .. string.sub(l, e + 1)
		for _, ph in ipairs(item.placeholders) do
			if ph.range[1] >= s then
				ph.range = { ph.range[1] - sd, ph.range[2] - sd }
			end
			if ph.range[1] >= e then
				ph.range = { ph.range[1] - ed, ph.range[2] - ed }
			end
		end
		table.insert(item.placeholders, { id = id, range = { s, e - sd - ed }, choice = choice })
	end

	local function insert_variable(index, s, e, str)
		local item = result[index]
		item.line = string.sub(item.line, 1, s) .. str .. string.sub(item.line, e + 1)
		local d = #str - (e - s)
		for _, ph in item.placeholders do
			if ph.range[1] >= e then
				ph.range = { ph.range[1] + d, ph.range[2] + d }
			end
		end
	end

	local lines = vim.split(text, "\n")
	for index, line in ipairs(lines) do
		result[index] = { line = line, placeholders = {} }
		while true do
			::continue::
			line = result[index].line
			local s, e, expr = string.find(line, "%${([^%$]+)}")
			if s == nil then
				break
			end
			s = s - 1
			-- placeholder
			local v, c = string.gsub(expr, "^%d+%:(.*)$", "%1")
			if c == 1 then
				local id = string.sub(expr, 1, #expr - #v - 1)
				add_placeholder(index, tonumber(id), s, 3 + #id, e, 1, {})
				goto continue
			else
			end
			if string.find(expr, "^%d+$") ~= nil then
				add_placeholder(index, tonumber(expr), s, 2 + #expr, e, 1, {})
				goto continue
			end
			-- choice
			v, c = string.gsub(expr, "^%d+|(.*)|$", "%1")
			if c == 1 then
				local id = string.sub(expr, 1, #expr - #v - 2)
				local choice = vim.split(v, ",")
				add_placeholder(index, tonumber(id), s, 3 + #id, e, 2, choice)
				goto continue
			end
			-- variable
			for k, action in pairs(snip_vars) do
				v, c = string.gsub(expr, string.format("^(%s):(.*)$", k), "%2")
				if c == 1 then
					local value = action()
					if value ~= "" then
						v = value
					end
					insert_variable(index, s, e, v)
					break
				end
			end
		end
		while true do
			::continue::
			line = result[index].line
			local s, e, v
			for k, action in pairs(snip_vars) do
				s, e = string.find(line, "%$" .. k)
				if s ~= nil then
					v = action()
					insert_variable(index, s - 1, e, v)
					goto continue
				end
			end
			if s == nil then
				break
			end
		end
		while true do
			line = result[index].line
			local s, e, expr = string.find(line, "%$(%d+)")
			if s ~= nil then
				add_placeholder(index, tonumber(expr), s - 1, 1 + #expr, e, 0, {})
			else
				break
			end
		end
		local phs = result[index].placeholders
		table.sort(phs, function(a, b)
			if a.id == 0 then
				return false
			elseif b.id == 0 then
				return true
			else
				return a.id < b.id
			end
		end)
	end
	for _, item in ipairs(result) do
		local phs = item.placeholders
		for idx, ph in ipairs(phs) do
			local sc = ph.range[1]
			local ec = ph.range[2]
			if sc == ec then
				local s1 = string.sub(item.line, 1, sc)
				local s2 = string.sub(item.line, sc + 1)
				item.line = s1 .. " " .. s2
				ph.range[2] = ec + 1
				if idx < #phs then
					for i = idx + 1, #phs do
						local range = phs[i].range
						range[1] = range[1] + 1
						range[2] = range[2] + 1
					end
				end
			end
		end
	end
	return result
end

local function del_placeholder(id)
	for i, m in ipairs(cmp_placeholders) do
		if m.id == id then
			local mpos = api.nvim_buf_get_extmark_by_id(0, cmp_placeholder_ns, m.id, { details = true })
			if vim.tbl_isempty(mpos) then
				bug.warn("Placeholder should not be empty")
			else
				local sr = mpos[1]
				local sc = mpos[2]
				local er = mpos[3].end_row
				local ec = mpos[3].end_col
				if sr > er or (sr == er and sc > ec) then
					sr, er = er, sr
					sc, ec = ec, sc
				end
				if sr ~= er then
					local start_line = fn.getline(sr + 1)
					if #start_line > sc then
						api.nvim_buf_set_text(0, sr, sc, sr, #start_line, { "" })
					end
					local next_line = fn.getline(er + 1)
					local fc = string.find(next_line, "[^%s]")
					if fc ~= nil and fc <= ec then
						api.nvim_buf_set_text(0, er, fc - 1, er, ec, { "" })
					end
				elseif sc < ec then
					api.nvim_buf_set_text(0, sr, sc, er, ec, { "" })
				end
				api.nvim_buf_del_extmark(0, cmp_placeholder_ns, m.id)
				table.remove(cmp_placeholders, i)
			end
			return
		end
	end
end

local M = {}

function M.del_placeholder_at_cursor()
	local curpos = fn.getcurpos()
	for _, m in ipairs(cmp_placeholders) do
		local mpos = api.nvim_buf_get_extmark_by_id(0, cmp_placeholder_ns, m.id, { details = true })
		if vim.tbl_isempty(mpos) then
			bug.warn("Placeholder should not be empty")
			goto continue
		end
		local start_col = mpos[2] + 1
		local end_col = mpos[3].end_col + 1
		-- for virt_text
		if start_col > end_col then
			start_col, end_col = end_col, start_col
		end
		if curpos[2] == mpos[1] + 1 and curpos[3] >= start_col and curpos[3] <= end_col then
			del_placeholder(m.id)
			return true
		end
		::continue::
	end
	return false
end

local function on_text_changed()
	bug.info("On TextChanged")
	-- TODO filter by exists result
	close()
	if not group_exists() then
		return
	end
	local mode = api.nvim_get_mode().mode
	if mode ~= "i" then
		return
	end
	if not inserting_cmp_text then
		M.del_placeholder_at_cursor()
	end
	if inserting_cmp_text then
		inserting_cmp_text = false
	end
	local word = get_trigger_word()
	if #word > 0 then
		complete(CompletionTriggerKind.Invoked)
		return
	end
	local curpos = fn.getcurpos()
	local line = api.nvim_get_current_line()
	local text_before_cursor = string.sub(line, 1, curpos[3] - 1)
	local char = string.sub(text_before_cursor, #text_before_cursor)
	if vim.tbl_contains(lsp_manager.trigger_chars, char) then
		if char == " " and string.find(text_before_cursor, "[^%s]") == nil then
			return
		end
		complete(CompletionTriggerKind.TriggerCharacter, char)
		return
	end
end

function M.handle_enter()
	bug.info("On Enter")
	if not group_exists() or cmp_menu == nil then
		return false
	end
	local range
	local text
	local item = cmp_result[cmp_menu.index]
	local is_snippet = item.insertTextFormat == InsertTextFormat.Snippet
	if item.textEdit ~= nil then
		text = item.textEdit.newText
		if item.textEdit.range ~= nil then
			local rg = item.textEdit.range
			range = { rg.start.line, rg.start.character, rg["end"].line, rg["end"].character }
		else
			local insert = item.textEdit.insert
			--              TODO insert or replace, specify by user
			range = { insert.start.line, insert.start.character, insert["end"].line, insert["end"].character }
		end
	else
		text = item.insertText ~= nil and item.insertText or item.label
		local _, row, sc, ec = get_trigger_word()
		range = { row - 1, sc - 1, row - 1, ec }
	end
	local indent = string.gsub(fn.getline(range[1] + 1), "^(%s*)[^%s].*", "%1")
	local lines
	local target_pos
	local snippet_result
	if is_snippet then
		snippet_result = parse_snippet(text)
		lines = vim.tbl_map(function(l)
			return l.line
		end, snippet_result)
		clear_placeholders()
	else
		lines = vim.split(text, "\n")
	end
	for i, line in ipairs(lines) do
		if i > 1 then
			lines[i] = indent .. line
		end
	end
	api.nvim_buf_set_text(0, range[1], range[2], range[3], range[4], lines)
	inserting_cmp_text = true
	if is_snippet then
		for index, l in ipairs(snippet_result) do
			local row = range[1] + index - 1
			for _, ph in ipairs(l.placeholders) do
				local offset = index == 1 and range[2] or #indent
				local start_col = ph.range[1] + offset
				local end_col = ph.range[2] + offset
				local m = api.nvim_buf_set_extmark(0, cmp_placeholder_ns, row, start_col, {
					end_row = row,
					end_col = end_col,
					hl_group = "BugCmpPlaceholder",
				})
				table.insert(cmp_placeholders, { id = m, pid = ph.id })
			end
		end
		if #cmp_placeholders > 0 then
			local mark = api.nvim_buf_get_extmark_by_id(0, cmp_placeholder_ns, cmp_placeholders[1].id, {})
			target_pos = { mark[1] + 1, mark[2] }
		end
	end
	if target_pos == nil then
		target_pos = { range[1] + #lines, range[2] + #lines[#lines] }
	end
	api.nvim_win_set_cursor(0, target_pos)
	close()
	return true
end

function M.handle_tab()
	if not group_exists() then
		return false
	end
	if #cmp_placeholders > 0 then
		close()
		local curpos = fn.getcurpos()
		local next_mark_id = cmp_placeholders[1].id
		if #cmp_placeholders == 1 then
			local mpos = api.nvim_buf_get_extmark_by_id(0, cmp_placeholder_ns, next_mark_id, { details = true })
			if curpos[2] == mpos[1] + 1 and curpos[3] >= mpos[2] + 1 and curpos[3] <= mpos[3].end_col + 1 then
				del_placeholder(next_mark_id)
				return false
			end
		end
		for i, m in ipairs(cmp_placeholders) do
			local mpos = api.nvim_buf_get_extmark_by_id(0, cmp_placeholder_ns, m.id, { details = true })
			if curpos[2] == mpos[1] + 1 and curpos[3] >= mpos[2] + 1 and curpos[3] <= mpos[3].end_col + 1 then
				if i ~= #cmp_placeholders then
					next_mark_id = cmp_placeholders[i + 1].id
					break
				end
			end
		end
		local next_mark = api.nvim_buf_get_extmark_by_id(0, cmp_placeholder_ns, next_mark_id, {})
		fn.cursor({ next_mark[1] + 1, next_mark[2] + 1 })
	elseif cmp_menu ~= nil then
		cmp_menu:next()
	else
		return false
	end
	return true
end

function M.handle_shift_tab()
	if not group_exists() or cmp_menu == nil then
		return false
	end
	cmp_menu:prev()
	return true
end

function M.handle_backspace()
	if not group_exists() then
		return false
	end
	return M.del_placeholder_at_cursor()
end

function M.handle_up()
	if not group_exists() or cmp_menu == nil then
		return false
	end
	cmp_menu:prev()
	return true
end

function M.handle_down()
	if not group_exists() or cmp_menu == nil then
		return false
	end
	cmp_menu:next()
	return true
end

api.nvim_create_autocmd("LspAttach", {
	group = cmp_group_id,
	callback = function(args)
		local bufnr = args.buf

		if group_exists(bufnr) then
			return
		end

		local gid = api.nvim_create_augroup("BugCmp-" .. group_flag, { clear = true })
		group_flag = group_flag + 1
		groups[tostring(bufnr)] = gid

		api.nvim_create_autocmd({ "TextChangedI" }, {
			group = gid,
			callback = function()
				on_text_changed()
			end,
		})

		api.nvim_create_autocmd("InsertLeave", {
			group = gid,
			callback = function()
				bug.info("On InterLeave")
				close()
				clear_placeholders()
			end,
		})
	end,
})

api.nvim_create_autocmd("LspDetach", {
	group = cmp_group_id,
	callback = function(args)
		local bufnr = args.buf
		api.nvim_del_augroup_by_id(groups[tostring(bufnr)])
		groups[tostring(bufnr)] = nil
	end,
})

return M

