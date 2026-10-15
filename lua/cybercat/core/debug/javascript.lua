-- JavaScript / TypeScript: Mason's js-debug-adapter (browser launch/attach, Node).
local M = {}

local LANGUAGES = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

--- Resolve a Chrome/Chromium executable without hardcoding one machine's install
--- location; nil lets js-debug use its own default.
---@return string?
local function resolve_browser()
	for _, candidate in ipairs({
		"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
		"/Applications/Chromium.app/Contents/MacOS/Chromium",
		"chromium",
		"google-chrome",
	}) do
		if vim.fn.executable(candidate) == 1 then
			return candidate
		end
	end
	return nil
end

---@param js_debug_path string
---@return table
local function server_adapter(js_debug_path)
	return {
		type = "server",
		host = "localhost",
		port = "${port}",
		executable = {
			command = "node",
			args = { js_debug_path .. "/js-debug/src/dapDebugServer.js", "${port}" },
		},
	}
end

---@return table[]
local function configurations()
	return {
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Launch browser (prompts for dev server port)",
			url = function()
				local port = vim.fn.input("Dev server port: ")
				return "http://localhost:" .. port
			end,
			webRoot = "${workspaceFolder}",
			runtimeExecutable = resolve_browser(),
			runtimeArgs = {
				"--remote-debugging-port=9222",
				"--user-data-dir=${workspaceFolder}/.chromium-debug",
			},
			sourceMaps = true,
			protocol = "inspector",
			port = 9222,
			sourceMapPathOverrides = {
				["webpack:///./src/*"] = "${webRoot}/src/*",
				["webpack:///src/*"] = "${webRoot}/src/*",
				["webpack:///./*"] = "${webRoot}/*",
			},
		},
		{
			type = "pwa-chrome",
			request = "attach",
			name = "Attach to Chromium",
			port = 9222,
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
		},
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch Node File",
			program = "${file}",
			cwd = "${workspaceFolder}",
			sourceMaps = true,
		},
	}
end

function M.setup()
	local js_debug_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"
	if vim.fn.isdirectory(js_debug_path) == 0 then
		vim.notify("js-debug-adapter not found! Run :Mason to install", vim.log.levels.WARN)
		return
	end

	local dap = require("dap")
	dap.adapters["pwa-node"] = server_adapter(js_debug_path)
	dap.adapters["pwa-chrome"] = server_adapter(js_debug_path)
	for _, language in ipairs(LANGUAGES) do
		dap.configurations[language] = configurations()
	end
end

return M
