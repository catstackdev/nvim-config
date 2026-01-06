local M = {}
local state = {
	sessions = {},
	current = nil,
}

local config = require("chat.config")
local utils = require("chat.core.utils")

function M.init()
	-- Load any persisted sessions
	if config.options.persist_history then
		-- Implementation would load from disk
	end

	-- Create default session if none exists
	if #state.sessions == 0 then
		M.create()
	end
end

function M.create(opts)
	opts = opts or {}
	local session = {
		id = utils.uuid(),
		created_at = os.time(),
		updated_at = os.time(),
		title = opts.title or "New Chat",
		messages = {},
		metadata = opts.metadata or {},
	}

	table.insert(state.sessions, session)
	state.current = session
	return session
end

function M.add_message(session, message)
	if not session then
		return
	end

	message = {
		id = utils.uuid(),
		timestamp = os.time(),
		role = message.role,
		content = message.content,
	}

	table.insert(session.messages, message)
	session.updated_at = os.time()

	-- Auto-generate title if first message
	if #session.messages == 1 then
		session.title = utils.generate_title(message.content)
	end
end

function M.get_messages(session, opts)
	opts = opts or {}
	local messages = {}

	for _, msg in ipairs(session.messages) do
		if not opts.filter or opts.filter(msg) then
			table.insert(messages, msg)
		end
	end

	return messages
end

function M.export(session, format)
	-- Implement export to different formats
	-- (JSON, Markdown, etc.)
end

return M
