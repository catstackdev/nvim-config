--mason.lua
return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- import mason
		local mason = require("mason")

		-- import mason-lspconfig
		local mason_lspconfig = require("mason-lspconfig")

		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			-- list of servers for mason to install
			ensure_installed = {
				"ts_ls",
				"html",
				"cssls",
				"tailwindcss",
				"svelte",
				"lua_ls",
				"graphql",
				"emmet_ls",
				"prismals",
				"pyright",
				"terraformls", -- for terraform
				"jsonls",
				"luau_lsp",
				"dockerls",
				"marksman", -- markdown lsp
				"angularls",
				-- "handlebars_ls",
				-- "ember", --for .hbs file for react template using plop
			},
			-- auto-install configured servers (with lspconfig)
			automatic_installation = true, -- not the same as ensure_installed
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"prettier", -- prettier formatter
				"stylua", -- lua formatter
				"isort", -- python formattemedmarkdown
				"black", -- python formatter
				"pylint", -- python linter
				"eslint_d", -- js linter
				"cfn-lint", -- cloudformation linter
				"mdx_analyzer",
				"sql-formatter", --sqlformatter for js
				"bashls", -- bash .sh
				"shfmt",
				"beautysh", --formatter for zsh

				"cspell", --check typo
				-- "djlint", -- testing
				"llm-ls", -- #lsp server for ai llm
				"js-debug-adapter",
			},
			run_on_start = true, -- run on startup
		})
	end,
}
