local M = {}
local state = {
	active = false,
	sessions = {},
	current_session = nil,
	initialized = false,
}

local config = require("chat.config")
local sidebar = require("chat.ui.sidebar")
local sessions = require("chat.core.sessions")
local history = require("chat.core.history.manager")
local api = require("chat.core.api.client")
local renderer = require("chat.ui.renderer")
local input = require("chat.ui.input")

function M.init()
	if state.initialized then
		return
	end

	-- Initialize components
	sidebar.init()
	sessions.init()
	input.init()

	-- Load history if enabled
	if config.options.persist_history then
		history.load()
	end

	-- Create default session
	M.new_session()

	state.initialized = true

	-- Auto-open if configured
	if config.options.auto_open then
		M.toggle()
	end
end

function M.toggle()
	if state.active then
		sidebar.close()
		state.active = false
	else
		sidebar.open()
		state.active = true
		renderer.redraw()
	end
end

function M.new_session()
	local session = sessions.create()
	table.insert(state.sessions, session)
	state.current_session = session
	return session
end

function M.send_message()
	if not state.current_session then
		return
	end

	local content = input.get_input()
	if not content or #content == 0 then
		return
	end

	-- Add user message
	sessions.add_message(state.current_session, {
		role = "user",
		content = content,
	})

	-- Get API response
	api.query({
		messages = state.current_session.messages,
		model = config.options.api.model,
		temperature = config.options.api.temperature,
	}, function(response, err)
		if err then
			sessions.add_message(state.current_session, {
				role = "system",
				content = "Error: " .. err,
			})
		else
			sessions.add_message(state.current_session, {
				role = "assistant",
				content = response,
			})
		end
		renderer.redraw()
	end)

	-- Show typing indicator
	if config.options.virtual_text then
		renderer.show_typing()
	end
end

function M.interrupt()
	api.cancel()
	if config.options.virtual_text then
		renderer.hide_typing()
	end
end

return M
