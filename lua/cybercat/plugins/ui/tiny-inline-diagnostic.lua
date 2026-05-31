return {
	"rachartier/tiny-inline-diagnostic.nvim",
	event = "LspAttach",
	priority = 1000, -- needs to load before other diagnostic UI
	config = function()
		require("tiny-inline-diagnostic").setup({
			preset = "modern", -- "modern" | "classic" | "minimal" | "powerline" | "ghost" | "simple" | "nonerdfont" | "amongus"
			transparent_bg = false,
			options = {
				show_source = { enabled = true, if_many = true },
				use_icons_from_diagnostic = false,
				add_messages = true,
				throttle = 20,
				softwrap = 30,
				multilines = {
					enabled = true,
					always_show = false,
				},
				show_all_diags_on_cursorline = false,
				enable_on_insert = false,
				enable_on_select = false,
				overflow = { mode = "wrap" },
				break_line = { enabled = false },
				virt_texts = { priority = 2048 },
				severity = {
					vim.diagnostic.severity.ERROR,
					vim.diagnostic.severity.WARN,
					vim.diagnostic.severity.INFO,
					vim.diagnostic.severity.HINT,
				},
			},
		})
		-- the plugin owns inline rendering; native virtual_text would double-render
		vim.diagnostic.config({ virtual_text = false })
	end,
	keys = {
		{
			"<leader>td",
			function()
				require("tiny-inline-diagnostic").toggle()
			end,
			desc = "Toggle inline diagnostics",
		},
	},
}
