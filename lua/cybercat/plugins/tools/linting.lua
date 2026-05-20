return {
	"mfussenegger/nvim-lint",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	config = function()
		local lint = require("lint")

		-- Configure mypy to use virtual environment
		lint.linters.mypy = require("lint.linters.mypy")
		lint.linters.mypy.args = {
			"--show-column-numbers",
			"--show-error-end",
			"--hide-error-codes",
			"--hide-error-context",
			"--no-color-output",
			"--no-error-summary",
			"--no-pretty",
		}
		-- Use python from virtual environment to run mypy
		lint.linters.mypy.cmd = function()
			local venv_python = vim.fn.getcwd() .. "/.venv/bin/python"
			if vim.fn.executable(venv_python) == 1 then
				return venv_python
			end
			return "python"
		end
		lint.linters.mypy.args = vim.list_extend({ "-m", "mypy" }, lint.linters.mypy.args)

		-- lint.linters_by_ft = {
		--   javascript = { "eslint_d" },
		--   typescript = { "eslint_d" },
		--   javascriptreact = { "eslint_d" },
		--   typescriptreact = { "eslint_d" },
		--   svelte = { "eslint_d" },
		--   python = { "pylint" },
		-- }
		lint.linters.cspell = {
			name = "cspell",
			cmd = "cspell",
			stdin = false, -- cspell does not accept stdin
			args = {
				"--no-summary",
				"--no-progress",
				"--language-id",
				"en_us",
				-- "--no-words", -- This ensures variable names like camelCase are checked
				"--quiet",
				"$FILENAME",
			},
			stream = "stderr",
			parser = function(output, bufnr)
				local diagnostics = {}
				for line in vim.gsplit(output, "\n") do
					local filename, row, col, message = string.match(line, "^([^:]+):(%d+):(%d+)%s*%- (.+)$")
					row = tonumber(row)
					col = tonumber(col)
					if filename and row and col and message then
						table.insert(diagnostics, {
							bufnr = bufnr,
							lnum = row - 1,
							col = col - 1,
							message = message,
							severity = vim.diagnostic.severity.WARN,
							source = "cspell",
						})
					end
				end
				-- return diagnostics
				return diagnostics, vim.v.shell_error
			end,
		}
		lint.linters_by_ft = {
			javascript = { "eslint_d", "cspell" },
			typescript = { "eslint_d", "cspell" },
			javascriptreact = { "eslint_d", "cspell" },
			typescriptreact = { "eslint_d", "cspell" },
			svelte = { "eslint_d", "cspell" },
			-- Python: ruff is much faster than pylint (Rust-based)
			-- go = { "golangci_lint" },
			-- Good for AI development where you iterate quickly
			python = { "ruff", "mypy" },
			markdown = { "cspell" },
			text = { "cspell" },
			html = { "cspell" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		-- vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
		-- 	group = lint_augroup,
		-- 	callback = function()
		-- 		lint.try_lint()
		-- 	end,
		-- })

		vim.keymap.set("n", "<leader>l", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })

		local cspell_enabled = true

		vim.api.nvim_create_user_command("CspellToggle", function()
			cspell_enabled = not cspell_enabled
			if cspell_enabled then
				vim.notify("CSpell Enabled", vim.log.levels.INFO)
			else
				vim.notify("CSpell Disabled", vim.log.levels.WARN)
			end
		end, {})

		-- Only lint on save — BufEnter/InsertLeave cause constant spawning (very expensive for cspell/mypy)
		local lint_timer = vim.uv.new_timer()
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			group = lint_augroup,
			callback = function()
				-- Debounce: cancel pending lint, fire 500ms after save
				lint_timer:stop()
				lint_timer:start(500, 0, vim.schedule_wrap(function()
					if not cspell_enabled then
						local buf_ft = vim.bo.filetype
						local linters = lint.linters_by_ft[buf_ft] or {}
						local active_linters = vim.tbl_filter(function(linter)
							return linter ~= "cspell"
						end, linters)
						if #active_linters > 0 then
							lint.try_lint(active_linters)
						end
					else
						lint.try_lint()
					end
				end))
			end,
		})
	end,
}
