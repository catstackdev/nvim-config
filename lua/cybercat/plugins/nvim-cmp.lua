return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		-- Essential sources
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/cmp-nvim-lua",
		"uga-rosa/cmp-dictionary",
		"f3fora/cmp-spell",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-nvim-lsp-signature-help",
		"saadparwaiz1/cmp_luasnip",
		"hrsh7th/cmp-emoji",

		-- "petertriho/cmp-git", -- Added missing git source  use cmp_git
		-- Snippet engine & sources
		{
			"L3MON4D3/LuaSnip",
			version = "v2.*",
			build = "make install_jsregexp",
			dependencies = { "rafamadriz/friendly-snippets" },
		},

		-- AI / Copilot
		{
			"zbirenbaum/copilot.lua",
			cmd = "Copilot",
			event = "InsertEnter",
			enabled = true,
			config = function()
				require("copilot").setup({
					panel = { enabled = false },
					suggestion = { enabled = false },
					filetypes = {
						yaml = false,
						markdown = false,
						help = false,
						gitcommit = false,
						gitrebase = false,
						hgcommit = false,
						svn = false,
						cvs = false,
						["."] = false,
					},
					copilot_node_command = "node", -- Node.js version must be > 18.x
					server_opts_overrides = {},
				})
			end,
		},
		{
			"zbirenbaum/copilot-cmp",
			enabled = true,
			dependencies = { "zbirenbaum/copilot.lua" },
			config = function()
				require("copilot_cmp").setup()
			end,
		},

		{
			"Exafunction/codeium.nvim",

			enabled = true,
			dependencies = {
				"nvim-lua/plenary.nvim",
				"hrsh7th/nvim-cmp",
			},
			config = function()
				require("codeium").setup({
					filetypes = {
						-- filetypes = {
						python = true,
						javascript = true,
						typescript = true,
						lua = true,
						go = true,
						rust = true,
						c = true,
						cpp = true,
						java = true,
						php = true,
						ruby = true,
						sh = true,
						sql = true,
						yaml = true,
						json = true,
						html = true,
						css = true,
						markdown = true,
					},
					-- },
				})
			end,
		},

		-- UI/Visual enhancements
		"onsails/lspkind.nvim",

		-- Web development specific plugins
		{
			"roobert/tailwindcss-colorizer-cmp.nvim",
			config = function()
				require("tailwindcss-colorizer-cmp").setup({ color_square_width = 2 })
			end,
		},
		"David-Kunz/cmp-npm",
		{
			"windwp/nvim-ts-autotag",
			config = function()
				require("nvim-ts-autotag").setup()
			end,
		},
		{
			"NvChad/nvim-colorizer.lua",
			opts = { user_default_options = { mode = "virtualtext", tailwind = true } },
		},

		-- Snippets
		"mhartington/vim-angular2-snippets",
		-- 🧠 Supermaven AI completion
		-- Supermaven AI completion (recommended: use only this one)
		{
			"supermaven-inc/supermaven-nvim",
			event = "InsertEnter",
			enabled = true,
			config = function()
				require("supermaven-nvim").setup({
					keymaps = {
						accept_suggestion = "<C-y>",
						clear_suggestion = "<C-]>",
						accept_word = "<C-j>",
					},
				})
			end,
		},
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")

		-- Load our modular components
		local formatting = require("cybercat.core.completion.formatting")
		local sources = require("cybercat.core.completion.sources")
		local mappings = require("cybercat.core.completion.mappings")

		-- Ghost text toggle command
		local ghost_text_enabled = true
		vim.api.nvim_create_user_command("ToggleGhostText", function()
			ghost_text_enabled = not ghost_text_enabled
			cmp.setup.buffer({
				experimental = {
					ghost_text = ghost_text_enabled and { hl_group = "Comment" } or nil,
				},
			})
			vim.notify("Ghost text " .. (ghost_text_enabled and "enabled" or "disabled"))
		end, {})

		-- LuaSnip reload command
		vim.api.nvim_create_user_command("LuaSnipReload", function()
			require("luasnip.loaders.from_lua").load({ paths = vim.fn.stdpath("config") .. "/lua/luasnip" })
			vim.notify("LuaSnip snippets reloaded")
		end, {})

		-- LuaSnip list command
		vim.api.nvim_create_user_command("LuaSnipList", function()
			local ft = vim.bo.filetype
			local snippets = luasnip.get_snippets(ft)
			if not snippets or vim.tbl_isempty(snippets) then
				vim.notify("No snippets for filetype: " .. ft, vim.log.levels.WARN)
				return
			end
			
			local lines = { "Available snippets for '" .. ft .. "':" }
			for trigger, snip_list in pairs(snippets) do
				table.insert(lines, "  • " .. trigger .. " (" .. #snip_list .. " variant(s))")
			end
			vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
		end, {})

		-- Load VSCode-style snippets
		require("luasnip.loaders.from_vscode").lazy_load()
		
		-- Load Lua snippets from lua/luasnip directory
		require("luasnip.loaders.from_lua").lazy_load({ 
			paths = vim.fn.stdpath("config") .. "/lua/luasnip" 
		})
		
		-- LuaSnip configuration
		luasnip.config.set_config({
			history = true,
			updateevents = "TextChanged,TextChangedI",
			enable_autosnippets = true,
		})

		-- Main cmp setup
		cmp.setup({
			completion = {
				completeopt = "menu,menuone,preview,noselect",
			},
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			mapping = mappings.get_mappings(cmp, luasnip),
			sources = cmp.config.sources(sources.get_default_sources()),
			formatting = formatting.get_formatting(),
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
			experimental = {
				ghost_text = {
					hl_group = "Comment",
				},
			},
			-- Performance improvements
			performance = {
				debounce = 60,
				throttle = 30,
				fetching_timeout = 500,
				max_view_entries = 30,
			},
		})

		-- Filetype-specific configurations
		for _, ft in ipairs({ "markdown", "gitcommit", "text" }) do
			cmp.setup.filetype(ft, {
				sources = cmp.config.sources(sources.get_text_sources()),
			})
		end

		-- Cmdline completion
		cmp.setup.cmdline("/", {
			mapping = mappings.get_cmdline_mappings(cmp),
			sources = sources.get_search_sources(),
		})

		-- Git commit completion
		cmp.setup.filetype("gitcommit", {
			sources = cmp.config.sources(sources.get_gitcommit_sources()),
		})
		-- Git completion setup
		-- require("cmp_git").setup()
	end,
}
