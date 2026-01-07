return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
		-- NEW: Adds a nice UI for LSP progress
		{
			"j-hui/fidget.nvim",
			-- tag = "*", -- alternatively, pin this to a specific version, e.g., "v1.6.1"
			opts = {},
		},
	},
	config = function()
		-- import lspconfig plugin
		vim.lsp.util.make_position_params_orig = vim.lsp.util.make_position_params

		vim.lsp.util.make_position_params = function(_, offset_encoding)
			offset_encoding = offset_encoding or "utf-16" -- adjust if needed
			return vim.lsp.util.make_position_params_orig(_, offset_encoding)
		end

		local lspconfig = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap -- for conciseness

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, silent = true }

				-- Keymaps
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)
				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

				-- set keybinds
			end,
		})

		local on_attach = function(client, bufnr)
			local opts = { buffer = bufnr, silent = true }

			-- NEW: Setup format-on-save
			if client.supports_method("textDocument/formatting") then
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true }),
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 5000 })
					end,
				})
			end
			-- Navic (breadcrumb)
			if client.server_capabilities.documentSymbolProvider then
				navic.attach(client, bufnr)
			end
		end

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()
		capabilities.textDocument.completion.completionItem.snippetSupport = true

		-- Change the Diagnostic symbols in the sign column (gutter)
		-- (not in youtube nvim video)
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end
		-- local function additional_tf_formatting()
		--   -- For example, run an external formatter or custom commands
		--   -- Example: vim.cmd("!terraform fmt -write=true")
		--   vim.cmd("!terraform fmt -write=true")
		--   vim.cmd([[retab]])
		--   --Whitespace Removal: Besides removing trailing whitespace, you can remove all whitespace from lines:
		--   vim.cmd([[:%s/\s\+$//e]])
		--   --Text Alignment: You can align text based on a specific character. For example, to align text around = characters:
		--   -- vim.cmd([[:'<,'>Tabularize /=]])
		-- end
		mason_lspconfig.setup({
			function(server_name)
				lspconfig[server_name].setup({
					on_attach = on_attach,
					capabilities = capabilities,
				})
			end,
			["marksman"] = function()
				lspconfig["marksman"].setup({
					on_attach = on_attach,
					capabilities = capabilities,
					filetypes = { "markdown", "mdx" },
				})
			end,

			-- ["ember"] = function()
			-- 	lspconfig["ember"].setup({
			-- 		capabilities = capabilities,
			-- 		filetypes = { "handlebars", "hbs" },
			-- 		cmd = { "ember-language-server", "--stdio" },
			-- 		root_dir = lspconfig.util.root_pattern("ember-cli-build.js", ".git"),
			-- 		on_attach = function(client, bufnr)
			-- 			vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
			-- 				pattern = "*.hbs",
			-- 				callback = function()
			-- 					vim.bo.filetype = "handlebars"
			-- 				end,
			-- 			})
			-- 		end,
			-- 	})
			-- end,

			["angularls"] = function()
				lspconfig["angularls"].setup({
					-- cmd = {
					-- 	"ngserver",
					-- 	"--stdio",
					-- 	"--tsProbeLocations",
					-- 	"/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/lib/node_modules/typescript",
					-- 	"--ngProbeLocations",
					-- 	"/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/lib/node_modules/@angular",
					-- },
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
					-- filetypes = { "html", "typescript", "javascript", "typescriptreact", "javascriptreact" },
					filetypes = { "typescript", "html", "typescriptreact", "htmlangular" },
					root_dir = require("lspconfig").util.root_pattern("angular.json", ".git"),
					on_attach = function(client, bufnr)
						print("Angular Language Server attached to " .. vim.bo.filetype)
						-- Disable formatting if another formatter is used
						client.server_capabilities.documentFormattingProvider = false
						on_attach(client, bufnr)
					end, --NOTE: enable this is delete below
					-- on_attach = on_attach,
				})
			end,
			["tsserver"] = function()
				lspconfig["tsserver"].setup({
					capabilities = capabilities,

					on_attach = on_attach,
					cmd = { "typescript-language-server", "--stdio" },
					root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json"),
					settings = {
						typescript = {
							tsdk = "/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/lib/node_modules/typescript/lib",
							-- tsdk = "~/.nvm/versions/node/v22.9.0/lib/node_modules/typescript/lib",
						},
					},
				})
			end,

			["svelte"] = function()
				-- configure svelte server
				lspconfig["svelte"].setup({
					capabilities = capabilities,
					on_attach = function(client, bufnr)
						vim.api.nvim_create_autocmd("BufWritePost", {
							pattern = { "*.js", "*.ts" },
							callback = function(ctx)
								-- Here use ctx.match instead of ctx.file
								client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
							end,
						})
					end,
				})
			end,
			["graphql"] = function()
				-- configure graphql language server
				--
				lspconfig["graphql"].setup({
					on_attach = on_attach,
					capabilities = capabilities,
					filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
				})
			end,
			["emmet_ls"] = function()
				-- configure emmet language server
				lspconfig["emmet_ls"].setup({

					on_attach = on_attach,
					capabilities = capabilities,
					filetypes = {
						"html",
						"typescriptreact",
						"javascriptreact",
						"css",
						"sass",
						"scss",
						"less",
						"svelte",
						"handlebars",
						"hbs",
					},
				})
			end,

			["html"] = function()
				lspconfig["html"].setup({
					on_attach = on_attach,
					capabilities = capabilities,
					filetypes = {
						"html",
						"handlebars",
						"templ",
						"hbs",
					},
				})
			end,
			["lua_ls"] = function()
				-- configure lua server (with special settings)
				lspconfig["lua_ls"].setup({

					on_attach = on_attach,
					capabilities = capabilities,
					settings = {
						Lua = {
							-- make the language server recognize "vim" global
							diagnostics = {
								globals = { "vim" },
							},
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				})
			end,
		})
	end,
}
