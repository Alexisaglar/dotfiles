return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        opts = {
          ensure_installed = { 'lua', 'python', 'vim', 'html', 'markdown', 'ruby' }, 
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
