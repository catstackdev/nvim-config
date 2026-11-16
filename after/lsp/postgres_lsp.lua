-- PostgreSQL Language Server
return {
	cmd = { "postgres-language-server", "lsp-proxy" },
	filetypes = { "sql" },
	workspace_required = false,
	root_markers = {
		"postgres-language-server.jsonc",
		".git",
	},
}
