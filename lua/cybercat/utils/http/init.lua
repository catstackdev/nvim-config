-- HTTP/Hurl testing utilities
-- Main entry point for all HTTP-related utilities

local M = {}

-- Load sub-modules
M.env = require("cybercat.utils.http.env")
M.terminal = require("cybercat.utils.http.terminal")
M.commands = require("cybercat.utils.http.commands")

--- Run hurl file in terminal
--- @param opts table|nil Options: { test = bool, verbose = bool }
function M.run_hurl_file(opts)
	-- Validate hurl is installed
	if not M.terminal.command_exists("hurl") then
		M.terminal.notify_missing_command("hurl", "brew install hurl")
		return
	end
	
	local cmd = M.commands.run_hurl_file(opts)
	M.terminal.run_in_terminal(cmd, { position = "split" })
end

--- Run hurl request at cursor position
function M.run_hurl_at_cursor()
	-- Validate hurl is installed
	if not M.terminal.command_exists("hurl") then
		M.terminal.notify_missing_command("hurl", "brew install hurl")
		return
	end
	
	local cmd = M.commands.run_hurl_at_cursor()
	M.terminal.run_in_terminal(cmd, { position = "split" })
end

--- Run hurl file in test mode
--- @param verbose boolean|nil Whether to show verbose output
function M.test_hurl_file(verbose)
	-- Validate hurl is installed
	if not M.terminal.command_exists("hurl") then
		M.terminal.notify_missing_command("hurl", "brew install hurl")
		return
	end
	
	local cmd = M.commands.test_hurl_file(verbose)
	M.terminal.run_in_terminal(cmd, { position = "split" })
end

--- Setup all HTTP testing utilities
--- Call this in your config to initialize terminal keymaps, etc.
function M.setup()
	-- Setup terminal keymaps
	M.terminal.setup_terminal_keymaps()
	
	-- Check for required commands
	local required = { "curl" }
	local valid, missing = M.terminal.validate_commands(required)
	if not valid then
		vim.notify(
			string.format("Warning: '%s' not found. Some features may not work.", missing),
			vim.log.levels.WARN
		)
	end
end

return M
