return {
  'blazkowolf/gruber-darker.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    -- setup must be called before loading
    vim.cmd 'colorscheme gruber-darker'
  end,
}
