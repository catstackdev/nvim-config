return { -- render SVG/Markdown/HTML in the browser with live updates
	"brianhuster/live-preview.nvim",
	cmd = "LivePreview",
	keys = {
		{
			"<leader>lp",
			function()
				if require("livepreview").is_running() then
					vim.cmd("LivePreview close")
				else
					vim.cmd("LivePreview start")
				end
			end,
			-- shadowed by webgpu_inspect's buffer-local <leader>ip (palette) in wgsl/glsl/ts
			-- buffers; buffer-local mappings win there, so no real collision
			desc = "Toggle browser preview (svg/md/html)",
		},
		{
			"<leader>lP",
			"<cmd>LivePreview pick<cr>",
			-- recursively lists every md/html/svg/adoc file under the cwd (no depth
			-- limit) via telescope, then opens the picked one in the browser
			desc = "Pick a file (recursive) to browser-preview",
		},
	},
	opts = {
		sync_scroll = true,
		browser = "chromium",
	},
	config = function(_, opts)
		require("livepreview.config").set(opts)
	end,
}
