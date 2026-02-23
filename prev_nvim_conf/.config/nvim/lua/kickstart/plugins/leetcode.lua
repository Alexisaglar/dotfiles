return {
  'kawre/leetcode.nvim',
  build = ':TSUpdate html', -- Recommended if you have nvim-treesitter installed
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    -- You also need a picker plugin. Some popular choices are:
    'nvim-telescope/telescope.nvim',
    -- "ibhagwan/fzf-lua",
  },
  opts = {
    -- Your custom configuration for leetcode.nvim goes here
    -- For example:
    lang = 'python3',
  },
}
