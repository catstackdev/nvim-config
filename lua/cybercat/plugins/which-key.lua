return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	opts = {},
	-- opts = function()
	-- 	local wk = require("which-key")
	-- 	wk.register({
	-- 		-- Normal mode mappings
	-- 		["<leader>t"] = { name = "[P]todo" },
	-- 		["<leader>m"] = { name = "[P]markdown" },
	-- 		["<leader>mf"] = { name = "[P]fold" },
	-- 		["<leader>mh"] = { name = "[P]headings increase/decrease" },
	-- 		["<leader>ml"] = { name = "[P]links" },
	-- 		["<leader>ms"] = { name = "[P]spell" },
	-- 		["<leader>msl"] = { name = "[P]language" },
	-- 	}, { mode = "n" })
	--
	-- 	-- Visual mode mappings (if needed)
	-- 	wk.register({
	-- 		["<leader>m"] = { name = "[P]markdown" },
	-- 		["<leader>mf"] = { name = "[P]fold" },
	-- 	}, { mode = "v" })
	-- end,
	-- opts = {
	-- 	preset = "modern", -- Use the modern preset for a cleaner, more visually appealing popup style
	-- 	delay = 200, -- Set a consistent delay for popup appearance (overrides the function for simplicity)
	-- 	plugins = {
	-- 		marks = true,
	-- 		registers = true,
	-- 		spelling = { enabled = true, suggestions = 20 },
	-- 		presets = {
	-- 			operators = true,
	-- 			motions = true,
	-- 			text_objects = true,
	-- 			windows = true,
	-- 			nav = true,
	-- 			z = true,
	-- 			g = true,
	-- 		},
	-- 	},
	-- 	win = {
	-- 		no_overlap = true,
	-- 		border = "single", -- Add a border for better visual separation
	-- 		padding = { 2, 2 }, -- Increase padding for readability
	-- 		title = true,
	-- 		title_pos = "center",
	-- 		zindex = 1000,
	-- 		-- winblend =10,
	-- 		wo = {
	-- 			winblend = 20, -- Add slight transparency for a modern look
	-- 		},
	-- 	},
	-- 	layout = {
	-- 		width = { min = 20, max = 50 }, -- Set min/max width for columns to handle longer descriptions
	-- 		spacing = 4, -- Slightly more spacing between columns for clarity
	-- 	},
	-- 	sort = { "local", "order", "group", "alphanum", "mod" }, -- Customize sorting to prioritize local mappings
	-- 	notify = true, -- Keep notifications for mapping issues
	-- 	-- Add icons for better visual cues (assuming default or common setup)
	-- 	icons = {
	-- 		breadcrumb = "»",
	-- 		separator = " ➜ ",
	-- 		group = "+ ",
	-- 	},
	-- 	show_help = true, -- Show help keys in the popup
	-- 	show_keys = true, -- Show the current keys pressed
	-- },
	--
}
