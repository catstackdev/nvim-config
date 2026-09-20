-- ~/.config/nvim/lua/cybercat/plugins/debug2.lua
return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"nvim-neotest/nvim-nio",
			"mfussenegger/nvim-dap-python",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- Setup UI
			dapui.setup()

			-- Virtual text
			require("nvim-dap-virtual-text").setup({
				enabled = true,
			})

			-- Auto open/close UI
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Python: mirror after/lsp/pyright.lua's interpreter resolution so
			-- breakpoints run against the same venv the LSP already uses.
			local function resolve_python(workspace)
				workspace = workspace or vim.fn.getcwd()
				if vim.fn.executable(workspace .. "/.venv/bin/python") == 1 then
					return workspace .. "/.venv/bin/python"
				end
				if vim.fn.executable(workspace .. "/venv/bin/python") == 1 then
					return workspace .. "/venv/bin/python"
				end
				if vim.env.VIRTUAL_ENV then
					return vim.env.VIRTUAL_ENV .. "/bin/python"
				end
				local python3 = vim.fn.exepath("python3")
				return python3 ~= "" and python3 or vim.fn.exepath("python")
			end

			local mason_path = vim.fn.stdpath("data") .. "/mason/packages"
			local debugpy_python = mason_path .. "/debugpy/venv/bin/python"

			if vim.fn.executable(debugpy_python) == 1 then
				local dap_python = require("dap-python")
				dap_python.setup(debugpy_python)
				dap_python.resolve_python = function()
					return resolve_python(vim.fn.getcwd())
				end
			else
				vim.notify("debugpy not found! Run :Mason to install", vim.log.levels.WARN)
			end

			-- Path to js-debug-adapter
			local js_debug_path = mason_path .. "/js-debug-adapter"

			-- Check if exists
			if vim.fn.isdirectory(js_debug_path) == 0 then
				vim.notify("js-debug-adapter not found! Run :Mason to install", vim.log.levels.WARN)
				return
			end

			-- Setup adapters
			dap.adapters["pwa-node"] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "node",
					args = {
						js_debug_path .. "/js-debug/src/dapDebugServer.js",
						"${port}",
					},
				},
			}

			dap.adapters["pwa-chrome"] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "node",
					args = {
						js_debug_path .. "/js-debug/src/dapDebugServer.js",
						"${port}",
					},
				},
			}

			-- Resolve a Chrome/Chromium executable without hardcoding one
			-- machine's install location; nil lets js-debug use its own default.
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

			-- Configurations
			for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
				dap.configurations[language] = {
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

			-- Keymaps
			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
			vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Debug: Open REPL" })
			vim.keymap.set("n", "<leader>dt", dapui.toggle, { desc = "Debug: Toggle UI" })

			-- Breakpoint signs
			vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "", linehl = "", numhl = "" })
			vim.fn.sign_define("DapStopped", { text = "→", texthl = "", linehl = "debugPC", numhl = "" })
		end,
	},
}
