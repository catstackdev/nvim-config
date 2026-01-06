local Base = require("nvim.lua.cybercat.cybercat-app.chat-app.lua.chat-ui.components.base")
local Popup = require("nui.popup")

local Chatbox = Base:new()

function Chatbox:init(opts)
	Base.init(self, opts)
	self.popup = Popup(vim.tbl_deep_extend("force", {
		relative = "editor",
		position = { row = "80%", col = "50%" },
		size = { width = "100%", height = 10 },
		border = { style = "rounded" },
		enter = true,
	}, self.opts))
end

-- ... mount/unmount methods ...

return {
	create = function(opts)
		return Chatbox:new(opts)
	end,
}
