local fn = vim.fn

local M = {}

local config = {
	colorscheme = "gruvbox",
}

function M.setup(opt)
	if type(opt) == "table" then
		config = vim.tbl_deep_extend("force", config, opt)
	end
	local colors = require("themes/" .. config.colorscheme)

	local groups = {
		--  :h highlight-default
		ColorColumn = {},
		Conceal = {},
		CurSearch = {},
		Cursor = { reverse = true },
		lCursor = { link = "Cursor" },
		CursorIM = {},
		CursorColumn = { link = "CursorLine" },
		CursorLine = {},
		Directory = { bold = true },
		DiffAdd = { fg = colors.info, reverse = true },
		DiffChange = { fg = colors.warn, reverse = true },
		DiffDelete = { fg = colors.error, reverse = true },
		DiffText = { reverse = true },
		EndOfBuffer = {},
		TermCursor = { link = "Cursor" },
		TermCursorNC = {},
		ErrorMsg = { fg = colors.error, bold = true },
		WinSeparator = {},
		Folded = { italic = true },
		FoldColumn = {},
		SignColumn = {},
		IncSearch = { link = "Search" },
		Substitute = { link = "Search" },
		LineNr = { fg = colors.linenr },
		LineNrAbove = { link = "LineNr" },
		LineNrBelow = { link = "LineNr" },
		CursorLineNr = {}, -- todo
		CursorLineFold = {}, -- todo
		CursorLineSign = {}, -- todo
		MatchParen = { fg = colors.info, reverse = true, bold = true },
		ModeMsg = { bold = true },
		MsgArea = {},
		MsgSeparator = {},
		MoreMsg = { bold = true },
		NonText = {},
		Normal = { fg = colors.fg, bg = colors.bg },
		NormalFloat = { bg = colors.float_bg },
		FloatBorder = {},
		FloatTitle = {},
		NormalNC = { link = "Normal" },
		Pmenu = { fg = colors.pmenu_fg, bg = colors.pmenu_bg },
		PmenuSel = { fg = colors.pmenu_sel_fg, bg = colors.pmenu_sel_bg, bold = true },
		PmenuKind = {}, --todo
		PmenuKindSel = {}, --todo
		PmenuExtra = {}, --todo
		PmenuExtraSel = {}, --todo
		PmenuSbar = { bg = colors.pmenu_bar },
		PmenuThumb = { bg = colors.pmenu_thumb },
		Question = { bold = true },
		QuickFixLine = { bold = true },
		Search = { fg = colors.search_fg, bg = colors.search_bg },
		SpecialKey = {},
		SpellBad = { undercurl = true, sp = colors.error },
		SpellCap = { undercurl = true, sp = colors.info },
		SpellLocal = { undercurl = true, sp = colors.info },
		SpellRare = { undercurl = true, sp = colors.hint },
		StatusLine = { fg = colors.status_fg, bg = colors.status_bg },
		StatusLineNC = {},
		TabLine = { fg = colors.status_b_fg, bg = colors.status_b_bg },
		TabLineFill = { fg = colors.status_fg, bg = colors.status_bg },
		TabLineSel = { fg = colors.status_a_fg, bg = colors.status_a_bg },
		Title = { bold = true },
		Visual = { bg = colors.visual_bg },
		VisualNOS = { link = "Visual" },
		WarningMsg = { fg = colors.warn, bold = true },
		Whitespace = {},
		WildMenu = {},
		WinBar = {},
		WinBarNC = {},

		--  :h group-name
		Comment = { fg = colors.comment, italic = true },

		Constant = { fg = colors.constant, bold = true },
		String = { fg = colors.string },
		Character = { fg = colors.character },
		Number = { fg = colors.number },
		Boolean = { fg = colors.boolean },
		Float = { fg = colors.number },

		Identifier = { fg = colors.variable },
		Function = { fg = colors.func, bold = true },

		Statement = { fg = colors.keyword },
		Conditional = { fg = colors.conditional },
		Repeat = { fg = colors.loop },
		Label = { fg = colors.loop },
		Operator = { fg = colors.operator },
		Keyword = { fg = colors.keyword },
		Exception = { fg = colors.exception },

		PreProc = { fg = colors.preproc },
		Include = { fg = colors.include },
		Define = { fg = colors.define },
		Macro = { fg = colors.macro },
		PreCondit = { fg = colors.preproc },

		Type = { fg = colors.type },
		StorageClass = { fg = colors.class },
		Structure = { fg = colors.class },
		Typedef = { link = "Type" },

		Special = { fg = colors.variable },
		SpecialChar = {},
		Tag = { fg = colors.tag },
		Delimiter = { fg = colors.tag_delimiter },
		SpecialComment = { fg = colors.comment, italic = true },
		Debug = {},

		Underlined = { underline = true },
		Ignore = {},
		Error = { fg = colors.error, bold = true },
		Todo = { bold = true, italic = true },

		--  :h lsp-highlight
		LspReferenceText = { bold = true },
		LspReferenceRead = { bold = true },
		LspReferenceWrite = { bold = true },
		LspCodeLens = { fg = colors.comment },
		LspCodeLensSeparator = {},
		LspSignatureActiveParameter = {},

		--  :h hl-DiagnosticError
		DiagnosticError = { fg = colors.error },
		DiagnosticWarn = { fg = colors.warn },
		DiagnosticInfo = { fg = colors.info },
		DiagnosticHint = { fg = colors.hint },
		DiagnosticVirtualTextError = { fg = colors.error },
		DiagnosticVirtualTextWarn = { fg = colors.warn },
		DiagnosticVirtualTextInfo = { fg = colors.info },
		DiagnosticVirtualTextHint = { fg = colors.hint },
		DiagnosticVirtualTextOk = {},
		DiagnosticUnderlineError = { undercurl = true, sp = colors.error },
		DiagnosticUnderlineWarn = { undercurl = true, sp = colors.warn },
		DiagnosticUnderlineInfo = { undercurl = true, sp = colors.info },
		DiagnosticUnderlineHint = { undercurl = true, sp = colors.hint },
		DiagnosticUnderlineOk = {},
		DiagnosticFloatingError = { fg = colors.error },
		DiagnosticFloatingWarn = { fg = colors.warn },
		DiagnosticFloatingInfo = { fg = colors.info },
		DiagnosticFloatingHint = { fg = colors.hint },
		DiagnosticFloatingOk = {},
		DiagnosticSignError = { fg = colors.error },
		DiagnosticSignWarn = { fg = colors.warn },
		DiagnosticSignInfo = { fg = colors.info },
		DiagnosticSignHint = { fg = colors.hint },
		DiagnosticSignOk = {},

		-- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md
		-- Misc
		["@comment"] = { link = "Comment" },
		["@comment.documentation"] = { fg = colors.string, italic = true },
		["@error"] = { link = "Error" },
		["@none"] = { bg = "NONE", fg = "NONE" },
		["@preproc"] = { link = "PreProc" },
		["@define"] = { link = "Define" },
		["@operator"] = { link = "Operator" },

		-- Punctuation
		["@punctuation.delimiter"] = { link = "Delimiter" },
		["@punctuation.bracket"] = { fg = colors.bracket },
		["@punctuation.special"] = { link = "Special" },

		-- Literals
		["@string"] = { link = "String" },
		["@string.documentation"] = { link = "String" },
		["@string.regex"] = { fg = colors.regex },
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
		["@function.macro"] = { fg = colors.macro },

		["@method"] = { link = "Function" },
		["@method.call"] = { link = "Function" },

		["@constructor"] = { link = "Function" },
		["@parameter"] = { fg = colors.parameter },

		-- Keywords
		["@keyword"] = { link = "Keyword" },
		["@keyword.coroutine"] = { link = "Keyword" },
		["@keyword.function"] = { link = "Keyword" },
		["@keyword.operator"] = { fg = colors.operator },
		["@keyword.return"] = { fg = colors.ret },

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
		["@property"] = { fg = colors.property },

		-- Identifiers
		["@variable"] = { link = "Identifier" },
		["@variable.builtin"] = { link = "Identifier" },

		["@constant"] = { link = "Constant" },
		["@constant.builtin"] = { link = "Constant" },
		["@constant.macro"] = { link = "Constant" },

		["@namespace"] = { fg = colors.class },
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

		StatusA = { fg = colors.status_a_fg, bg = colors.status_a_bg },
		StatusB = { fg = colors.status_b_fg, bg = colors.status_b_bg },
		StatusC = { fg = colors.status_c_fg, bg = colors.status_c_bg },
	}

	vim.cmd("hi clear")
	vim.g.colors_name = "gruvbox"
	vim.o.termguicolors = true
	for group, settings in pairs(groups) do
		vim.api.nvim_set_hl(0, group, settings)
	end
end

function M.html(theme)
	local dest = fn.stdpath("config") .. "/theme.html"
	local file = io.open(dest, "w")
	if file == nil then
		return
	end
	local colors = require("themes/" .. theme)
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
				'<div><input type="color" value="%s"><label style="color: %s"> %s - %s</label></div>',
				color,
				color,
				key,
				color
			)
		)
	end
	local style = string.format("<style>body {font-family: Arial,sans-serif; background: %s;}</style>", colors.bg)
	local script =
		"<script>const inputs = document.getElementsByTagName('INPUT'); for (let i = 0; i < inputs.length; i++) inputs[i].onchange = (e) => {e.target.nextSibling.style.color = e.target.value}</script>"
	local str = "<!DOCTYPE html><head>" .. style .. "</head><body>" .. table.concat(list, "") .. script .. "</body>"
	file:write(str)
	file:close()
	vim.notify("Theme html file has saved to " .. dest, vim.log.levels.INFO, {})
end

return M

