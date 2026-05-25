-- ==================================
-- = NEOVIM CONFIG - mostly vanilla =
-- ==================================

-- Leader key (must be set before any mappings)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- =============================================================================
-- OPTIONS
-- =============================================================================

local opt = vim.opt

-- Line numbers
opt.number = true           -- show line numbers
opt.relativenumber = true   -- relative line numbers (great for jumps)

-- Indentation
opt.tabstop = 4             -- tab = 4 spaces
opt.shiftwidth = 4          -- indent = 4 spaces
opt.expandtab = true        -- use spaces instead of tabs
opt.smartindent = true      -- auto indent on new line

-- Search
opt.ignorecase = true       -- case insensitive search...
opt.smartcase = true        -- ...unless you type uppercase
opt.hlsearch = true         -- highlight search results
opt.incsearch = true        -- show matches as you type

-- Appearance
opt.termguicolors = true    -- full color support
opt.scrolloff = 15           -- keep 8 lines above/below cursor
opt.signcolumn = "yes"      -- always show sign column (prevents layout shift)
opt.wrap = false            -- no line wrapping
opt.cursorline = true       -- highlight current line

-- Splits
opt.splitright = true       -- vertical split goes right
opt.splitbelow = true       -- horizontal split goes below

-- Files
opt.swapfile = false        -- no swap files
opt.backup = false          -- no backup files
opt.undofile = true         -- persistent undo (survives closing nvim)
opt.undodir = os.getenv("HOME") .. "/.nvim/undodir"

-- Misc
opt.updatetime = 250        -- faster completion/diagnostics
opt.clipboard = "unnamedplus" -- use system clipboard by default
opt.mouse = "a"             -- enable mouse support

-- C specific
opt.path:append("**")      -- recursive :find search
opt.makeprg = "gcc % -o %<" -- :make compiles current file with gcc

-- ===============================================
-- =================== KEYMAPS ===================
-- ===============================================

local map = vim.keymap.set
-- -----------
-- - Buffers -
-- -----------
map("n", "]b", ":bnext<CR>",      { desc = "Next buffer" })
map("n", "[b", ":bprev<CR>",      { desc = "Prev buffer" })
map("n", "bx", ":bp | bd#<CR>",   { desc = "Close buffer (go to prev)" })
map("n", "<leader>b", ":ls<CR>:b ",      { desc = "List buffers + jump" })
-- map("n", "<leader>", ":b#<CR>",         { desc = "Toggle last two buffers" })

-- -------------------------
-- Splits
-- -------------------------
map("n", "<leader>sv", ":vsp<CR>",        { desc = "Vertical split" })
map("n", "<leader>sh", ":sp<CR>",         { desc = "Horizontal split" })
map("n", "<leader>sq", "<C-w>q",          { desc = "Close split" })
map("n", "<leader>so", "<C-w>o",          { desc = "Close all other splits" })
map("n", "<leader>se", "<C-w>=",          { desc = "Equalize split sizes" })

-- Split navigation (replaces <C-w>hjkl)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- Split resizing
map("n", "<C-Left>",  ":vertical resize -2<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase width" })
map("n", "<C-Up>",    ":resize -2<CR>",           { desc = "Decrease height" })
map("n", "<C-Down>",  ":resize +2<CR>",           { desc = "Increase height" })

-- -------------------------
-- Tabs
-- -------------------------
-- map("n", "<leader>tn", ":tabnew<CR>",     { desc = "New tab" })
-- map("n", "<leader>tc", ":tabc<CR>",       { desc = "Close tab" })
-- map("n", "<leader>to", ":tabo<CR>",       { desc = "Close all other tabs" })
-- map("n", "gt",         ":tabnext<CR>",    { desc = "Next tab" })
-- map("n", "gT",         ":tabprev<CR>",    { desc = "Prev tab" })

-- -------------------------
-- Terminal
-- -------------------------
-- map("n", "<leader>tt", ":sp | term<CR>",   { desc = "Terminal in horizontal split" })
map("n", "<leader>t", ":vsp | vertical resize 60 | term<CR>",  { desc = "Terminal in vertical split" })
-- map("n", "<leader>tT", ":tabnew | term<CR>", { desc = "Terminal in new tab" })
map("t", "<Esc>",      "<C-\\><C-n>",      { desc = "Exit terminal mode" })

-- -------------------------
-- Quickfix (great for :make and :grep)
-- -------------------------
map("n", "<leader>co", ":copen<CR>",      { desc = "Open quickfix" })
map("n", "<leader>cc", ":cclose<CR>",     { desc = "Close quickfix" })
map("n", "]q",         ":cnext<CR>",      { desc = "Next quickfix item" })
map("n", "[q",         ":cprev<CR>",      { desc = "Prev quickfix item" })
map("n", "<leader>cm", ":make<CR>",       { desc = "Run :make (compile)" })

