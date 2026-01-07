-- Svelte Language Server
return {
	on_attach = function(client, bufnr)
		-- Notify Svelte LSP when JS/TS files change (for reactivity)
		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = { "*.js", "*.ts" },
			callback = function(ctx)
				client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
			end,
		})
	end,
}
