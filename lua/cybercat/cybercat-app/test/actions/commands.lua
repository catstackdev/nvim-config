local M = {}

function M.setup(components, config)
	vim.api.nvim_create_user_command("MyUIToggleSidebar", function()
		if components.sidebar then
			components.sidebar:toggle()
		else
			vim.notify("Sidebar component not initialized", vim.log.levels.ERROR)
		end
	end, {})

	-- Add other commands...
end

return M
