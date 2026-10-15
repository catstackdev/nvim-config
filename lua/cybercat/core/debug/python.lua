-- Python: debugpy from Mason, run against the same venv the LSP uses.
local M = {}

--- Mirrors after/lsp/pyright.lua's interpreter resolution so breakpoints run
--- against the same venv the LSP already uses.
---@param workspace string?
---@return string
local function resolve_python(workspace)
	workspace = workspace or vim.fn.getcwd()
	for _, venv in ipairs({ "/.venv/bin/python", "/venv/bin/python" }) do
		if vim.fn.executable(workspace .. venv) == 1 then
			return workspace .. venv
		end
	end
	if vim.env.VIRTUAL_ENV then
		return vim.env.VIRTUAL_ENV .. "/bin/python"
	end
	local python3 = vim.fn.exepath("python3")
	return python3 ~= "" and python3 or vim.fn.exepath("python")
end

function M.setup()
	local debugpy_python = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
	if vim.fn.executable(debugpy_python) ~= 1 then
		vim.notify("debugpy not found! Run :Mason to install", vim.log.levels.WARN)
		return
	end

	local dap_python = require("dap-python")
	dap_python.setup(debugpy_python)
	dap_python.resolve_python = function()
		return resolve_python(vim.fn.getcwd())
	end
end

return M
