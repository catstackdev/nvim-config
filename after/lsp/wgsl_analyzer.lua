return {
	filetypes = { "wgsl" },
	on_attach = function(client, bufnr)
		if client.server_capabilities.documentFormattingProvider then
			vim.api.nvim_create_autocmd("BufWritePre", {
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr, async = false })
				end,
			})
		end
		-- if client:supports_method("textDocument/formatting") then
		-- 	vim.api.nvim_create_autocmd("BufWritePre", {
		-- 		buffer = bufnr,
		-- 		callback = function()
		-- 			vim.lsp.buf.format({
		-- 				bufnr = bufnr,
		-- 				async = false,
		-- 				filter = function(c)
		-- 					return c.name == "wgsl-analyzer"
		-- 				end,
		-- 			})
		-- 		end,
		-- 	})
		-- end

		-- 🔍 optional: enable inlay hints properly (Neovim 0.10+)
		if vim.lsp.inlay_hint then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end
	end,
	settings = {
		["wgsl-analyzer"] = {
			-- customImports = {},                  -- map your /include/raymarch.glsl-style helpers if you add WGSL includes
			diagnostics = {
				typeErrors = true,
				nagaParsing = true, -- runs naga front-end
				-- nagaValidation = true, -- runs naga IR validation
				nagaValidation = false, -- runs naga IR validation
				nagaVersion = "main",
				-- nagaVersion = "23",
			},
			inlayHints = {
				enabled = true,
				typeHints = true, -- shows inferred f32/vec2<f32> etc.
				parameterHints = true,
				structLayoutHints = true, -- shows byte offsets
				typeVerbosity = "compact",
			},
		},
	},
}
