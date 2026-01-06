local M = {}
function M.setup(user_opts)
	local config = require("cybercat.cybercat-app.chat.config")
	local sidebar = require("cybercat.cybercat-app.chat.ui.sidebar")
	local keymaps = require("cybercat.cybercat-app.chat.features.keymaps")

	-- 1. Setup user options
	config.setup(user_opts)

	-- 2. Initialize the sidebar UI
	local buf = sidebar.init()

	-- 3. Set sidebar keymaps (you can pass buf if needed)
	keymaps.set_sidebar_keymaps(buf)
end

return M
