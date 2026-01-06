return {
	"rcarriga/nvim-notify",
	config = function()
		local notify = require("notify")
		notify.setup({
			stages = "fade_in_slide_out",
			timeout = 3000,
			background_colour = "#1e1e2e",
			minimum_width = 50,
			max_width = 80,
			render = "minimal",
			icons = {
				ERROR = "",
				WARN = "",
				INFO = "",
				DEBUG = "",
				TRACE = "✎",
			},
			blend = 10,
		})

		-- Make nvim-notify the default handler
		vim.notify = notify

		-- Ensure <leader> is defined before mapping
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				vim.keymap.set("n", "<leader>un", function()
					require("notify").history({ view = "mini" })
				end, { noremap = true, silent = true, desc = "Notification history" })
			end,
		})
	end,
}
