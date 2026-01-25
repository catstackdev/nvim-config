-- Terminal management utilities for HTTP/Hurl testing
-- Handles terminal creation, keymaps, and cleanup

local M = {}

--- Default terminal options
M.default_opts = {
	position = "split", -- "split", "vsplit", "tabnew"
	size = nil, -- nil for default size
	close_on_exit = false,
}

--- Run command in terminal split
--- @param cmd string Command to run
--- @param opts table|nil Terminal options
function M.run_in_terminal(cmd, opts)
	opts = vim.tbl_extend("force", M.default_opts, opts or {})
	
	local term_cmd = opts.position
	if term_cmd == "split" then
		vim.cmd("split")
	elseif term_cmd == "vsplit" then
		vim.cmd("vsplit")
	elseif term_cmd == "tabnew" then
		vim.cmd("tabnew")
	end
	
	vim.cmd("terminal " .. cmd)
	
	-- Enter insert mode in terminal
	vim.cmd("startinsert")
end

--- Setup terminal keymaps for HTTP testing
--- Adds 'q' to close, <Esc> to exit insert mode, etc.
function M.setup_terminal_keymaps()
	-- Close terminal with 'q' when in normal mode
	vim.api.nvim_create_autocmd("TermOpen", {
		pattern = "term://*hurl*,term://*curl*",
		callback = function()
			local buf = vim.api.nvim_get_current_buf()
			vim.keymap.set("n", "q", "<cmd>close<CR>", { 
				buffer = buf, 
				silent = true,
				desc = "Close terminal" 
			})
			vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { 
				buffer = buf, 
				silent = true,
				desc = "Close terminal" 
			})
		end,
	})
end

--- Run command and capture output in split
--- @param cmd string Command to run
--- @param callback function|nil Optional callback when command completes
function M.run_and_show(cmd, callback)
	M.run_in_terminal(cmd, { position = "split" })
	
	if callback then
		vim.api.nvim_create_autocmd("TermClose", {
			once = true,
			callback = callback,
		})
	end
end

--- Check if a command exists
--- @param command string Command name to check
--- @return boolean exists True if command exists
function M.command_exists(command)
	return vim.fn.executable(command) == 1
end

--- Validate required commands are installed
--- @param commands table List of required commands
--- @return boolean valid True if all commands exist
--- @return string|nil missing Name of first missing command
function M.validate_commands(commands)
	for _, cmd in ipairs(commands) do
		if not M.command_exists(cmd) then
			return false, cmd
		end
	end
	return true, nil
end

--- Show notification if command is missing
--- @param command string Missing command name
--- @param install_hint string|nil Installation hint
function M.notify_missing_command(command, install_hint)
	local msg = string.format("Command '%s' not found", command)
	if install_hint then
		msg = msg .. "\nInstall with: " .. install_hint
	end
	vim.notify(msg, vim.log.levels.ERROR)
end

return M
