return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'leoluz/nvim-dap-go',
      'rcarriga/nvim-dap-ui',
      'mfussenegger/nvim-dap-python',
      'theHamsta/nvim-dap-virtual-text',
      'nvim-neotest/nvim-nio',
      -- "williamboman/mason.nvim"
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'
      local dap_python = require 'dap-python'

      require('dapui').setup {}

      require('dap-python').setup '/Users/alexisaglar/resource_allocation_live/tftenv/bin/python'
      require('nvim-dap-virtual-text').setup {
        commented = true,
      }

      dap_python.setup 'python3'

      vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint)
      vim.keymap.set('n', '<leader>dc', dap.run_to_cursor)
      vim.keymap.set('n', '<leader>dq', dap.terminate)
      vim.keymap.set('n', '<leader>dt', dapui.toggle)
      vim.keymap.set('n', '<leader>dr', ":lua require('dapui').open({reset=true})<CR>")
      vim.keymap.set('n', '<space>?', function()
        require('dapui').eval(nil, { enter = true })
      end)

      vim.keymap.set('n', '<F1>', dap.continue)
      vim.keymap.set('n', '<F2>', dap.step_into)
      vim.keymap.set('n', '<F3>', dap.step_over)
      vim.keymap.set('n', '<F4>', dap.step_out)
      vim.keymap.set('n', '<F5>', dap.step_back)
      vim.keymap.set('n', '<F6>', dap.restart)

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end

      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end

      -- automatic clossing
      -- dap.listeners.before.event_terminated.dapui_config = function()
      --   dapui.close()
      -- end

      -- dap.listeners.before.event_exited.dapui_config = function()
      --   dapui.close()
      -- end
    end,
  },
}
