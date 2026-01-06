local M = {
	_ready = false,
}

function M.setup()
	if M._ready then
		return
	end

	-- Load components with dependency injection
	local check = require("cybercat.core.llm.check")
	local api = require("cybercat.core.llm.api")
	local ui = require("cybercat.core.llm.ui")

	-- Inject dependencies
	api.inject_ui(ui)
	ui.inject_api(api)

	-- Initialize with health check
	check.verify(function(success)
		if success then
			ui.init()
			api.init()
			M._ready = true
			vim.notify("LLM Chat ready! Use <leader>lc to open", vim.log.levels.INFO)
		else
			vim.notify("LLM Chat disabled - Ollama not running", vim.log.levels.ERROR)
		end
	end)

	-- Keymaps
	vim.keymap.set("n", "<leader>lc", function()
		if ui.is_open() then
			ui.close()
		elseif M._ready then
			ui.open()
		else
			vim.notify("LLM system not ready - check Ollama", vim.log.levels.WARN)
		end
	end, { desc = "Toggle LLM Chat" })
end

return M
