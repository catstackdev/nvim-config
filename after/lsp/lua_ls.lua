-- Lua Language Server
return {
	settings = {
		Lua = {
			-- Make the language server recognize "vim" global
			diagnostics = {
				globals = { "vim" },
			},
			completion = {
				callSnippet = "Replace",
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = {
					vim.env.VIMRUNTIME,
					-- Add plugins to workspace if needed
					-- "${3rd}/luv/library",
					-- "${3rd}/busted/library",
				},
				checkThirdParty = false,
			},
			telemetry = {
				enable = false,
			},
		},
	},
}
