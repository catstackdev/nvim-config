local NuiSplit = require("nui.split")
local NuiPopup = require("nui.popup")
local event = require("nui.utils.autocmd").event

local M = {}

function M.create_ui()
	-- Left Box (Sidebar)
	local left = NuiSplit({
		relative = "editor",
		position = "left",
		size = 30,
		enter = true,
	})

	-- Right Box (Main view)
	local right = NuiSplit({
		relative = "editor",
		position = "right",
		size = "80%",
	})

	-- Bottom Chat Box
	local bottom = NuiPopup({
		relative = "editor",
		position = {
			row = "80%",
			col = "50%",
		},
		size = {
			width = "100%",
			height = 10,
		},
		anchor = "NW",
		border = {
			style = "rounded",
			text = {
				top = " Chat ",
				top_align = "left",
			},
		},
		enter = true,
		focusable = true,
	})

	left:mount()
	right:mount()
	bottom:mount()

	-- Optional: Close all on leave
	left:on(event.BufLeave, function()
		left:unmount()
	end)
	right:on(event.BufLeave, function()
		right:unmount()
	end)
	bottom:on(event.BufLeave, function()
		bottom:unmount()
	end)
end

return M
