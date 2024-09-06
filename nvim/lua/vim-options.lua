vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.nu = true -- enable line numbers
vim.opt.relativenumber = true -- relative line numbers

-- copy to clipboard comments
-- vim.api.nvim_set_option("clipboard", "unnamed")
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
-- vim.keymap.set({"n", "v"}, "<leader>y", [["*y]])

-- -- navigate panes with ease between tmux and nvim
vim.keymap.set("n",  "<C-l>", ':wincmd l<CR>')
vim.keymap.set("n",  "<C-k>", ':wincmd k<CR>')
vim.keymap.set("n",  "<C-j>", ':wincmd j<CR>')
vim.keymap.set("n",  "<C-h>", ':wincmd h<CR>')

vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')

