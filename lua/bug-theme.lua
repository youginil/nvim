local fn = vim.fn

local M = {}

local config = {
	colorscheme = "gruvbox",
}

local function hex2rgb(s)
	return {
		tonumber(string.sub(s, 2, 3), 16),
		tonumber(string.sub(s, 4, 5), 16),
		tonumber(string.sub(s, 6, 7), 16),
	}
end

local function rgb2hex(v)
	return "#" .. string.format("%x", v[1]) .. string.format("%x", v[2]) .. string.format("%x", v[3])
end

local function mix(c1, c2, ratio)
	print(c1)
	local r1, g1, b1 = unpack(hex2rgb(c1))
	local r2, g2, b2 = unpack(hex2rgb(c2))
	local r = r1 * ratio + r2 * (1 - ratio)
	local g = g1 * ratio + g2 * (1 - ratio)
	local b = b1 * ratio + b2 * (1 - ratio)
	return rgb2hex({ r, g, b })
end

function M.setup(opt)
	if type(opt) == "table" then
		config = vim.tbl_deep_extend("force", config, opt)
	end
	local theme = require("themes/" .. config.colorscheme)
	local c = theme.colors

	local groups = {
		--  :h highlight-default
		ColorColumn = {},
		Conceal = {},
		CurSearch = { fg = c.fg, bg = mix(c.search_bg, c.bg, 0.5) },
		Cursor = { reverse = true },
		lCursor = { link = "Cursor" },
		CursorIM = {},
		CursorColumn = { link = "CursorLine" },
		CursorLine = {},
		Directory = { bold = true },
		DiffAdd = { fg = c.info, reverse = true },
		DiffChange = { fg = c.warn, reverse = true },
		DiffDelete = { fg = c.error, reverse = true },
		DiffText = { reverse = true },
		EndOfBuffer = {},
		TermCursor = { link = "Cursor" },
		TermCursorNC = {},
		ErrorMsg = { fg = c.error, bold = true },
		WinSeparator = {},
		Folded = { italic = true },
		FoldColumn = {},
		SignColumn = {},
		IncSearch = { link = "Search" },
		Substitute = { link = "Search" },
		LineNr = { fg = c.linenr },
		LineNrAbove = { link = "LineNr" },
		LineNrBelow = { link = "LineNr" },
		CursorLineNr = {}, -- todo
		CursorLineFold = {}, -- todo
		CursorLineSign = {}, -- todo
		MatchParen = { fg = c.info, reverse = true, bold = true },
		ModeMsg = { bold = true },
		MsgArea = {},
		MsgSeparator = {},
		MoreMsg = { bold = true },
		NonText = {},
		Normal = { fg = c.fg, bg = c.bg },
		NormalFloat = { bg = c.float_bg },
		FloatBorder = {},
		FloatTitle = {},
		NormalNC = { link = "Normal" },
		Pmenu = { fg = c.pmenu_fg, bg = c.pmenu_bg },
		PmenuSel = { fg = c.pmenu_sel_fg, bg = c.pmenu_sel_bg, bold = true },
		PmenuKind = {}, --todo
		PmenuKindSel = {}, --todo
		PmenuExtra = {}, --todo
		PmenuExtraSel = {}, --todo
		PmenuSbar = { bg = c.pmenu_bar },
		PmenuThumb = { bg = c.pmenu_thumb },
		Question = { bold = true },
		QuickFixLine = { bold = true },
		Search = { fg = c.search_fg, bg = c.search_bg },
		SpecialKey = {},
		SpellBad = { undercurl = true, sp = c.error },
		SpellCap = { undercurl = true, sp = c.info },
		SpellLocal = { undercurl = true, sp = c.info },
		SpellRare = { undercurl = true, sp = c.hint },
		StatusLine = { fg = c.status_fg, bg = c.status_bg },
		StatusLineNC = {},
		TabLine = { fg = c.status_fg, bg = c.status_bg },
		TabLineFill = { fg = c.status_fg, bg = c.status_bg },
		TabLineSel = { fg = c.status_a_fg, bg = c.status_a_bg },
		Title = { bold = true },
		Visual = { bg = c.visual_bg },
		VisualNOS = { link = "Visual" },
		WarningMsg = { fg = c.warn, bold = true },
		Whitespace = {},
		WildMenu = {},
		WinBar = {},
		WinBarNC = {},

		--  :h group-name
		Comment = { fg = c.comment, italic = true },

		Constant = { fg = c.constant, bold = true },
		String = { fg = c.string },
		Character = { fg = c.character },
		Number = { fg = c.number },
		Boolean = { fg = c.boolean },
		Float = { fg = c.number },

		Identifier = { fg = c.variable },
		Function = { fg = c.func, bold = true },

		Statement = { fg = c.keyword },
		Conditional = { fg = c.conditional },
		Repeat = { fg = c.loop },
		Label = { fg = c.loop },
		Operator = { fg = c.operator },
		Keyword = { fg = c.keyword },
		Exception = { fg = c.exception },

		PreProc = { fg = c.preproc },
		Include = { fg = c.include },
		Define = { fg = c.define },
		Macro = { fg = c.macro },
		PreCondit = { fg = c.preproc },

		Type = { fg = c.type },
		StorageClass = { fg = c.class },
		Structure = { fg = c.class },
		Typedef = { link = "Type" },

		Special = { fg = c.variable },
		SpecialChar = {},
		Tag = { fg = c.tag },
		Delimiter = { fg = c.tag_delimiter },
		SpecialComment = { fg = c.comment, italic = true },
		Debug = {},

		Underlined = { underline = true },
		Ignore = {},
		Error = { fg = c.error, bold = true },
		Todo = { bold = true, italic = true },

		--  :h lsp-highlight
		LspReferenceText = { bold = true },
		LspReferenceRead = { bold = true },
		LspReferenceWrite = { bold = true },
		LspCodeLens = { fg = c.comment },
		LspCodeLensSeparator = {},
		LspSignatureActiveParameter = {},

		--  :h hl-DiagnosticError
		DiagnosticError = { fg = c.error },
		DiagnosticWarn = { fg = c.warn },
		DiagnosticInfo = { fg = c.info },
		DiagnosticHint = { fg = c.hint },
		DiagnosticVirtualTextError = { fg = c.error },
		DiagnosticVirtualTextWarn = { fg = c.warn },
		DiagnosticVirtualTextInfo = { fg = c.info },
		DiagnosticVirtualTextHint = { fg = c.hint },
		DiagnosticVirtualTextOk = {},
		DiagnosticUnderlineError = { undercurl = true, sp = c.error },
		DiagnosticUnderlineWarn = { undercurl = true, sp = c.warn },
		DiagnosticUnderlineInfo = { undercurl = true, sp = c.info },
		DiagnosticUnderlineHint = { undercurl = true, sp = c.hint },
		DiagnosticUnderlineOk = {},
		DiagnosticFloatingError = { fg = c.error },
		DiagnosticFloatingWarn = { fg = c.warn },
		DiagnosticFloatingInfo = { fg = c.info },
		DiagnosticFloatingHint = { fg = c.hint },
		DiagnosticFloatingOk = {},
		DiagnosticSignError = { fg = c.error },
		DiagnosticSignWarn = { fg = c.warn },
		DiagnosticSignInfo = { fg = c.info },
		DiagnosticSignHint = { fg = c.hint },
		DiagnosticSignOk = {},

		-- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md
		-- Misc
		["@comment"] = { link = "Comment" },
		["@comment.documentation"] = { fg = c.string, italic = true },
		["@error"] = { link = "Error" },
		["@none"] = { bg = "NONE", fg = "NONE" },
		["@preproc"] = { link = "PreProc" },
		["@define"] = { link = "Define" },
		["@operator"] = { link = "Operator" },

		-- Punctuation
		["@punctuation.delimiter"] = { link = "Delimiter" },
		["@punctuation.bracket"] = { fg = c.bracket },
		["@punctuation.special"] = { link = "Special" },

		-- Literals
		["@string"] = { link = "String" },
		["@string.documentation"] = { link = "String" },
		["@string.regex"] = { fg = c.regex },
		["@string.escape"] = { link = "String" },
		["@string.special"] = { link = "String" },

		["@character"] = { link = "Character" },
		["@character.special"] = { link = "Character" },

		["@boolean"] = { link = "Boolean" },
		["@number"] = { link = "Number" },
		["@float"] = { link = "Float" },

		-- Functions
		["@function"] = { link = "Function" },
		["@function.builtin"] = { link = "Function" },
		["@function.call"] = { link = "Function" },
		["@function.macro"] = { fg = c.macro },

		["@method"] = { link = "Function" },
		["@method.call"] = { link = "Function" },

		["@constructor"] = { link = "Function" },
		["@parameter"] = { fg = c.parameter },

		-- Keywords
		["@keyword"] = { link = "Keyword" },
		["@keyword.coroutine"] = { link = "Keyword" },
		["@keyword.function"] = { link = "Keyword" },
		["@keyword.operator"] = { fg = c.operator },
		["@keyword.return"] = { fg = c.ret },

		["@conditional"] = { link = "Conditional" },
		["@conditional.ternary"] = { link = "Conditional" },

		["@repeat"] = { link = "Repeat" },
		["@debug"] = { link = "Debug" },
		["@label"] = { link = "Label" },
		["@include"] = { link = "Include" },
		["@exception"] = { link = "Exception" },

		-- Types
		["@type"] = { link = "Type" },
		["@type.builtin"] = { link = "Type" },
		["@type.definition"] = { link = "Type" },
		["@type.qualifier"] = { link = "Type" },

		["@storageclass"] = { link = "StorageClass" },
		["@attribute"] = { link = "@property" },
		["@field"] = { link = "@property" },
		["@property"] = { fg = c.property },

		-- Identifiers
		["@variable"] = { link = "Identifier" },
		["@variable.builtin"] = { link = "Identifier" },

		["@constant"] = { link = "Constant" },
		["@constant.builtin"] = { link = "Constant" },
		["@constant.macro"] = { link = "Constant" },

		["@namespace"] = { fg = c.class },
		["@symbol"] = { link = "Identifier" },

		-- Text
		["@text"] = { link = "String" },
		["@text.strong"] = { bold = true },
		["@text.emphasis"] = { italic = true },
		["@text.underline"] = { underline = true },
		["@text.strike"] = { strikethrough = true },
		["@text.title"] = { link = "Title" },
		["@text.literal"] = { link = "String" },
		["@text.quote"] = { italic = true },
		["@text.uri"] = { link = "Underlined" },
		["@text.math"] = { link = "Special" },
		["@text.environment"] = { link = "Macro" },
		["@text.environment.name"] = { link = "Type" },
		["@text.reference"] = { link = "Constant" },

		["@text.todo"] = { link = "Todo" },
		["@text.note"] = { link = "SpecialComment" },
		["@text.warning"] = { link = "WarningMsg" },
		["@text.danger"] = { link = "ErrorMsg" },

		["@text.diff.add"] = { link = "diffAdded" },
		["@text.diff.delete"] = { link = "diffRemoved" },

		-- Tags
		["@tag"] = { link = "Tag" },
		["@tag.attribute"] = { link = "Identifier" },
		["@tag.delimiter"] = { link = "Delimiter" },

		-- Conceal
		["@conceal"] = {},

		-- Spell
		["@spell"] = {},
		["@nospell"] = {},

		-- Locals
		["@definition"] = {},
		["@definition.constant"] = {},
		["@definition.function"] = {},
		["@definition.method"] = {},
		["@definition.var"] = {},
		["@definition.parameter"] = {},
		["@definition.macro"] = {},
		["@definition.type"] = {},
		["@definition.field"] = {},
		["@definition.enum"] = {},
		["@definition.namespace"] = {},
		["@definition.import"] = {},
		["@definition.associated"] = {},

		["@scope"] = {},
		["@reference"] = {},

		-- Folds
		["@fold"] = {},

		-- Injections
		["@html"] = {},
		["@language"] = {},
		["@content"] = {},
		["@combined"] = {},

		-- Indents
		["@indent.begin"] = {},
		["@indent.end"] = {},
		["@indent.align"] = {},
		["@indent.dedent"] = {},
		["@indent.branch"] = {},
		["@indent.ignore"] = {},
		["@indent.auto"] = {},
		["@indent.zero"] = {},

		-- Treesitter
		-- See `:help treesitter`
		-- Those are not part of the nvim-treesitter
		["@punctuation"] = { link = "Delimiter" },
		["@macro"] = { link = "Macro" },
		["@structure"] = { link = "Structure" },

		-- Plugins
		StatusA = { fg = c.status_a_fg, bg = c.status_a_bg },
		StatusB = { fg = c.status_b_fg, bg = c.status_b_bg },
		StatusC = { fg = c.status_c_fg, bg = c.status_c_bg },
	}

	vim.cmd("hi clear")

	vim.o.termguicolors = true
	vim.g.colors_name = config.colorscheme
	vim.o.background = theme.background

	for group, settings in pairs(groups) do
		vim.api.nvim_set_hl(0, group, settings)
	end
