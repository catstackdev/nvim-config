-- Prisma Language Server
-- return {
-- 	filetypes = { "prisma" },
-- }
return {
	filetypes = { "prisma" },
	on_attach = function(client, bufnr)
		-- Check if the server supports formatting
		if client.server_capabilities.documentFormattingProvider then
			local group = vim.api.nvim_create_augroup("PrismaFormat", { clear = true })

			vim.api.nvim_create_autocmd("BufWritePre", {
				group = group,
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr })
				end,
			})
		end
	end,
	settings = {
		prisma = {
			prismaFmtBinPath = "",
		},
	},
}
