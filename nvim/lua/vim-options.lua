vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "

vim.opt.nu = true -- enable line numbers
vim.opt.relativenumber = true -- relative line numbers

-- copy to clipboard comments
vim.keymap.set({"n", "v"}, "<leader>y", [["*y]])

-- navigate panes with ease between tmux and nvim
vim.keymap.set("n",  "<c-l>", ':wincmd l<CR>')
vim.keymap.set("n",  "<c-k>", ':wincmd k<CR>')
vim.keymap.set("n",  "<c-j>", ':wincmd j<CR>')
vim.keymap.set("n",  "<c-h>", ':wincmd h<CR>')