-- -------------------------
-- Diagnostics (LSP)
-- -------------------------
map("n", "]d", vim.diagnostic.goto_next,  { desc = "Next diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev,  { desc = "Prev diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic float" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to quickfix" })

-- -------------------------
-- File explorer (Netrw)
-- -------------------------
-- map("n", "<leader>fe", ":Ex<CR>",         { desc = "File explorer" })
map("n", "<leader>fs", ":Vex<CR>",        { desc = "File explorer (vertical)" })
-- map("n", "<leader>fs", ":Sex<CR>",        { desc = "File explorer (horizontal)" })

-- -------------------------
-- Search
-- -------------------------
map("n", "<leader>h", ":nohlsearch<CR>",  { desc = "Clear search highlight" })
-- grep across C files in project
map("n", "<leader>fg", ":grep  **/*.c **/*.h<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>", { desc = "Grep C files" })

-- -------------------------
-- Misc quality of life
-- -------------------------
-- Keep cursor centered when jumping
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n",     "nzzzv")
map("n", "N",     "Nzzzv")

-- Escape alternatives
-- map("i", "jj",           "<Esc>",        { desc = "Exit insert mode" })
map("i", "<C-c><C-c>",   "<Esc>",        { desc = "Exit insert mode" })
-- map("t", "<C-c><C-c>",   "<C-\\><C-n>",  { desc = "Exit terminal mode" })

-- Move lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Paste without losing register
map("x", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })

-- =============================================================================
-- LSP - clangd for C
-- =============================================================================

-- This sets up the built-in LSP client to use clangd.
-- Requirements: clangd must be installed on your system.
--   Ubuntu/Debian: sudo apt install clangd
--   RHEL/Fedora: sudo dnf install clangd
--   Arch:          sudo pacman -S clang
--   macOS:         brew install llvm

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        vim.lsp.start({
            name = "clangd",
            cmd = { "clangd" },
            root_dir = vim.fs.dirname(
                vim.fs.find({ "compile_commands.json", ".clangd", ".git", "Makefile" }, {
                    upward = true
                })[1]
            ) or vim.fn.getcwd(),
            capabilities = vim.lsp.protocol.make_client_capabilities(),
        })
    end,
})

-- LSP keymaps (only active when LSP is attached)
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufopts = { buffer = args.buf }

        map("n", "gd",         vim.lsp.buf.definition,      vim.tbl_extend("force", bufopts, { desc = "Go to definition" }))
        map("n", "gD",         vim.lsp.buf.declaration,     vim.tbl_extend("force", bufopts, { desc = "Go to declaration" }))
        map("n", "gr",         vim.lsp.buf.references,      vim.tbl_extend("force", bufopts, { desc = "Find references" }))
        map("n", "gi",         vim.lsp.buf.implementation,  vim.tbl_extend("force", bufopts, { desc = "Go to implementation" }))
        map("n", "K",          vim.lsp.buf.hover,           vim.tbl_extend("force", bufopts, { desc = "Hover docs" }))
        map("n", "<leader>rn", vim.lsp.buf.rename,          vim.tbl_extend("force", bufopts, { desc = "Rename symbol" }))
        map("n", "<leader>ca", vim.lsp.buf.code_action,     vim.tbl_extend("force", bufopts, { desc = "Code action" }))
        map("n", "<leader>f",  vim.lsp.buf.format,          vim.tbl_extend("force", bufopts, { desc = "Format file" }))
        map("i", "<C-s>",      vim.lsp.buf.signature_help,  vim.tbl_extend("force", bufopts, { desc = "Signature help" }))
    end,
})

-- LSP diagnostics appearance
vim.diagnostic.config({
    virtual_text = true,       -- show errors inline at end of line
    signs = true,              -- show signs in the gutter
    underline = true,          -- underline the problematic code
    update_in_insert = false,  -- don't update diagnostics while typing
    severity_sort = true,      -- errors before warnings
})

--
-- ========================================
-- = NEOVIM CONFIG - Vanilla (no plugins) =
-- ========================================

-- Install third-party plugins via "vim.pack.add()".
vim.pack.add({
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/terrortylor/nvim-comment',
  'https://github.com/blazkowolf/gruber-darker.nvim',
})

require('nvim_comment').setup {vim.keymap.set({"n", "v"}, "<leader>/", ":CommentToggle<cr>")}
require('gruber-darker').setup {vim.cmd 'colorscheme gruber-darker'}
