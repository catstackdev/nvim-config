local Base = require("nvim.lua.cybercat.cybercat-app.chat-app.lua.chat-ui.components.base")
local Split = require("nui.split")

local Main = Base:new()

function Main:init(opts)
	Base.init(self, opts)
	self.split = Split(vim.tbl_deep_extend("force", {
		relative = "editor",
		position = "right",
		size = "80%",
		enter = true,
	}, self.opts))
end

-- ... same mount/unmount methods as sidebar ...

return {
	create = function(opts)
		return Main:new(opts)
	end,
}
