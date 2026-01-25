-- ============================================================================
-- Snacks.nvim Options
-- ============================================================================
-- Extracted from snacks.lua for better organization
-- ============================================================================

local M = {}

function M.setup()
	return {
		bigfile = { enabled = true },
		explorer = { enabled = true },
		indent = { enabled = true },
		input = { enabled = true },
		
		-- ============================================================================
		-- Picker Configuration
		-- ============================================================================
		-- Documentation: https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
		
		picker = {
			-- Score manipulation for frecency
			transform = function(item)
				if not item.file then
					return item
				end
				-- Demote the "lazyvim" keymaps file
				if item.file:match("lazyvim/lua/config/keymaps%.lua") then
					item.score_add = (item.score_add or 0) - 30
				end
				return item
			end,
			
			debug = {
				scores = false, -- show scores in the list
			},
			
			-- Default layout: ivy
			layout = {
				preset = "ivy",
				cycle = false, -- Don't cycle to top when reaching bottom
			},
			
			-- Custom layouts
			layouts = {
				ivy = {
					layout = {
						box = "vertical",
						backdrop = false,
						row = -1,
						width = 0,
						height = 0.5,
						border = "top",
						title = " {title} {live} {flags}",
						title_pos = "left",
						{ win = "input", height = 1, border = "bottom" },
						{
							box = "horizontal",
							{ win = "list", border = "none" },
							{ win = "preview", title = "{preview}", width = 0.5, border = "left" },
						},
					},
				},
				vertical = {
					layout = {
						backdrop = false,
						width = 0.8,
						min_width = 80,
						height = 0.8,
						min_height = 30,
						box = "vertical",
						border = "rounded",
						title = "{title} {live} {flags}",
						title_pos = "center",
						{ win = "input", height = 1, border = "bottom" },
						{ win = "list", border = "none" },
						{ win = "preview", title = "{preview}", height = 0.4, border = "top" },
					},
				},
			},
			
			matcher = {
				frecency = true,
			},
			
			win = {
				input = {
					keys = {
						["<Esc>"] = { "close", mode = { "n", "i" } },
						["J"] = { "preview_scroll_down", mode = { "i", "n" } },
						["K"] = { "preview_scroll_up", mode = { "i", "n" } },
						["H"] = { "preview_scroll_left", mode = { "i", "n" } },
						["L"] = { "preview_scroll_right", mode = { "i", "n" } },
					},
				},
			},
			
			formatters = {
				file = {
					filename_first = true, -- display filename before path
					truncate = 80,
				},
			},
		},
		
		-- ============================================================================
		-- LazyGit Configuration
		-- ============================================================================
		-- Documentation: https://github.com/folke/snacks.nvim/blob/main/docs/lazygit.md
		
		lazygit = {
			theme = {
				selectedLineBgColor = { bg = "CursorLine" },
			},
			win = {
				width = 0,  -- Fullscreen
				height = 0, -- Fullscreen
			},
		},
		
		-- ============================================================================
		-- Notifier Configuration
		-- ============================================================================
		
		notifier = {
			enabled = true,
			top_down = false, -- place notifications from top to bottom
			timeout = 3000,
		},
		
		-- ============================================================================
		-- Styles Configuration
		-- ============================================================================
		
		styles = {
			snacks_image = {
				relative = "editor",
				col = -1, -- Top right corner
			},
			notification = {
				wo = { wrap = true },
			},
		},
		
		-- ============================================================================
		-- Image Configuration
		-- ============================================================================
		
		image = {
			enabled = true,
			doc = {
				-- Render inline in skitty mode, float otherwise
				inline = vim.g.neovim_mode == "skitty" and true or false,
				float = true,
				-- Size based on mode
				max_width = vim.g.neovim_mode == "skitty" and 5 or 60,
				max_height = vim.g.neovim_mode == "skitty" and 2.5 or 30,
				-- Cache location: :lua print(vim.fn.stdpath("cache") .. "/snacks/image")
			},
		},
		
		-- ============================================================================
		-- Dashboard Configuration
		-- ============================================================================
		
		dashboard = {
			preset = {
				keys = {
					{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
					{ icon = " ", key = "<esc>", desc = "Quit", action = ":qa" },
				},
				-- ASCII Art: ANSI Shadow font
				-- Source: https://patorjk.com/software/taag
				header = [[
███╗   ██╗███████╗ ██████╗ ██████╗ ███████╗ █████╗ ███╗   ██╗
████╗  ██║██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗████╗  ██║
██╔██╗ ██║█████╗  ██║   ██║██████╔╝█████╗  ███████║██╔██╗ ██║
██║╚██╗██║██╔══╝  ██║   ██║██╔══██╗██╔══╝  ██╔══██║██║╚██╗██║
██║ ╚████║███████╗╚██████╔╝██████╔╝███████╗██║  ██║██║ ╚████║
╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝

[Linkarzu.com]
        ]],
			},
		},
	}
end

return M
