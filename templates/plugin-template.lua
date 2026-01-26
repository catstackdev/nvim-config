-- Plugin Template
-- Copy this file to create new plugin configurations
-- Location: lua/cybercat/plugins/{category}/plugin-name.lua
--
-- Categories: core, ui, editing, git, ai, languages, tools, disabled

return {
	"author/plugin-name",
	
	-- Lazy loading strategy (choose one or more)
	event = "VeryLazy",              -- Load after startup
	-- cmd = "CommandName",          -- Load on command
	-- ft = "filetype",              -- Load for specific filetype
	-- keys = "<leader>x",           -- Load on keypress
	
	-- Dependencies
	dependencies = {
		-- "other/plugin",
	},
	
	-- Plugin options (passed to setup())
	opts = {
		-- option1 = true,
		-- option2 = "value",
	},
	
	-- Advanced configuration
	config = function()
		local plugin = require("plugin-name")
		
		plugin.setup({
			-- Configuration here
		})
		
		-- Keymaps
		local keymap = vim.keymap
		-- keymap.set("n", "<leader>x", "<cmd>Command<CR>", { desc = "Description" })
	end,
	
	-- Keymaps (alternative to config function)
	-- keys = {
	-- 	{ "<leader>x", "<cmd>Command<CR>", desc = "Description" },
	-- },
}
