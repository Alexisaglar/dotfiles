return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    -- Use `opts` instead of `config`
    opts = {
      ensure_installed = { 'lua', 'python', 'vim', 'vimdoc' }, -- Add any other languages you use
      sync_install = false, -- Install parsers synchronously (blocks UI)
      auto_install = true, -- Automatically install parsers when entering a buffer
      highlight = {
        enable = true, -- Enable syntax highlighting
      },
      indent = {
        enable = true, -- Enable indentation based on treesitter
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
