-- nvim-cmp source: variable names in scope at the current debugger stop.
-- Fills the gap for adapters without DAP "completions" support (e.g. Delve):
-- it asks the paused session for its scopes and variables, like the Scopes panel.
local cmp = require("cmp")

---@class DapVariablesSource
local source = {}

---@return DapVariablesSource
function source.new()
	return setmetatable({}, { __index = source })
end

function source:get_debug_name()
	return "dap_variables"
end

---@return boolean
function source:is_available()
	local session = require("dap").session()
	return session ~= nil and session.current_frame ~= nil
end

---@param _ any
---@param callback fun(items: table[])
function source:complete(_, callback)
	local session = require("dap").session()
	local frame = session and session.current_frame
	if not frame then
		return callback({})
	end

	local items, seen = {}, {}
	local function finish()
		vim.schedule(function()
			callback(items)
		end)
	end

	session:request("scopes", { frameId = frame.id }, function(scopes_err, scopes_response)
		local scopes = {}
		for _, scope in ipairs(not scopes_err and scopes_response and scopes_response.scopes or {}) do
			if not scope.expensive then
				scopes[#scopes + 1] = scope
			end
		end
		local pending = #scopes
		if pending == 0 then
			return finish()
		end

		for _, scope in ipairs(scopes) do
			session:request("variables", { variablesReference = scope.variablesReference }, function(err, response)
				for _, variable in ipairs(not err and response and response.variables or {}) do
					if not seen[variable.name] then
						seen[variable.name] = true
						items[#items + 1] = {
							label = variable.name,
							kind = cmp.lsp.CompletionItemKind.Variable,
							detail = variable.type,
							documentation = variable.value,
						}
					end
				end
				pending = pending - 1
				if pending == 0 then
					finish()
				end
			end)
		end
	end)
end

return source
