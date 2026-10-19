-- Auto-step (<leader>dN): step over once a second while the program is paused.
-- It ends itself when it lands on a breakpoint (a conditional one only when its
-- condition is true), on q / Esc, or when the session goes away.
local M = {}

local INTERVAL_MS = 1000
local STOP_KEYS = { "q", "<Esc>" }
local LISTENER_KEY = "cybercat_auto_step"

local timer ---@type uv.uv_timer_t?
local busy = false
local first_tick = true

function M.is_running()
	return timer ~= nil
end

function M.stop()
	if not timer then
		return
	end
	timer:stop()
	timer:close()
	timer = nil
	busy = false
	for _, key in ipairs(STOP_KEYS) do
		pcall(vim.keymap.del, "n", key)
	end
	require("dap").listeners.after.event_stopped[LISTENER_KEY] = nil
	vim.notify("Auto-step off", vim.log.levels.INFO)
end

--- The breakpoint set on the line the session is paused at, if any.
---@param frame dap.StackFrame
---@return table?
local function breakpoint_at(frame)
	local path = frame.source and frame.source.path
	if not path then
		return nil
	end
	local bufnr = vim.fn.bufnr(path)
	local in_buffer = require("dap.breakpoints").get(bufnr)[bufnr] or {}
	for _, bp in ipairs(in_buffer) do
		if bp.line == frame.line then
			return bp
		end
	end
end

--- Decide whether a breakpoint on the current line should end auto-step.
---@param session dap.Session
---@param frame dap.StackFrame
---@param on_result fun(should_stop: boolean)
local function should_stop_at_breakpoint(session, frame, on_result)
	local bp = breakpoint_at(frame)
	if not bp then
		return on_result(false)
	end
	if bp.condition and bp.condition ~= "" then
		session:evaluate({ expression = bp.condition, context = "watch", frameId = frame.id }, function(err, response)
			on_result(not err and response ~= nil and response.result == "true")
		end)
		return
	end
	-- a logpoint only prints; a plain breakpoint is a place to look
	on_result(not (bp.logMessage and bp.logMessage ~= ""))
end

local function tick()
	local dap = require("dap")
	local session = dap.session()
	if not session then
		return M.stop()
	end
	-- only while paused: a step issued mid-run would be rejected by the adapter
	if busy or not session.stopped_thread_id then
		return
	end
	local frame = session.current_frame
	if first_tick or not frame then
		first_tick = false
		return require("cybercat.core.debug.step_guard").step_over()
	end
	busy = true
	should_stop_at_breakpoint(session, frame, function(should_stop)
		busy = false
		if not timer then
			return
		end
		if should_stop then
			M.stop()
		else
			require("cybercat.core.debug.step_guard").step_over()
		end
	end)
end

--- Step over repeatedly. Toggle again (or stop the session) to end it.
function M.toggle()
	if timer then
		return M.stop()
	end
	local dap = require("dap")
	if not dap.session() then
		return vim.notify("Auto-step: no debug session", vim.log.levels.WARN)
	end
	first_tick = true
	busy = false
	timer = vim.uv.new_timer()
	timer:start(INTERVAL_MS, INTERVAL_MS, vim.schedule_wrap(tick))
	-- the adapter itself reported a breakpoint stop (e.g. a condition that became true)
	dap.listeners.after.event_stopped[LISTENER_KEY] = function(_, body)
		if body.reason == "breakpoint" then
			vim.schedule(M.stop)
		end
	end
	for _, key in ipairs(STOP_KEYS) do
		vim.keymap.set("n", key, M.stop, { desc = "Debug: stop auto-step" })
	end
	vim.notify(("Auto-step on (every %dms) - q/Esc to stop"):format(INTERVAL_MS), vim.log.levels.INFO)
end

return M
