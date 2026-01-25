return { -- nicer-looking tabs with close icons
	"nanozuki/tabby.nvim",
	enabled = false,
	config = function()
		require("tabby.tabline").use_preset("tab_only")
	end,
}
