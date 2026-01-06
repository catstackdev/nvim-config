local Layout = require("nui.layout")
local Popup = require("nui.popup")

local function create_ui()
	local layout = Layout(
		{
			relative = "editor",
			position = "50%",
			size = {
				width = 100,
				height = 30,
			},
		},
		Layout.Box({
			-- Top area (Box 1 + Box 2 side by side)
			Layout.Box({
				Layout.Box(
					Popup({
						border = {
							style = "rounded",
							text = { top = " Box 1 ", top_align = "center" },
						},
						win_options = {
							winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
						},
					}),
					{ grow = 3 }
				),
				Layout.Box(
					Popup({
						border = {
							style = "rounded",
							text = { top = " Box 2 (Menu) ", top_align = "center" },
						},
						win_options = {
							winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
						},
					}),
					{ grow = 1 }
				),
			}, { size = "70%" }),

			-- Bottom area (Box 3 for chat)
			Layout.Box(
				Popup({
					border = {
						style = "rounded",
						text = { top = " Chat Box ", top_align = "center" },
					},
					win_options = {
						winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
					},
				}),
				{ size = "30%" }
			),
		}, { dir = "col" })
	)

	layout:mount()

	-- Add sample content to each box
	local box1_buf = layout.children[1].children[1].popup.bufnr
	local box2_buf = layout.children[1].children[2].popup.bufnr
	local box3_buf = layout.children[2].popup.bufnr

	vim.api.nvim_buf_set_lines(box1_buf, 0, -1, false, {
		"This is Box 1: Main Content",
		"--------------------------",
		"Could show LLM context, doc, etc.",
	})

	vim.api.nvim_buf_set_lines(box2_buf, 0, -1, false, {
		"Menu",
		"- Option A",
		"- Option B",
	})

	vim.api.nvim_buf_set_lines(box3_buf, 0, -1, false, {
		"Chat starts here...",
		"CyberCat: Hello!",
	})

	-- Make Box 3 modifiable for typing/chat
	vim.bo[box3_buf].modifiable = true
end

return {
	open = create_ui,
}
