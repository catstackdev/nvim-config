return { -- dim inactive windows (levouh/tint.nvim is archived; this is the maintained equivalent)
	"tadaa/vimade",
	enabled = false,
	event = "VeryLazy",
	opts = {
		recipe = { "default", { animate = true } },
		-- active colorscheme (tokyonight, colorscheme.lua) sets transparent = true;
		-- vimade needs the real bg to compute fade colors when Neovim reports none
		basebg = "#011628",
		fadelevel = 0.9,
	},
}
