-- Debugging (nvim-dap). The setup lives in lua/cybercat/core/debug/:
--   ui.lua          dap-ui layout, signs, auto open/close
--   keymaps.lua     <leader>d* keys
--   eval_float.lua  <leader>de value popup
--   go.lua / python.lua / javascript.lua   one debugger per language
return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"nvim-neotest/nvim-nio",
			"mfussenegger/nvim-dap-python",
			"leoluz/nvim-dap-go",
			"Weissle/persistent-breakpoints.nvim",
		},
		config = function()
			-- Keymaps first: a missing debugger below must never leave them unset.
			-- Saving only: restoring is done by core/debug/breakpoint_restore.lua, because
			-- the plugin's own loader puts breakpoints of unloaded buffers on line 1.
			require("persistent-breakpoints").setup()
			require("cybercat.core.debug.breakpoint_restore").setup()
			require("cybercat.core.debug.keymaps").setup()
			require("cybercat.core.debug.ui").setup()
			require("cybercat.core.debug.go").setup()
			require("cybercat.core.debug.python").setup()
			require("cybercat.core.debug.javascript").setup()
		end,
	},
}
