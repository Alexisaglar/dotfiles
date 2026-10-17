--- editor options --- 
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.termguicolors =  true

-- Share ordinary yanks and pastes through Hyprland's Wayland clipboard.
vim.g.clipboard = "wl-copy"
vim.opt.clipboard = "unnamedplus"

--- keymaps ---
vim.g.mapleader = " "
vim.keymap.set("n", "<leader>e", vim.cmd.Ex, { desc = "Open File Explorer" })
vim.keymap.set("n", "<leader>h", vim.cmd.nohl, { desc = "Remove highlight" })

--- plugin managment ---
vim.pack.add({{ src = "https://github.com/blazkowolf/gruber-darker.nvim" }})
-- vim.cmd.colorscheme("gruber-darker")
vim.cmd.colorscheme("moss") -- local theme: colors/moss.lua


--- lsp ---
-- ESP-IDF's clangd; each project selects its build database in its .clangd.
-- The esp-21.1.3_20260408 paths change when ESP-IDF is upgraded.
local esp = vim.fn.expand("~/.espressif/tools")
vim.lsp.config("clangd", {
    cmd = {
        esp .. "/esp-clangd/esp-21.1.3_20260408/esp-clangd/bin/clangd",
        "--background-index",
        "--resource-dir=" .. esp .. "/esp-clang/esp-21.1.3_20260408/esp-clang/lib/clang/21",
        "--query-driver=" .. esp .. "/**/bin/*-elf-*",
    },
    filetypes = { "c", "cpp" },
    root_markers = { "sdkconfig", ".git" },
})
vim.lsp.enable("clangd")

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to definition" })
    end,
})
