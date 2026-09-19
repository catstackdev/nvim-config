-- Lua Language Server
return {
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
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
				-- Limit number of files preloaded (speeds up loading)
				maxPreload = 2000,
				-- Skip analyzing large directories
				preloadFileSize = 1000,
			},
			telemetry = {
				enable = false,
			},
			-- Disable progress notifications (loading/diagnosing messages)
			window = {
				-- progressBar = false,
			},
		},
	},
	-- Alternative: Filter out progress notifications at client level
	on_attach = function(client)
		client.server_capabilities.window = client.server_capabilities.window or {}
		client.server_capabilities.window.workDoneProgress = false
	end,
}
