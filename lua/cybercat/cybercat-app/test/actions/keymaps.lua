local M = {
	defaults = {
		close = { "<Esc>", "q" },
		toggle = "<Leader>u",
		focus_next = "<Tab>",
		focus_prev = "<S-Tab>",
	},
}

function M.setup(components, config)
	config = config or {}
	for name, component in pairs(components) do
		local keymaps = vim.tbl_deep_extend("force", M.defaults, config[name] or {})
		M.register(component, keymaps)
	end
end

function M.register(component, keymaps)
	if component.popup and component.popup.map then
		for _, key in ipairs(type(keymaps.close) == "table" and keymaps.close or { keymaps.close }) do
			component.popup:map("n", key, function()
				component:hide()
			end, { noremap = true })
		end
	end
	-- Register other keymaps...
end
return M
