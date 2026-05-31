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
			{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
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
				-- enable indentation (disabled for ts/js — known buggy indent queries)
				indent = {
					enable = true,
					disable = { "typescript", "tsx", "javascript", "typescriptreact", "javascriptreact" },
				},
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
					"http", -- for rest.nvim
					"hurl", -- for hurl.nvim

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
					"glsl",
					"wgsl",

					-- 🚀 Backend / Systems
					"go",
					"python",
					"rust",
					-- "java",
					-- "handlebars",  -- no parser available
					-- "glimmer",     -- no parser available
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
				-- nvim-treesitter-textobjects (master branch API)
				textobjects = {
					select = {
						enable = true,
						lookahead = true, -- jump forward to nearest match
						keymaps = {
							["af"] = { query = "@function.outer", desc = "outer function" },
							["if"] = { query = "@function.inner", desc = "inner function" },
							["ac"] = { query = "@class.outer", desc = "outer class" },
							["ic"] = { query = "@class.inner", desc = "inner class" },
							["aa"] = { query = "@parameter.outer", desc = "outer parameter/argument" },
							["ia"] = { query = "@parameter.inner", desc = "inner parameter/argument" },
							["ai"] = { query = "@conditional.outer", desc = "outer conditional" },
							["ii"] = { query = "@conditional.inner", desc = "inner conditional" },
							["al"] = { query = "@loop.outer", desc = "outer loop" },
							["il"] = { query = "@loop.inner", desc = "inner loop" },
						},
					},
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["]f"] = { query = "@function.outer", desc = "next function start" },
							["]c"] = { query = "@class.outer", desc = "next class start" },
							["]a"] = { query = "@parameter.inner", desc = "next argument" },
						},
						goto_next_end = {
							["]F"] = { query = "@function.outer", desc = "next function end" },
							["]C"] = { query = "@class.outer", desc = "next class end" },
						},
						goto_previous_start = {
							["[f"] = { query = "@function.outer", desc = "prev function start" },
							["[c"] = { query = "@class.outer", desc = "prev class start" },
							["[a"] = { query = "@parameter.inner", desc = "prev argument" },
						},
						goto_previous_end = {
							["[F"] = { query = "@function.outer", desc = "prev function end" },
							["[C"] = { query = "@class.outer", desc = "prev class end" },
						},
					},
					swap = {
						enable = true,
						swap_next = {
							["<leader>tsa"] = { query = "@parameter.inner", desc = "swap argument with next" },
						},
						swap_previous = {
							["<leader>tsA"] = { query = "@parameter.inner", desc = "swap argument with prev" },
						},
					},
				},
				-- Treesitter refactor module
				refactor = {
					highlight_definitions = {
						enable = false, -- disabled: nil parent crash (nvim-treesitter-refactor bug)
						-- Set to false if you have an `updatetime` of ~100
						clear_on_cursor_move = true,
					},
					smart_rename = {
						enable = true,
						keymaps = {
							smart_rename = "<leader>tr", -- gr* family reserved by Neovim 0.11+ (grr=refs, grn=rename, gra=action, gri=impl)
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
		init = function()
			-- Disable markdown injections: plain ``` blocks (no language tag) produce
			-- a nil info_string node that crashes nvim-treesitter's query predicates
			-- on Neovim 0.12. Remove once upstream fixes the nil-check.
			vim.treesitter.query.set("markdown", "injections", "")
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
