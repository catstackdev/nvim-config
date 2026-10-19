-- Step mode: press the key once, then tap n/i/o/c as often as you like.
-- Same idea as resize.lua: a small key loop, so no <leader>d prefix per step.
local M = {}

local HELP = "-- STEP --  n: next   i: into   o: out   c: continue   g: go to cursor   e: eval   q/Esc: done   (other keys move the cursor)"

-- Keys that start a multi-key command (zz, 5j, <C-w>w, ...): read one more key.
local PREFIX_KEYS = { z = true, ["["] = true, ["]"] = true, ['"'] = true, ["'"] = true, ["`"] = true, m = true }
local CTRL_W = vim.keycode("<C-w>")

---@param key string
---@return boolean
local function starts_sequence(key)
	return PREFIX_KEYS[key] or key == CTRL_W or key:match("^%d$") ~= nil
end

--- Run a key (or short sequence) as a normal-mode command, e.g. j, <C-d>, gg.
---@param keys string
local function pass_through(keys)
	vim.api.nvim_feedkeys(keys, "nx", false)
end

---@return table<string, fun()>
local function actions()
	local dap = require("dap")
	return {
		n = require("cybercat.core.debug.step_guard").step_over,
		i = dap.step_into,
		o = dap.step_out,
		c = dap.continue,
		g = dap.run_to_cursor,
		e = require("cybercat.core.debug.eval_float").show,
	}
end

function M.start()
	if not require("dap").session() then
		return vim.notify("Step mode: no debug session", vim.log.levels.WARN)
	end
	local by_key = actions()
	while true do
		vim.api.nvim_echo({ { HELP, "ModeMsg" } }, false, {})
		vim.cmd("redraw")
		local ok, key = pcall(vim.fn.getcharstr)
		if not ok or key == "q" or key == vim.keycode("<Esc>") or key == vim.keycode("<CR>") then
			break
		end
		local action = by_key[key]
		if action then
			action()
		else
			while starts_sequence(key) do
				local more_ok, more = pcall(vim.fn.getcharstr)
				if not more_ok or more == vim.keycode("<Esc>") then
					key = ""
					break
				end
				key = key .. more
				if not (more:match("^%d$")) then
					break
				end
			end
			if key ~= "" then
				pass_through(key)
			end
		end
	end
	vim.api.nvim_echo({ { "" } }, false, {})
	vim.cmd("redraw")
end

return M