end

function M.html(name)
	local dest = fn.stdpath("config") .. "/debug.html"
	local file = io.open(dest, "w")
	if file == nil then
		return
	end
	local theme = require("themes/" .. name)
	local colors = theme.colors
	local keys = {
		"string",
		"character",
		"number",
		"boolean",
		"regex",
		"keyword",
		"func",
		"parameter",
		"class",
		"property",
		"variable",
		"constant",
		"operator",
		"ret",
		"conditional",
		"loop",
		"exception",
		"include",
		"define",
		"preproc",
		"macro",
		"type",
		"bracket",
		"tag",
		"tag_attribute",
		"tag_delimiter",
		"comment",
	}
	local list = {}
	for _, key in ipairs(keys) do
		local color = colors[key]
		table.insert(
			list,
			string.format(
				'<div><input type="text" value="%s" data-key="%s"><label style="margin-left: 10px; color: %s">%s - %s</label></div>',
				color,
				key,
				color,
				key,
				color
			)
		)
	end
	local style = string.format("<style>body {font-family: Arial,sans-serif; background: %s;}</style>", colors.bg)
	local script = [[<script>
    const inputs = document.getElementsByTagName('INPUT');
    for (let i = 0; i < inputs.length; i++){
        inputs[i].onchange = (e)=>{
            const value = e.target.value;
            if (!/#[0-9][a-f]/i.test(value)) {
                return;
            }
            const label = e.target.nextSibling;
            label.style.color = e.target.value;
            label.innerText = e.target.dataset.key + ' - ' + e.target.value;
        }
    }
    </script>]]
	local str = "<!DOCTYPE html><head>" .. style .. "</head><body>" .. table.concat(list, "") .. script .. "</body>"
	file:write(str)
	file:close()
	vim.notify("Theme html file has saved to " .. dest, vim.log.levels.INFO, {})
end

return M

