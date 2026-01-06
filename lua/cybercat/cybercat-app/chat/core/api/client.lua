local M = {}
local config = require("chat.config")
local utils = require("chat.core.utils")
local providers = {
	openai = require("chat.core.api.providers.openai"),
	ollama = require("chat.core.api.providers.ollama"),
	custom = require("chat.core.api.providers.custom"),
}

local state = {
	current_request = nil,
	cancelled = false,
}

function M.query(params, callback)
	if state.current_request then
		vim.notify("Already processing a request", vim.log.levels.WARN)
		return
	end

	state.cancelled = false
	local provider = providers[config.options.api.provider]
	if not provider then
		callback(nil, "No provider configured")
		return
	end

	-- Prepare messages (respect context window)
	local messages = utils.trim_messages(params.messages, config.options.api.context_window)

	-- Start request
	state.current_request = provider.query({
		messages = messages,
		model = params.model,
		temperature = params.temperature,
		stream = true, -- Enable streaming
	}, function(response, err, done)
		if state.cancelled then
			return
		end

		if err then
			callback(nil, err)
		elseif response then
			callback(response, nil, done)
		end

		if done then
			state.current_request = nil
		end
	end)
end

function M.cancel()
	if state.current_request then
		if state.current_request.cancel then
			state.current_request.cancel()
		end
		state.cancelled = true
		state.current_request = nil
	end
end

-- Health check for providers
function M.check_health(callback)
	local provider = providers[config.options.api.provider]
	if provider and provider.health_check then
		provider.health_check(callback)
	else
		callback(false, "No health check available")
	end
end

return M
