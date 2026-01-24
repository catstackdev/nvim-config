-- Auto-start Neovim server for Claude CLI integration
-- This makes nvim auto-connect to Claude without needing vim-claude command

local M = {}

function M.setup()
	print("🔥 DEBUG: auto-session.lua")
	-- Only in Neovim (not Neovide or other GUIs)
	if not vim.fn.has("nvim") or vim.g.neovide then
		return
	end
	--console
	print("🔥 DEBUG2: auto-session.lua")

	-- Auto-start server on VimEnter
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			local pid = vim.fn.getpid()
			local cwd = vim.fn.getcwd()

			-- Use a hash of the full path to make it unique per directory
			-- This prevents multiple "nvim" or "src" folders from colliding
			local dir_hash = vim.fn.sha256(cwd):sub(1, 8)
			local dir_name = vim.fn.fnamemodify(cwd, ":t")

			-- New Format: /tmp/nvim-claude-[dirname]-[hash]-[pid].sock
			local socket = string.format("/tmp/nvim-claude-%s-%s-%d.sock", dir_name, dir_hash, pid)

			-- Remove the servername == "" check so it ALWAYS starts
			vim.fn.delete(socket)
			local ok = pcall(vim.fn.serverstart, socket)
			if ok then
				vim.g.claude_socket = socket
				print("🚀 Claude Server: " .. socket)
			end
		end,
	})

	-- Clean up socket on exit
	-- vim.api.nvim_create_autocmd("VimLeavePre", {
	-- 	callback = function()
	-- 		if vim.g.claude_socket then
	-- 			vim.fn.delete(vim.g.claude_socket)
	-- 		end
	-- 	end,
	-- })

	-- Add command to show socket info
	vim.api.nvim_create_user_command("ClaudeSocket", function()
		local socket = vim.v.servername
		if socket and socket ~= "" then
			print("Claude socket: " .. socket)
			print("Connect with: export NVIM_LISTEN_ADDRESS=" .. socket)
			print("Or just: ci (Claude will auto-detect)")
		else
			print("No socket active. Server not started.")
		end
	end, { desc = "Show Claude socket information" })

	-- Add command to restart socket
	vim.api.nvim_create_user_command("ClaudeSocketRestart", function()
		local cwd = vim.fn.getcwd()
		local socket_name = cwd:gsub("/", "-"):gsub("^-", "")
		local socket = string.format("/tmp/nvim-claude-%s.sock", socket_name)

		vim.fn.serverstart(socket)
		vim.g.claude_socket = socket
		print("Claude socket restarted: " .. socket)
	end, { desc = "Restart Claude socket" })
end

return M
