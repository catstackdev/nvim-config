-- return {
-- 	setup = function(config)
-- 		return {
-- 			sidebar = require("cybercat.cybercat-app.chat-app.components.sidebar").create(config.sidebar),
-- 			-- main = require("cybercat.cybercat-app.chat-app.components.main").create(config.main),
-- 			-- chatbox = require("cybercat.cybercat-app.chat-app.components.chatbox").create(config.chatbox),
-- 		}
-- 	end,
-- }
local function create_component(module, opts)
	local ok, comp = pcall(require, "cybercat.cybercat-app.chat-app.components." .. module)
	if not ok or not comp then
		vim.notify("Failed to load component: " .. module, vim.log.levels.ERROR)
		return nil
	end

	-- Handle both .create() and :new() style components
	if comp.create then
		return comp.create(opts or {})
	else
		return comp:new(opts or {})
	end
end

return {
	setup = function(config)
		config = config or {}
		local components = {
			sidebar = create_component("sidebar", config.sidebar),
		}

		-- Only add if configured
		if config.main then
			components.main = create_component("main", config.main)
		end

		if config.chatbox then
			components.chatbox = create_component("chatbox", config.chatbox)
		end

		return components
	end,
}
