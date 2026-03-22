return {
  'mitch1000/backpack.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    require('backpack').setup {
      theme = 'dark',
      contrast = 'high',
    }
    vim.g.my_color_scheme = 'backpack'
    vim.cmd('colorscheme ' .. vim.g.my_color_scheme)
  end,
}
