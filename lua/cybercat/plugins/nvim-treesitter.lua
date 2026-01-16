-- NOTE:InspectTree
-- ctrl+ space (selecte evetighin {} or () )
-- auto close tag
return {
	{
		"nvim-treesitter/nvim-treesitter",
		-- event = { "BufReadPre", "BufNewFile" },
		event = "BufReadPost", -- Loads after UI is ready
		build = ":TSUpdate",
		dependencies = {
			-- "nvim-treesitter/nvim-treesitter-textobjects",
			"windwp/nvim-ts-autotag",
			"nvim-treesitter/nvim-treesitter-refactor",
		},
		config = function()
			-- import nvim-treesitter plugin
			local treesitter = require("nvim-treesitter.configs")

			-- configure treesitter
			treesitter.setup({ -- enable syntax highlighting
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false, -- avoid conflicts with Vim syntax
				},
				-- enable indentation
				indent = { enable = true },
				-- enable autotagging (w/ nvim-ts-autotag plugin)
				-- autotag = { // NOTE: disabled by bc
				-- 	enable = true,
				-- },
				-- ensure these language parsers are installed
				-- ensure_installed = {
				-- 	"regex",
				-- 	--
				-- 	"json",
				-- 	"javascript",
				-- 	"typescript",
				-- 	"tsx",
				-- 	"yaml",
				-- 	"html",
				-- 	"css",
				-- 	"prisma",
				-- 	"markdown",
				-- 	"markdown_inline",
				-- 	"svelte",
				-- 	"graphql",
				-- 	"bash",
				-- 	"lua",
				-- 	"vim",
				-- 	"dockerfile",
				-- 	"gitignore",
				-- 	"query",
				-- 	"terraform", -- added manually by bc
				-- 	"vue", -- Added for Vue.js support
				-- 	"json5", -- Added for JSON5 support
				-- 	"scss", -- Added for SCSS support
				-- 	-- "less", -- Added for LESS support
				-- 	-- "mdx", -- Include MDX support
				-- 	"vimdoc",
				-- 	"c",
				-- 	"latex",
				-- },
				ensure_installed = {
					-- 🌐 Web
					"html",
					"css",
					"scss",
					-- "less",    -- optional
					"javascript",
					"typescript",
					"tsx",
					"vue",
					"svelte",
					"graphql",

					-- 📦 Data / Config
					"json",
					"json5",
					"yaml",
					"toml", -- good for configs
					"regex",
					"prisma",
					"gitignore",
					"dockerfile",
					"query",

					-- 📖 Docs / Markup
					"markdown",
					"markdown_inline",
					-- "mdx",     -- optional if you use MDX
					"latex",
					"vimdoc",

					-- 🛠️ Infra
					"terraform",

					-- 🖥️ Core
					"lua",
					"vim",

					-- 🔧 Systems / Misc
					"bash",
					"c",

					-- 🚀 Optional extras (uncomment if you code in these)
					-- "python",
					-- "rust",
					-- "go",
					-- "java",
					--
					-- "handlebars",
					-- "glimmer",
				},
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<C-space>",
						node_incremental = "<C-space>",
						scope_incremental = false,
						node_decremental = "<bs>",
					},
				},
				-- Treesitter refactor module
				refactor = {
					highlight_definitions = {
						enable = true,
						-- Set to false if you have an `updatetime` of ~100
						clear_on_cursor_move = true,
					},
					smart_rename = {
						enable = true,
						keymaps = {
							smart_rename = "grr", -- Changed from gR to avoid conflict with LSP references
						},
					},
					navigation = {
						enable = true,
						keymaps = {
							goto_definition = "gnd",
							list_definitions = "gnD",
							list_definitions_toc = "gO",
							goto_next_usage = "<a-*>",
							goto_previous_usage = "<a-#>",
						},
					},
				},
			})

			-- enable nvim-ts-context-commentstring plugin for commenting tsx and jsx
			-- require("ts_context_commentstring").setup({})
		end,
	},

	-- Start Tree-sitter highlighting for markdown buffers automatically
	-- vim.api.nvim_create_autocmd("FileType", {
	--   pattern = "markdown",
	--   callback = function()
	--     if not vim.treesitter.get_parser(0, "markdown") then
	--       vim.treesitter.start(0, "markdown")
	--     end
	--   end,
	-- })
}
