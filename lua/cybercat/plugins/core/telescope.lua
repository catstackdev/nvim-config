return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	cmd = "Telescope", --for lazy loading
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-telescope/telescope-ui-select.nvim",
		"nvim-tree/nvim-web-devicons",
		"ThePrimeagen/harpoon",
		"folke/todo-comments.nvim",
		{ "nvim-telescope/telescope-dap.nvim" },

		{
			"jmbuhr/telescope-zotero.nvim",
			enabled = true,
			dev = false,
			dependencies = {
				{ "kkharji/sqlite.lua" },
			},
			config = function()
				vim.keymap.set("n", "<leader>fz", ":Telescope zotero<cr>", { desc = "[z]otero" })
			end,
		},
	},

	config = function()
		-- import telescope plugin safely
		local telescope = require("telescope")

		-- import telescope actions safely
		local actions = require("telescope.actions")

		-- import telescope-ui-select safely
		local themes = require("telescope.themes")

		-- configure telescope
		telescope.setup({
			-- configure custom mappings
			defaults = {
				-- vertical layout gives the results list the full terminal width
				-- (preview moves below) so long paths have room to display in full
				-- layout_strategy = "vertical",
				-- layout_config = {
				-- 	vertical = {
				-- 		preview_height = 0.5,
				-- 	},
				-- },
				-- puts the full path of the highlighted file in the preview
				-- window's title (top border), even when the results list
				-- below shows a smart-truncated path
				dynamic_preview_title = true,
				path_display = { "smart" },
				-- path_display = {},
				-- overall popup size: width/height are fractions of the editor;
				-- wider box = more room before "smart" needs to truncate anything
				layout_config = {
					width = 0.90,
					height = 0.90,
					horizontal = {
						preview_width = 0.60,
					},
				},
				file_ignore_patterns = { "node_modules", ".git/" },
				vimgrep_arguments = {
					"rg",
					"--hidden",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
				},
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- send selected to quickfixlist
					},
				},
			},
			extensions = {
				["ui-select"] = {
					themes.get_dropdown({}),
				},
			},
		})

		telescope.load_extension("fzf")
		telescope.load_extension("ui-select")
		telescope.load_extension("harpoon")

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" }) -- find files within current working directory, respects .gitignore
		keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" }) -- find previously opened files
		keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" }) -- find string in current working directory as you type
		keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" }) -- find string under cursor in current working directory
		keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Show open buffers" }) -- list open buffers in current neovim instance
		keymap.set("n", "<leader>fh", "<cmd>Telescope harpoon marks<cr>", { desc = "Show harpoon marks" }) -- show harpoon marks
		keymap.set("n", "<leader>gL", "<cmd>Telescope git_commits<cr>", { desc = "Show git Log/commits" }) -- list all git commits (use <cr> to checkout) ["gc" for git commits]
		keymap.set(
			"n",
			"<leader>gfc",
			"<cmd>Telescope git_bcommits<cr>",
			{ desc = "Show git commits for current buffer" }
		) -- list git commits for current file/buffer (use <cr> to checkout) ["gfc" for git file commits]
		keymap.set("n", "<leader>gb", "<cmd>Telescope git_branches<cr>", { desc = "Show git branches" }) -- list git branches (use <cr> to checkout) ["gb" for git branch]
		keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<cr>", { desc = "Show current git changes per file" }) -- list current changes per file with diff preview ["gs" for git status]
		keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
		vim.keymap.set("n", "<leader>fy", "<cmd>Telescope yank_history<cr>", {
			desc = "Yank history",
		})
	end,
}
