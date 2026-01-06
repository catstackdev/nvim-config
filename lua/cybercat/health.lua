local M = {}

M.check = function()
	vim.health.start("Cybercat Configuration")

	-- Check critical dependencies
	if vim.fn.executable("rg") == 1 then
		vim.health.ok("ripgrep installed")
	else
		vim.health.error("ripgrep not found")
	end

	-- Check mode
	if vim.g.neovim_mode then
		vim.health.ok("Running in " .. vim.g.neovim_mode .. " mode")
	end
end

return M
