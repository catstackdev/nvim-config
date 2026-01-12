-- TypeScript/JavaScript Language Server
-- Note: tsserver is now ts_ls in newer versions
return {
	cmd = { "typescript-language-server", "--stdio" },
	-- root_dir = require("lspconfig").util.root_pattern("package.json", "tsconfig.json", "jsconfig.json"),
	-- settings = {
	-- 	typescript = {
	-- 		tsdk = "/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/lib/node_modules/typescript/lib",
	-- 		inlayHints = {
	-- 			includeInlayParameterNameHints = "all",
	-- 			includeInlayParameterNameHintsWhenArgumentMatchesName = false,
	-- 			includeInlayFunctionParameterTypeHints = true,
	-- 			includeInlayVariableTypeHints = true,
	-- 			includeInlayPropertyDeclarationTypeHints = true,
	-- 			includeInlayFunctionLikeReturnTypeHints = true,
	-- 			includeInlayEnumMemberValueHints = true,
	-- 		},
	-- 	},
	-- 	javascript = {
	-- 		inlayHints = {
	-- 			includeInlayParameterNameHints = "all",
	-- 			includeInlayParameterNameHintsWhenArgumentMatchesName = false,
	-- 			includeInlayFunctionParameterTypeHints = true,
	-- 			includeInlayVariableTypeHints = true,
	-- 			includeInlayPropertyDeclarationTypeHints = true,
	-- 			includeInlayFunctionLikeReturnTypeHints = true,
	-- 			includeInlayEnumMemberValueHints = true,
	-- 		},
	-- 	},
	-- },
	-- cmd = { "typescript-language-server", "--stdio" },
	-- root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json"),
	settings = {
		typescript = {
			tsdk = "/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/lib/node_modules/typescript/lib",
			-- tsdk = "~/.nvm/versions/node/v22.9.0/lib/node_modules/typescript/lib",
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
		javascript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayVariableTypeHintsWhenTypeMatchesName = false,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
	},
	root_dir = vim.fs.root(0, { "package.json", "tsconfig.json", "jsconfig.json" }),
}
