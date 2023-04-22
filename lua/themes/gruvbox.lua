-- https://github.com/ellisonleao/gruvbox.nvim
local gruvbox_dark = {
	bg0 = "#282828",
	bg1 = "#3c3836",
	bg2 = "#504945",
	bg3 = "#665c54",
	bg4 = "#7c6f64",
	fg0 = "#fbf1c7",
	fg1 = "#ebdbb2",
	fg2 = "#d5c4a1",
	fg3 = "#bdae93",
	fg4 = "#a89984",
	gray = "#928374",
	red = "#fb4934",
	green = "#b8bb26",
	yellow = "#fabd2f",
	blue = "#83a598",
	purple = "#d3869b",
	aqua = "#8ec07c",
	orange = "#fe8019",
}

local c = gruvbox_dark

local groups = {
	--  :h highlight-default
	ColorColumn = { bg = c.bg1 },
	Conceal = { fg = c.blue },
	CurSearch = {},
	Cursor = { reverse = true },
	lCursor = { link = "Cursor" },
	CursorIM = {},
	CursorColumn = { link = "CursorLine" },
	CursorLine = { bg = c.bg1 },
	Directory = { fg = c.green, bold = true },
	DiffAdd = { fg = c.green, bg = c.bg0, reverse = true },
	DiffChange = { fg = c.aqua, bg = c.bg0, reverse = true },
	DiffDelete = { fg = c.red, bg = c.bg0, reverse = true },
	DiffText = { fg = c.yellow, bg = c.bg0, reverse = true },
	EndOfBuffer = {},
	TermCursor = { link = "Cursor" },
	TermCursorNC = {},
	ErrorMsg = { fg = c.red, bold = true },
	WinSeparator = {},
	Folded = { fg = c.gray, bg = c.bg1, italic = true },
	FoldColumn = { fg = c.gray, bg = c.bg1 },
	SignColumn = { bg = c.bg1 },
	IncSearch = { fg = c.orange, bg = c.bg0, reverse = true },
	Substitute = { link = "Search" },
	LineNr = { fg = c.bg4 },
	LineNrAbove = { link = "LineNr" },
	LineNrBelow = { link = "LineNr" },
	CursorLineNr = { fg = c.yellow, bg = c.bg1 },
	CursorLineFold = {},
	CursorLineSign = {},
	MatchParen = { bg = c.bg3, bold = true },
	ModeMsg = { fg = c.yellow, bold = true },
	MsgArea = {},
	MsgSeparator = {},
	MoreMsg = { fg = c.yellow, bold = true },
	NonText = { fg = c.bg2 },
	Normal = { fg = c.fg1, bg = c.bg0 },
	NormalFloat = { bg = c.bg1 },
	FloatBorder = {},
	FloatTitle = {},
	NormalNC = { link = "Normal" },
	Pmenu = { fg = c.fg1, bg = c.bg2 },
	PmenuSel = { fg = c.bg2, bg = c.blue, bold = true },
	PmenuKind = {},
	PmenuKindSel = {},
	PmenuExtra = {},
	PmenuExtraSel = {},
	PmenuSbar = { bg = c.bg2 },
	PmenuThumb = { bg = c.bg4 },
	Question = { fg = c.orange, bold = true },
	QuickFixLine = { fg = c.bg0, bg = c.yellow, bold = true },
	Search = { fg = c.yellow, bg = c.bg0, reverse = true },
	SpecialKey = { fg = c.fg4 },
	SpellBad = { undercurl = true, sp = c.red },
	SpellCap = { undercurl = true, sp = c.blue },
	SpellLocal = { undercurl = true, sp = c.aqua },
	SpellRare = { undercurl = true, sp = c.purple },
	StatusLine = { fg = c.bg2, bg = c.fg1, reverse = true },
	StatusLineNC = { fg = c.bg1, bg = c.fg4, reverse = true },
	TabLine = { fg = c.fg2, bg = c.bg2 },
	TabLineFill = { fg = c.bg4, bg = c.bg1 },
	TabLineSel = { fg = c.bg0, bg = c.fg3 },
	Title = { fg = c.green, bold = true },
	Visual = { bg = c.bg3 },
	VisualNOS = { link = "Visual" },
	WarningMsg = { fg = c.red, bold = true },
	Whitespace = {},
	WildMenu = { fg = c.blue, bg = c.bg2, bold = true },
	WinBar = {},
	WinBarNC = {},

	--  :h group-name
	Comment = { fg = c.gray, italic = true },

	Constant = { fg = c.gray },
	String = { fg = c.green },
	Character = { fg = c.purple },
	Number = { fg = c.yellow },
	Boolean = { fg = c.aqua },
	Float = { fg = c.fg3 },

	Identifier = { fg = c.blue },
	Function = { fg = c.green, bold = true },

	Statement = { fg = c.red },
	Conditional = { fg = c.red },
	Repeat = { fg = c.red },
	Label = { fg = c.red },
	Operator = { fg = c.orange },
	Keyword = { fg = c.red },
	Exception = { fg = c.red },

	PreProc = { fg = c.aqua },
	Include = { fg = c.fg3 },
	Define = { fg = c.fg2 },
	Macro = { fg = c.fg4 },
	PreCondit = { fg = c.orange },

	Type = { fg = c.yellow },
	StorageClass = { fg = c.orange },
	Structure = { fg = c.aqua },
	Typedef = { fg = c.yellow },

	Special = { fg = c.orange },
	SpecialChar = {},
	Tag = {},
	Delimiter = {},
	SpecialComment = {},
	Debug = {},

	Underlined = { fg = c.blue, underline = true },
	Ignore = {},
	Error = { fg = c.red, bold = true },
	Todo = { fg = c.fg0, bold = true, italic = true },

	--  :h lsp-highlight
	LspReferenceText = { fg = c.yellow, bold = true },
	LspReferenceRead = { fg = c.yellow, bold = true },
	LspReferenceWrite = { fg = c.orange, bold = true },
	LspCodeLens = { fg = c.gray },
	LspCodeLensSeparator = {},
	LspSignatureActiveParameter = {},

	--  :h hl-DiagnosticError
	DiagnosticError = { fg = c.red },
	DiagnosticWarn = { fg = c.yellow },
	DiagnosticInfo = { fg = c.blue },
	DiagnosticHint = { fg = c.aqua },
	DiagnosticVirtualTextError = { fg = c.red },
	DiagnosticVirtualTextWarn = { fg = c.yellow },
	DiagnosticVirtualTextInfo = { fg = c.blue },
	DiagnosticVirtualTextHint = { fg = c.aqua },
	DiagnosticVirtualTextOk = {},
	DiagnosticUnderlineError = { undercurl = true, sp = c.red },
	DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
	DiagnosticUnderlineInfo = { undercurl = true, sp = c.blue },
	DiagnosticUnderlineHint = { undercurl = true, sp = c.aqua },
	DiagnosticUnderlineOk = {},
	DiagnosticFloatingError = { fg = c.red },
	DiagnosticFloatingWarn = { fg = c.orange },
	DiagnosticFloatingInfo = { fg = c.blue },
	DiagnosticFloatingHint = { fg = c.aqua },
	DiagnosticFloatingOk = {},
	DiagnosticSignError = { fg = c.red, bg = c.bg1 },
	DiagnosticSignWarn = { fg = c.yellow, bg = c.bg1 },
	DiagnosticSignInfo = { fg = c.blue, bg = c.bg1 },
	DiagnosticSignHint = { fg = c.aqua, bg = c.bg1 },
	DiagnosticSignOk = {},

	-- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md
	-- Misc
	["@comment"] = { link = "Comment" },
	["@comment.documentation"] = { fg = c.purple, italic = true },
	["@error"] = { link = "Error" },
	["@none"] = { bg = "NONE", fg = "NONE" },
	["@preproc"] = { link = "PreProc" },
	["@define"] = { link = "Define" },
	["@operator"] = { link = "Operator" },

	-- Punctuation
	["@punctuation.delimiter"] = { link = "Delimiter" },
	["@punctuation.bracket"] = { fg = c.fg4 },
	["@punctuation.special"] = { fg = c.orange },

	-- Literals
	["@string"] = { link = "String" },
	["@string.documentation"] = { fg = c.fg3 },
	["@string.regex"] = { fg = c.fg2 },
	["@string.escape"] = { fg = c.aqua },
	["@string.special"] = { fg = c.orange },

	["@character"] = { link = "Character" },
	["@character.special"] = { fg = c.purple },

	["@boolean"] = { link = "Boolean" },
	["@number"] = { link = "Number" },
	["@float"] = { link = "Float" },

	-- Functions
	["@function"] = { link = "Function" },
	["@function.builtin"] = { fg = c.blue, bold = true },
	["@function.call"] = { fg = c.red, bold = true },
	["@function.macro"] = { fg = c.yellow, bold = true },

	["@method"] = { fg = c.green, bold = true },
	["@method.call"] = { fg = c.orange, bold = true },

	["@constructor"] = { fg = c.blue, bold = true },
	["@parameter"] = { fg = c.fg2 },

	-- Keywords
	["@keyword"] = { link = "Keyword" },
	["@keyword.coroutine"] = { fg = c.fg1 },
	["@keyword.function"] = { fg = c.fg2 },
	["@keyword.operator"] = { fg = c.fg3 },
	["@keyword.return"] = { fg = c.fg4 },

	["@conditional"] = { link = "Conditional" },
	["@conditional.ternary"] = { fg = c.fg4 },

	["@repeat"] = { link = "Repeat" },
	["@debug"] = { link = "Debug" },
	["@label"] = { link = "Label" },
	["@include"] = { link = "Include" },
	["@exception"] = { link = "Exception" },

	-- Types
	["@type"] = { link = "Type" },
	["@type.builtin"] = { fg = c.blue },
	["@type.definition"] = { fg = c.purple },
	["@type.qualifier"] = { fg = c.aqua },

	["@storageclass"] = { fg = c.orange },
	["@attribute"] = { fg = c.blue },
	["@field"] = { fg = c.fg3 },
	["@property"] = { fg = c.fg2 },

	-- Identifiers
	["@variable"] = { link = "Identifier" },
	["@variable.builtin"] = { fg = c.green },

	["@constant"] = { link = "Constant" },
	["@constant.builtin"] = { fg = c.aqua },
	["@constant.macro"] = { fg = c.red },

	["@namespace"] = { fg = c.blue },
	["@symbol"] = { link = "Identifier" },

	-- Text
	["@text"] = { link = "String" },
	["@text.strong"] = { bold = true },
	["@text.emphasis"] = { italic = true },
	["@text.underline"] = { underline = true },
	["@text.strike"] = { strikethrough = true },
	["@text.title"] = { link = "Title" },
	["@text.literal"] = { link = "String" },
	["@text.quote"] = {},
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
}

vim.cmd("hi clear")
vim.g.colors_name = "gruvbox"
vim.o.termguicolors = true
for group, settings in pairs(groups) do
	vim.api.nvim_set_hl(0, group, settings)
end

