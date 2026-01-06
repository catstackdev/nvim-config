return {
	"lukas-reineke/indent-blankline.nvim",
	event = { "BufReadPre", "BufNewFile" },
	main = "ibl",
	opts = {
		-- indent = { char = "┊" },
		indent = {
			char = "┊", -- main indent char
			tab_char = "│", -- for tabs, a bit thicker
			smart_indent_cap = true, -- avoids drawing indent guides after end of file
			-- show_trailing_blankline_indent = false, -- optional: hide indent on blank lines at EOF
		},

		-- highlight = {
		-- 	"IblIndent",
		-- 	"IblIndentAbove",
		-- 	"IblIndentBelow",
		-- 	"IblIndentScope",
		-- },
	},
}
