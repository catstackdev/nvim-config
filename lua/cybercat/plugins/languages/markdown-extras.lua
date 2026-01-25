-- Extra markdown enhancements beyond render-markdown
return {
	-- Render markdown images in terminal
	{
		"3rd/image.nvim",
		ft = { "markdown", "norg" },
		opts = {
			backend = "kitty", -- or "ueberzug"
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = true,
					only_render_image_at_cursor = true,
				},
			},
			max_width = 100,
			max_height = 12,
		},
	},

	-- Markdown table mode (easy table editing)
	{
		"dhruvasagar/vim-table-mode",
		ft = "markdown",
		config = function()
			vim.g.table_mode_corner = "|"
			vim.g.table_mode_corner_corner = "|"
			vim.g.table_mode_header_fillchar = "-"
		end,
		keys = {
			{ "<leader>tm", "<cmd>TableModeToggle<cr>", desc = "Toggle Table Mode" },
		},
	},

	-- Markdown TOC generator
	{
		"mzlogin/vim-markdown-toc",
		ft = "markdown",
		cmd = { "GenTocGFM", "GenTocGitLab", "GenTocMarked" },
		keys = {
			{ "<leader>mt", "<cmd>GenTocGFM<cr>", desc = "Generate TOC" },
		},
	},

	-- Preview markdown in browser with live reload
	{
		"iamcco/markdown-preview.nvim",
		ft = "markdown",
		build = "cd app && npm install",
		config = function()
			vim.g.mkdp_auto_close = 0
			vim.g.mkdp_theme = "dark"
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		keys = {
			{ "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
		},
	},

	-- Obsidian.nvim - Obsidian integration
	{
		"epwalsh/obsidian.nvim",
		enabled = false, -- Disabled: causing healthcheck conflicts
		ft = "markdown",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			workspaces = {
				{
					name = "notes",
					path = "~/notes", -- Change to your notes directory
				},
			},
			daily_notes = {
				folder = "daily",
				date_format = "%Y-%m-%d",
			},
			completion = {
				nvim_cmp = true,
			},
			mappings = {
				["gf"] = {
					action = function()
						return require("obsidian").util.gf_passthrough()
					end,
					opts = { noremap = false, expr = true, buffer = true },
				},
				["<leader>ch"] = {
					action = function()
						return require("obsidian").util.toggle_checkbox()
					end,
					opts = { buffer = true },
				},
			},
		},
		keys = {
			{ "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New Note" },
			{ "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search Notes" },
			{ "<leader>ot", "<cmd>ObsidianToday<cr>", desc = "Today's Note" },
			{ "<leader>ol", "<cmd>ObsidianBacklinks<cr>", desc = "Backlinks" },
		},
	},

	-- Markdown code block execution
	{
		"jubnzv/mdeval.nvim",
		ft = "markdown",
		config = function()
			require("mdeval").setup({
				require_confirmation = false,
				eval_options = {
					javascript = {
						command = { "node" },
					},
					python = {
						command = { "python3" },
					},
					bash = {
						command = { "bash" },
					},
					lua = {
						command = { "lua" },
					},
				},
			})
		end,
		keys = {
			{ "<leader>me", "<cmd>MdEval<cr>", desc = "Execute Code Block" },
		},
	},

	-- Markdown link helper
	{
		"jghauser/follow-md-links.nvim",
		ft = "markdown",
		keys = {
			{ "<cr>", "<cmd>edit <cfile><cr>", ft = "markdown", desc = "Follow Markdown Link" },
		},
	},
}
