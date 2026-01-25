return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	config = function()
		require("claudecode").setup({
			-- Terminal configuration via Snacks.nvim
			terminal = {
				win = {
					position = "bottom",
					height = 0.4, -- 40% of screen height
					border = "rounded",
				},
				-- Auto-enter insert mode when opening
				enter_insert = true,
			},
			-- Model selection (optional - defaults to Sonnet)
			-- model = "sonnet", -- Options: "sonnet", "opus", "haiku"
			-- Auto-save before sending commands
			auto_save = true,
			-- File watching for external changes
			watch_files = true,
		})

		-- Autocmds for enhanced integration
		local group = vim.api.nvim_create_augroup("ClaudeCode", { clear = true })

		-- Auto-accept diffs with confirmation
		vim.api.nvim_create_autocmd("User", {
			pattern = "ClaudeCodeDiffReady",
			group = group,
			callback = function()
				vim.notify("Claude Code diff ready - <leader>cla to accept, <leader>cld to deny", vim.log.levels.INFO)
			end,
		})

		-- Highlight Claude Code terminal
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "claudecode",
			group = group,
			callback = function()
				vim.opt_local.number = false
				vim.opt_local.relativenumber = false
				vim.opt_local.signcolumn = "no"
			end,
		})
	end,
	keys = {
		-- Main actions (using <leader>cl prefix)
		{ "<leader>cl", nil, desc = "󰧑 Claude Code" },
		{ "<leader>clc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>clf", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{ "<leader>clq", "<cmd>ClaudeCodeClose<cr>", desc = "Close Claude" },

		-- Session management
		{ "<leader>clr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume session" },
		{ "<leader>clC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue last" },
		{ "<leader>cln", "<cmd>ClaudeCode --new<cr>", desc = "New session" },

		-- Model selection
		{ "<leader>clm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },

		-- Context management
		{ "<leader>clb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer" },
		{ "<leader>clB", "<cmd>ClaudeCodeAddAll<cr>", desc = "Add all buffers" },
		{ "<leader>clx", "<cmd>ClaudeCodeClearContext<cr>", desc = "Clear context" },
		{ "<leader>cli", "<cmd>ClaudeCodeShowContext<cr>", desc = "Show context" },

		-- Send code/text to Claude
		{ "<leader>cls", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
		{
			"<leader>cls",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add from tree",
			ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
		},

		-- Diff management
		{ "<leader>cla", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>cld", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
		{ "<leader>clD", "<cmd>ClaudeCodeDiffView<cr>", desc = "View diffs" },

		-- Utility commands
		{ "<leader>cll", "<cmd>ClaudeCodeLogs<cr>", desc = "Show logs" },
		{ "<leader>clh", "<cmd>ClaudeCodeHelp<cr>", desc = "Help" },

		-- Quick actions (in visual mode)
		{ "<leader>cle", "<cmd>ClaudeCodeExplain<cr>", mode = "v", desc = "Explain code" },
		{ "<leader>clf", "<cmd>ClaudeCodeFix<cr>", mode = "v", desc = "Fix/improve code" },
		{ "<leader>clt", "<cmd>ClaudeCodeTest<cr>", mode = "v", desc = "Generate tests" },
		{ "<leader>clo", "<cmd>ClaudeCodeOptimize<cr>", mode = "v", desc = "Optimize code" },
	},
	cmd = {
		"ClaudeCode",
		"ClaudeCodeFocus",
		"ClaudeCodeClose",
		"ClaudeCodeSelectModel",
		"ClaudeCodeAdd",
		"ClaudeCodeClearContext",
		"ClaudeCodeShowContext",
	},
}
-- return {
-- 	"greggh/claude-code.nvim",
-- 	dependencies = {
-- 		"nvim-lua/plenary.nvim", -- Required for git operations
-- 	},
-- 	config = function()
-- 		require("claude-code").setup({
-- 			-- Terminal window settings
-- 			window = {
-- 				split_ratio = 0.3,      -- Percentage of screen for the terminal window
-- 				position = "botright",  -- Position: "botright", "topleft", "vertical", "float"
-- 				enter_insert = true,    -- Enter insert mode when opening Claude Code
-- 				hide_numbers = true,    -- Hide line numbers in terminal window
-- 				hide_signcolumn = true, -- Hide sign column in terminal window
--
-- 				-- Floating window configuration (only applies when position = "float")
-- 				float = {
-- 					width = "80%",        -- Width: number of columns or percentage string
-- 					height = "80%",       -- Height: number of rows or percentage string
-- 					row = "center",       -- Row position: number, "center", or percentage
-- 					col = "center",       -- Column position: number, "center", or percentage
-- 					relative = "editor",  -- Relative to: "editor" or "cursor"
-- 					border = "rounded",   -- Border: "none", "single", "double", "rounded", "solid", "shadow"
-- 				},
-- 			},
-- 			-- File refresh settings
-- 			refresh = {
-- 				enable = true,           -- Enable file change detection
-- 				updatetime = 100,        -- updatetime when Claude Code is active (temporarily overrides your 200ms default)
-- 				timer_interval = 1000,   -- How often to check for file changes (milliseconds)
-- 				show_notifications = true, -- Show notification when files are reloaded
-- 			},
-- 			-- Git project settings
-- 			git = {
-- 				use_git_root = true,     -- Set CWD to git root when opening Claude Code
-- 			},
-- 			-- Shell-specific settings
-- 			shell = {
-- 				separator = '&&',        -- Command separator for shell commands
-- 				pushd_cmd = 'pushd',     -- Push directory onto stack (bash/zsh)
-- 				popd_cmd = 'popd',       -- Pop directory from stack (bash/zsh)
-- 			},
-- 			-- Command settings
-- 			command = "claude",        -- Command to launch Claude Code
-- 			-- Command variants
-- 			command_variants = {
-- 				continue = "--continue", -- Resume the most recent conversation
-- 				resume = "--resume",     -- Display interactive conversation picker
-- 				verbose = "--verbose",   -- Enable verbose logging
-- 			},
-- 			-- Keymaps
-- 			keymaps = {
-- 				toggle = {
-- 					normal = "<C-,>",       -- Normal mode toggle (no conflicts)
-- 					terminal = "<C-,>",     -- Terminal mode toggle
-- 					variants = {
-- 						continue = "<leader>cc", -- Changed from cC to avoid <leader>ca conflict
-- 						verbose = "<leader>cV",  -- Verbose mode toggle (no conflicts)
-- 					},
-- 				},
-- 				window_navigation = true, -- Enable window navigation (<C-h/j/k/l>)
-- 				scrolling = true,         -- Enable scrolling (<C-f/b>) for page up/down
-- 			}
-- 		})
-- 	end,
-- }
