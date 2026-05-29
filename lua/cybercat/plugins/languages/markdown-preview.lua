return {
	"iamcco/markdown-preview.nvim",
	keys = {
		{
			"<leader>mp",
			ft = "markdown",
			"<cmd>MarkdownPreviewToggle<cr>",
			desc = "Markdown Preview",
		},
	},
	init = function()
		vim.g.mkdp_page_title = "${name}"
		vim.g.mkdp_browser = "chromium"
		vim.g.mkdp_auto_close = 0   -- keep preview open when leaving buffer
		vim.g.mkdp_echo_preview_url = 1  -- print URL in cmdline so you know the port
	end,
}
