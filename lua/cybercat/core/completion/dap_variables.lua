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

function source:get_trigger_characters()
	return { "." }
end

---@param variable table  a DAP Variable
---@return table item
local function to_item(variable)
	return {
		label = variable.name,
		kind = cmp.lsp.CompletionItemKind.Variable,
		detail = variable.type,
		documentation = variable.value,
	}
end

--- Children of a variable reference (struct fields, slice elements).
---@param session table
---@param reference integer
---@param callback fun(variables: table[])
local function fetch_children(session, reference, callback)
	session:request("variables", { variablesReference = reference }, function(err, response)
		callback(not err and response and response.variables or {})
	end)
end

--- Fields of `base` (e.g. "tt" or "tt.inner"). Delve shows a pointer as one child
--- named after the pointee, so for a single child we look one level deeper.
---@param session table
---@param base string
---@param callback fun(items: table[])
local function complete_members(session, base, callback)
	local args = { expression = base, frameId = session.current_frame.id, context = "watch" }
	session:request("evaluate", args, function(err, response)
		local reference = not err and response and response.variablesReference or 0
		if reference == 0 then
			return callback({})
		end
		fetch_children(session, reference, function(children)
			if #children == 1 and children[1].variablesReference and children[1].variablesReference > 0 then
				return fetch_children(session, children[1].variablesReference, function(fields)
					callback(vim.tbl_map(to_item, fields))
				end)
			end
			callback(vim.tbl_map(to_item, children))
		end)
	end)
end

---@param params table  nvim-cmp completion params
---@param callback fun(items: table[])
function source:complete(params, callback)
	local session = require("dap").session()
	local frame = session and session.current_frame
	if not frame then
		return callback({})
	end

	-- "tt.a|" -> complete the fields of tt instead of the names in scope.
	local base = params.context.cursor_before_line:match("([%w_%.%[%]]+)%.[%w_]*$")
	if base then
		return complete_members(session, base, function(items)
			vim.schedule(function()
				callback(items)
			end)
		end)
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
