local Base = require("nvim.lua.cybercat.cybercat-app.chat-app.lua.chat-ui.components.base")
local Split = require("nui.split")

local Sidebar = Base:new()

function Sidebar:init(opts)
	Base.init(self, opts) -- Call parent init

	self.split = Split(vim.tbl_deep_extend("force", {
		relative = "editor",
		position = "left",
		size = opts.size or 30,
		enter = opts.enter or false,
	}, opts))
end

function Sidebar:mount()
	self.split:mount()
end

function Sidebar:unmount()
	self.split:unmount()
end

-- Support both creation patterns
return {
	create = function(opts)
		return Sidebar:new(opts)
	end,

	-- Alternative style
	new = function(opts)
		return Sidebar:new(opts)
	end,
}
