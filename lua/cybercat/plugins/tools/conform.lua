-- FOrmatting with conform.nvim

-- -- Auto-format when focus is lost or I leave the buffer
-- -- Useful if on skitty-notes or a regular buffer and switch somewhere else the
-- -- formatting doesn't stay all messed up
-- -- I found this autocmd example in the readme
-- -- https://github.com/stevearc/conform.nvim/blob/master/README.md#setup
-- -- "FocusLost" used when switching from skitty-notes
-- -- "BufLeave" is used when switching between 2 buffers
-- vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
-- 	pattern = "*",
-- 	callback = function(args)
-- 		local buf = args.buf or vim.api.nvim_get_current_buf()
-- 		-- Only format if the current mode is normal mode
-- 		-- Only format if autoformat is enabled for the current buffer (if
-- 		-- autoformat disabled globally the buffers inherits it, see :LazyFormatInfo)
-- 		if LazyVim.format.enabled(buf) and vim.fn.mode() == "n" then
-- 			-- Add a small delay to the formatting so it doesn’t interfere with
-- 			-- CopilotChat’s or grug-far buffer initialization, this helps me to not
-- 			-- get errors when using the "BufLeave" event above, if not using
-- 			-- "BufLeave" the delay is not needed
-- 			vim.defer_fn(function()
-- 				if vim.api.nvim_buf_is_valid(buf) then
-- 					require("conform").format({ bufnr = buf })
-- 				end
-- 			end, 100)
-- 		end
-- 	end,
-- })
--
return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		formatters_by_ft = {
			-- HTML files (including Angular templates)
			html = { "prettier" },

			-- Angular component templates
			-- Use prettier for .component.html files
			["html.angular"] = { "prettier" },

			-- JavaScript/TypeScript
			javascript = { "prettier" },
			typescript = { "prettier" },
			javascriptreact = { "prettier" },
			typescriptreact = { "prettier" },

			-- CSS/SCSS
			css = { "prettier" },
			scss = { "prettier" },

			-- JSON/YAML
			json = { "prettier" },
			jsonc = { "prettier" },
			yaml = { "prettier" },

			-- Markdown
			markdown = { "prettier" },

			-- Other languages
			templ = { "templ" },
			python = { "ruff_format" },
		},

		-- Format on save with function (more reliable)
		format_on_save = function(bufnr)
			-- Disable if autoformat is disabled
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end

			return {
				timeout_ms = 3000,
				lsp_fallback = true,
			}
		end,

		-- Formatters configuration
		formatters = {
			prettier = {
				prepend_args = {
					"--single-attribute-per-line",
					"--print-width=80",
				},
			},
		},
	},

	-- Add autocmd as fallback
	config = function(_, opts)
		local conform = require("conform")
		conform.setup(opts)

		-- Additional autocmd for save (fallback)
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*",
			callback = function(args)
				-- Don't format if disabled
				if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
					return
				end

				-- Format with conform
				conform.format({
					bufnr = args.buf,
					timeout_ms = 3000,
					lsp_fallback = true,
				})
			end,
		})

		-- Keybindings for manual format
		vim.keymap.set({ "n", "v" }, "<leader>cf", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 3000,
			})
		end, { desc = "Format file or range (in visual mode)" })

		-- Toggle autoformat
		vim.keymap.set("n", "<leader>tf", function()
			if vim.g.disable_autoformat then
				vim.g.disable_autoformat = false
				print("Autoformat enabled")
			else
				vim.g.disable_autoformat = true
				print("Autoformat disabled")
			end
		end, { desc = "Toggle autoformat" })
	end,
}
