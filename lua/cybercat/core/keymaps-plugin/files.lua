-- File permissions and bash script execution
local keymap = vim.keymap

-- Toggle executable permission on current file, previously I had 2 keymaps, to
-- add or remove exec permissions, now it's a toggle using the same keymap
-- just do on opened file not on tree dir
keymap.set("n", "<leader>fx", function()
	local file = vim.fn.expand("%:p") -- full path of current buffer
	if file == "" or vim.fn.filereadable(file) == 0 then
		vim.notify("No file to toggle permissions", vim.log.levels.WARN)
		return
	end

	local stat = vim.loop.fs_stat(file)
	if not stat then
		vim.notify("Cannot get file status", vim.log.levels.ERROR)
		return
	end

	-- Check owner execute permission
	local is_executable = bit.band(stat.mode, 0x40) ~= 0 -- 0x40 = 0o100

	local cmd
	if is_executable then
		cmd = { "chmod", "-x", file }
	else
		cmd = { "chmod", "+x", file }
	end

	local ok = os.execute(table.concat(cmd, " "))
	if ok then
		vim.notify(
			is_executable and "Removed executable permission" or "Added executable permission",
			vim.log.levels.INFO
		)
	else
		vim.notify("Failed to toggle executable permission", vim.log.levels.ERROR)
	end
end, { desc = "Toggle executable permission" })

-- If this is a bash script, make it executable, and execute it in a tmux pane on the right
-- Using a tmux pane allows me to easily select text
-- Had to include quotes around "%" because there are some apple dirs that contain spaces, like iCloud
keymap.set("n", "<leader>cb", function()
	local file = vim.fn.expand("%:p") -- Get the current file name
	local first_line = vim.fn.getline(1) -- Get the first line of the file
	if string.match(first_line, "^#!/") then -- If first line contains shebang
		local escaped_file = vim.fn.shellescape(file) -- Properly escape the file name for shell commands
		-- Execute the script on a tmux pane on the right. On my mac I use zsh, so
		-- running this script with bash to not execute my zshrc file after
		-- vim.cmd("silent !tmux split-window -h -l 60 'bash -c \"" .. escaped_file .. "; exec bash\"'")
		-- `-l 60` specifies the size of the tmux pane, in this case 60 columns
		vim.cmd(
			"silent !tmux split-window -h -l 60 'bash -c \""
				.. escaped_file
				.. "; echo; echo Press any key to exit...; read -n 1; exit\"'"
		)
	else
		vim.cmd("echo 'Not a script. Shebang line not found.'")
	end
end, { desc = "[P]BASH, execute file" })