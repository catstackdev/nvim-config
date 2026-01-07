-- ESLint Language Server
return {
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"vue",
		"svelte",
	},
	settings = {
		codeAction = {
			disableRuleComment = {
				enable = true,
				location = "separateLine",
			},
			showDocumentation = {
				enable = true,
			},
		},
		codeActionOnSave = {
			enable = false, -- Use conform.nvim instead
			mode = "all",
		},
		format = false, -- Use conform.nvim/prettier instead
		quiet = false,
		onIgnoredFiles = "off",
		rulesCustomizations = {},
		run = "onType",
		validate = "on",
		workingDirectory = {
			mode = "auto",
		},
	},
}
