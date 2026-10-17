-- moss — a simple dark green theme (matches ~/.config/kitty/moss.conf)
-- No backgrounds are painted: the terminal background shows through. Only
-- selection, search and the completion menu keep one, since they need it.

vim.cmd.highlight("clear")
vim.o.background = "dark"
vim.g.colors_name = "moss"

local c = {
    bg      = "#0f1512",
    bg_alt  = "#161d19",
    bg_sel  = "#24332b",
    border  = "#2c3a32",
    comment = "#5f7366",
    fg_dim  = "#8a9a8f",
    fg      = "#c5d1c8",
    white   = "#e3ebe5",
    green   = "#8fbf8f",
    lime    = "#a9d6a0",
    teal    = "#6fb5a0",
    yellow  = "#c9c27e",
    orange  = "#cfa06a",
    red     = "#c97b70",
    blue    = "#7fa8b0",
    purple  = "#a890b0",
}

local groups = {
    -- editor
    Normal       = { fg = c.fg },
    NormalFloat  = { fg = c.fg },
    FloatBorder  = { fg = c.border },
    ColorColumn  = {},
    CursorLine   = {},
    CursorColumn = {},
    LineNr       = { fg = c.comment },
    CursorLineNr = { fg = c.green, bold = true },
    SignColumn   = {},
    FoldColumn   = { fg = c.comment },
    Folded       = { fg = c.fg_dim },
    WinSeparator = { fg = c.border },
    StatusLine   = { fg = c.green, bold = true },
    StatusLineNC = { fg = c.comment },
    TabLine      = { fg = c.fg_dim },
    TabLineFill  = {},
    TabLineSel   = { fg = c.green, bold = true },
    Visual       = { bg = c.bg_sel },
    Search       = { fg = c.bg, bg = c.yellow },
    IncSearch    = { fg = c.bg, bg = c.orange },
    CurSearch    = { fg = c.bg, bg = c.orange },
    MatchParen   = { fg = c.lime, bold = true, underline = true },
    Pmenu        = { fg = c.fg, bg = c.bg_alt },
    PmenuSel     = { fg = c.bg, bg = c.green },
    PmenuSbar    = { bg = c.bg_alt },
    PmenuThumb   = { bg = c.border },
    NonText      = { fg = c.border },
    Whitespace   = { fg = c.border },
    EndOfBuffer  = { fg = c.border },
    SpecialKey   = { fg = c.comment },
    Conceal      = { fg = c.comment },
    Directory    = { fg = c.teal },
    Title        = { fg = c.lime, bold = true },
    Question     = { fg = c.green },
    MoreMsg      = { fg = c.green },
    ModeMsg      = { fg = c.fg_dim },
    ErrorMsg     = { fg = c.red },
    WarningMsg   = { fg = c.orange },
    QuickFixLine = { fg = c.lime, bold = true },

    -- syntax
    Comment      = { fg = c.comment },
    String       = { fg = c.yellow },
    Character    = { fg = c.yellow },
    Number       = { fg = c.orange },
    Boolean      = { fg = c.orange },
    Float        = { fg = c.orange },
    Constant     = { fg = c.orange },
    Identifier   = { fg = c.fg },
    Function     = { fg = c.teal },
    Statement    = { fg = c.green, bold = true },
    Keyword      = { fg = c.green, bold = true },
    Conditional  = { fg = c.green, bold = true },
    Repeat       = { fg = c.green, bold = true },
    Exception    = { fg = c.green, bold = true },
    Operator     = { fg = c.fg_dim },
    PreProc      = { fg = c.blue },
    Type         = { fg = c.lime },
    Special      = { fg = c.blue },
    Delimiter    = { fg = c.fg_dim },
    Underlined   = { fg = c.teal, underline = true },
    Todo         = { fg = c.yellow, bold = true },
    Error        = { fg = c.red },

    -- treesitter / LSP (most links fall through to the groups above)
    ["@variable"]           = { fg = c.fg },
    ["@variable.builtin"]   = { fg = c.purple },
    ["@variable.member"]    = { fg = c.fg },
    ["@property"]           = { fg = c.fg },
    ["@constructor"]        = { fg = c.lime },
    ["@module"]             = { fg = c.fg_dim },
    ["@punctuation"]        = { fg = c.fg_dim },
    ["@string.escape"]      = { fg = c.blue },
    ["@tag"]                = { fg = c.green },
    ["@tag.attribute"]      = { fg = c.teal },
    ["@markup.heading"]     = { fg = c.lime, bold = true },
    ["@markup.link"]        = { fg = c.teal, underline = true },
    ["@markup.raw"]         = { fg = c.yellow },
    ["@lsp.type.variable"]  = {},
    ["@lsp.type.property"]  = {},

    -- diagnostics
    DiagnosticError = { fg = c.red },
    DiagnosticWarn  = { fg = c.orange },
    DiagnosticInfo  = { fg = c.blue },
    DiagnosticHint  = { fg = c.teal },
    DiagnosticOk    = { fg = c.green },
    DiagnosticUnderlineError = { sp = c.red, undercurl = true },
    DiagnosticUnderlineWarn  = { sp = c.orange, undercurl = true },
    DiagnosticUnderlineInfo  = { sp = c.blue, undercurl = true },
    DiagnosticUnderlineHint  = { sp = c.teal, undercurl = true },

    -- diff
    DiffAdd    = { fg = c.green },
    DiffChange = { fg = c.blue },
    DiffDelete = { fg = c.red },
    DiffText   = { fg = c.blue, bold = true, underline = true },
    Added      = { fg = c.green },
    Changed    = { fg = c.blue },
    Removed    = { fg = c.red },

    -- spelling
    SpellBad   = { sp = c.red, undercurl = true },
    SpellCap   = { sp = c.orange, undercurl = true },
    SpellRare  = { sp = c.purple, undercurl = true },
    SpellLocal = { sp = c.teal, undercurl = true },
}

for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
end

local term = {
    c.bg_alt, c.red, c.green, c.yellow, c.blue, c.purple, c.teal, c.fg,
    c.comment, "#dc9589", c.lime, "#d9d39a", "#9bc0c7", "#bfa8c6", "#8ccdb8", c.white,
}
for i, color in ipairs(term) do
    vim.g["terminal_color_" .. (i - 1)] = color
end
