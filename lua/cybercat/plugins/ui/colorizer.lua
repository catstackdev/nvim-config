return {
	"NvChad/nvim-colorizer.lua",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		filetypes = { "*", "!lazy" },
		user_default_options = {
			RGB = true,
			RRGGBB = true,
			RRGGBBAA = true,
			AARRGGBB = false,
			rgb_fn = true,
			hsl_fn = true,
			css = true,
			css_fn = true,
			tailwind = true,
			sass = { enable = true, parsers = { "css" } },
			mode = "background",
			virtualtext = "■",
			always_update = false,
		},
	},
}
