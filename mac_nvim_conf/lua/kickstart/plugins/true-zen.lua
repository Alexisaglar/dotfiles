return{
  "Pocco81/true-zen.nvim",
  config = function()
    require("true-zen").setup({
      modes = {
        minimalist = {
          ignored_buf_types = { "nofile" },
          options = {
            -- number = false,

            --> true-zen
            -- relativenumber = false,
            -- showtabline = 0,
            -- signcolumn = "no",
            -- statusline = "",
            -- cmdheight = 1,
            -- laststatus = 0,
            -- showcmd = false,
            -- showmode = false,
            -- ruler = false,
            -- numberwidth = 1
          },
        },
      },
    })
    vim.keymap.set("n", "<leader>zn", ":TZNarrow<CR>", {})
    vim.keymap.set("v", "<leader>zn", ":'<,'>TZNarrow<CR>", {})
    vim.keymap.set("n", "<leader>zf", ":TZFocus<CR>", {})
    vim.keymap.set("n", "<leader>zm", ":TZMinimalist<CR>", {})
    vim.keymap.set("n", "<leader>za", ":TZAtaraxis<CR>", {})
	end,
  }
