return {
	"stevearc/conform.nvim",
	-- lazy = true,
	event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	config = function()
		local conform = require("conform")
		-- Expand path once at config time
		local prettier_config = vim.fn.expand("~/.prettierrc.yaml")
		local home_dir = vim.fn.expand("~")

		local function resolve_executable(name, opts)
			opts = opts or {}

			local path = vim.fn.exepath(name)

			-- Prefer non-Mason executable
			if path ~= "" and not path:find("/mason/", 1, true) then
				return path
			end

			-- Try custom fallback paths
			for _, fallback in ipairs(opts.fallbacks or {}) do
				if vim.fn.executable(fallback) == 1 then
					return fallback
				end
			end

			-- Last resort: Mason or PATH
			if path ~= "" then
				return path
			end

			return name
		end
		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				svelte = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				liquid = { "prettier" },
				prisma = { "prettier" }, -- Prisma schema files
				-- handlebars = { "prettier" },
				lua = { "stylua" },
				python = { "ruff_format", "ruff_organize_imports" }, -- Ruff does both formatting + imports (faster than black+isort)
				go = { "goimports", "gofumpt" },
				rust = { "rustfmt" },
				sql = { "sql_formatter" }, -- Fixed: use underscore not hyphen
				shell = { "shfmt" },
				alloy = { "alloy_fmt" },
				-- terraform = { "terraform_fmt" }, -- Disabled: terraform CLI not installed
				-- Disable shfmt for zsh - it can't handle Zsh-specific syntax
				-- like glob qualifiers (N), extended globs, etc.
				-- zsh = { "shfmt" },
			},

			-- Force prettier to always use global config instead of project-level
			formatters = {
				prettier = {
					-- Override args function to force global config
					args = function(self, ctx)
						return {
							"--config",
							prettier_config,
							"--no-editorconfig",
							"--stdin-filepath",
							"$FILENAME",
						}
					end,
				},
				-- sql_formatter = {
				-- 	command = function()
				-- 		return resolve_executable("sql-formatter")
				-- 	end,
				-- 	prepend_args = {
				-- 		"--language",
				-- 		"postgresql",
				-- 	},
				-- },
				sql_formatter = {
					command = function()
						return resolve_executable("sql-formatter")
					end,

					args = function(self, ctx)
						local local_config =
							vim.fs.find(".sql-formatter.json", { path = ctx.dirname, upward = true })[1]

						return {
							"--config",
							local_config or vim.fn.expand("~/.config/sql-formatter/.sql-formatter.json"),
						}
					end,
				},
				rustfmt = {
					command = function()
						return resolve_executable("rustfmt", {
							fallbacks = {
								vim.fn.expand("~/.cargo/bin/rustfmt"),
								"/opt/homebrew/opt/rustup/bin/rustfmt",
							},
						})
					end,
				},
				-- Configure shfmt for shell scripts (not zsh)
				shfmt = {
					prepend_args = { "-i", "2", "-ci" }, -- 2 space indent, indent switch cases
				},
				-- `alloy fmt` prints formatted output to stdout
				alloy_fmt = {
					command = "alloy",
					args = { "fmt", "$FILENAME" },
					stdin = false,
				},
				stylua = {
					command = function()
						return resolve_executable("stylua")
					end,
				},
			},
			format_on_save = {
				lsp_fallback = true,
				async = false,
				timeout_ms = 10000,
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
