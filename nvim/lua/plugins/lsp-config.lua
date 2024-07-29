return {
	{
		"williamboman/mason.nvim",
    lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
    lazy = false,
		config = function()
			require("mason-lspconfig").setup({
        auto_install = true,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
    lazy = false,
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local lspconfig = require("lspconfig")
			lspconfig.pyright.setup({
				capabilities = capabilities,
			})
			lspconfig.lua_ls.setup({
				capabilities = capabilities,
      })

			-- Key mappings for LSP functionality
			vim.keymap.set("n", "K", vim.lsp.buf.hover, { noremap = true })
			vim.keymap.set("n", "gD", vim.lsp.buf.definition, { noremap = true })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { noremap = true })
		end,
	},
}
