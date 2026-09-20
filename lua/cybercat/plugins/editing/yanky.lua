return { -- yank-ring: cycle through yank history instead of losing it to the next delete
	"gbprod/yanky.nvim",
	dependencies = {
		{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
	},
	event = { "BufReadPre", "BufNewFile" },
	opts = {

		highlight = {
			on_put = true,
			on_yank = true,
			timer = 300,
		},
		-- ring = {
		-- 	history_length = 100,
		-- 	storage = "shada",
		-- 	sync_with_numbered_registers = true,
		-- 	cancel_event = "update",
		-- 	ignore_registers = { "_" },
		-- 	update_register_on_cycle = false,
		-- 	permanent_wrapper = nil,
		-- },
		system_clipboard = {
			sync_with_ring = true,
		},
	},
	config = function(_, opts)
		require("yanky").setup(opts)
		require("telescope").load_extension("yank_history")
		-- Yank flash color
		vim.api.nvim_set_hl(0, "YankyYanked", {
			bg = "#3b7b9a",
			fg = "#bbfbba",
		})

		vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)", { desc = "Yank (ring)" })
		vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Put after (ring)" })
		vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Put before (ring)" })
		vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Put after, leave cursor (ring)" })
		vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Put before, leave cursor (ring)" })
		vim.keymap.set("n", "<c-p>", "<Plug>(YankyPreviousEntry)", { desc = "Previous yank entry" })
		vim.keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)", { desc = "Next yank entry" })
		-- vim.keymap.set("n", "<leader>y", "<cmd>YankyRingHistory<cr>", { desc = "Yank ring history" })
	end,
}
