local keymaps = require("cybercat.cybercat-app.chat-app.actions.keymaps")
local commands = require("cybercat.cybercat-app.chat-app.actions.commands")

return {
	setup = function(config, components)
		keymaps.setup(components, config.keymaps)
		commands.setup(components, config.commands)
	end,
}
