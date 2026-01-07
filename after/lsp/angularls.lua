-- Angular Language Server
return {
	cmd = {
		"/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/bin/ngserver",
		"--stdio",
		"--tsProbeLocations",
		"/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/lib/node_modules/typescript",
		"--ngProbeLocations",
		"/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/lib/node_modules/@angular",
		"--angularCoreVersion",
		"18.0.1",
	},
	filetypes = { "typescript", "html", "typescriptreact", "htmlangular" },
	root_dir = require("lspconfig").util.root_pattern("angular.json", ".git"),
	on_attach = function(client, bufnr)
		print("✓ Angular Language Server attached to " .. vim.bo.filetype)
		-- Disable formatting - use Conform/Prettier instead
		client.server_capabilities.documentFormattingProvider = false
	end,
}
