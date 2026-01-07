return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/lazydev.nvim", opts = {} },
		{
			"j-hui/fidget.nvim",
			opts = {
				progress = {
					-- Suppress specific messages
					suppress_on_insert = true, -- Hide during insert mode
					ignore = {
						"lua_ls", -- Ignore lua_ls progress
					},
				},
				notification = {
					window = {
						winblend = 0,
					},
				},
			},
		},
	},
	config = function()
		-- Import required plugins
		local lspconfig = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		-- Enable autocompletion capabilities for all LSP servers
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Enhanced capabilities
		capabilities.textDocument.completion.completionItem = {
			documentationFormat = { "markdown", "plaintext" },
			snippetSupport = true,
			preselectSupport = true,
			insertReplaceSupport = true,
			labelDetailsSupport = true,
			deprecatedSupport = true,
			commitCharactersSupport = true,
			tagSupport = { valueSet = { 1 } },
			resolveSupport = {
				properties = {
					"documentation",
					"detail",
					"additionalTextEdits",
				},
			},
		}

		-- Helper function to load server config from after/lsp/
		local function get_server_config(server_name)
			local config_path = vim.fn.stdpath("config") .. "/after/lsp/" .. server_name .. ".lua"

			if vim.fn.filereadable(config_path) == 1 then
				-- Load the config file
				local ok, server_config = pcall(dofile, config_path)
				if ok and server_config then
					return server_config
				end
			end

			return {}
		end

		-- Setup mason-lspconfig handlers to automatically start LSP servers
		-- mason_lspconfig.setup_handlers({
		-- 	-- Default handler for all servers
		-- 	function(server_name)
		-- 		-- Get server-specific config from after/lsp/{server_name}.lua
		-- 		local server_config = get_server_config(server_name)
		--
		-- 		-- Merge with default capabilities
		-- 		server_config.capabilities = vim.tbl_deep_extend(
		-- 			"force",
		-- 			capabilities,
		-- 			server_config.capabilities or {}
		-- 		)
		--
		-- 		-- Setup the LSP server
		-- 		lspconfig[server_name].setup(server_config)
		-- 	end,
		-- })
	end,
}
