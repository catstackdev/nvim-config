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
		-- build = "cd app && npm install",
		build = "cd app && npm install && git -C .. restore -- app/yarn.lock",
		config = function()
			vim.g.mkdp_auto_close = 0 -- keep preview open when leaving buffer
			vim.g.mkdp_theme = "dark"
			vim.g.mkdp_filetypes = { "markdown" }
			vim.g.mkdp_browser = "chromium"
			vim.g.mkdp_echo_preview_url = 1 -- print URL in cmdline so you know the port
			vim.g.mkdp_page_title = "${name}"
			-- mkdp_markdown_css REPLACES the plugin's markdown.css instead of adding to it, so
			-- serve the plugin's own stylesheet with the midnight theme appended
			-- (absolute path required)
			local plugin_css = vim.fn.stdpath("data") .. "/lazy/markdown-preview.nvim/app/_static/markdown.css"
			local theme_css = vim.fn.stdpath("config") .. "/markdown-preview/midnight.css"
			local merged_css = vim.fn.stdpath("cache") .. "/markdown-preview-midnight.css"
			local base = vim.fn.readfile(plugin_css)
			vim.list_extend(base, vim.fn.readfile(theme_css))
			-- the previewer is served over http, so the shared wallpaper is inlined as a data URI
			local bg_file = io.open(vim.fn.expand("~/dotfiles/assets/bg/elven_mage_dragon_catttt.webp"), "rb")
			if bg_file then
				local encoded = vim.base64.encode(bg_file:read("*a"))
				bg_file:close()
				table.insert(
					base,
					('main[data-theme], :root { --mn-bg-image: url("data:image/webp;base64,%s"); }'):format(encoded)
				)
			end
			vim.fn.writefile(base, merged_css)
			vim.g.mkdp_markdown_css = merged_css
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
