local colors = require("cybercat.core.ui.colors")

return {
	"eldritch-theme/eldritch.nvim",
	lazy = true,
	name = "eldritch",
	opts = {
		transparent = true,
		styles = {
			sidebars = "transparent",
			floats = "transparent",
		},

		-- Global colors
		on_colors = function(global_colors)
			local color_definitions = {
				bg = colors["cybercat_color10"],
				fg = colors["cybercat_color14"],
				selection = colors["cybercat_color16"],
				comment = colors["cybercat_color09"],
				red = colors["cybercat_color08"],
				orange = colors["cybercat_color06"],
				yellow = colors["cybercat_color05"],
				green = colors["cybercat_color02"],
				purple = colors["cybercat_color04"],
				cyan = colors["cybercat_color03"],
				pink = colors["cybercat_color01"],
				bright_red = colors["cybercat_color08"],
				bright_green = colors["cybercat_color02"],
				bright_yellow = colors["cybercat_color05"],
				bright_blue = colors["cybercat_color04"],
				bright_magenta = colors["cybercat_color01"],
				bright_cyan = colors["cybercat_color03"],
				bright_white = colors["cybercat_color14"],
				menu = colors["cybercat_color10"],
				visual = colors["cybercat_color16"],
				gutter_fg = colors["cybercat_color16"],
				nontext = colors["cybercat_color16"],
				white = colors["cybercat_color14"],
				black = colors["cybercat_color10"],
				bg_dark = colors["cybercat_color13"],
				bg_highlight = colors["cybercat_color17"],
				terminal_black = colors["cybercat_color13"],
				fg_dark = colors["cybercat_color14"],
				fg_gutter = colors["cybercat_color13"],
				dark3 = colors["cybercat_color13"],
				dark5 = colors["cybercat_color13"],
				bg_visual = colors["cybercat_color16"],
			}

			for key, value in pairs(color_definitions) do
				global_colors[key] = value
			end
		end,

		-- Highlights
		on_highlights = function(highlights)
			local hl = {
				-- Cursor & line
				CursorLine = { bg = colors["cybercat_color13"] },
				Cursor = { bg = colors["cybercat_color24"] },
				lCursor = { bg = colors["cybercat_color24"] },
				CursorIM = { bg = colors["cybercat_color24"] },

				-- Diffs
				DiffChange = { bg = colors["cybercat_color03"], fg = "black" },
				DiffDelete = { bg = colors["cybercat_color11"], fg = "black" },
				DiffAdd = { bg = colors["cybercat_color02"], fg = "black" },
				TelescopeResultsDiffDelete = { bg = colors["cybercat_color01"], fg = "black" },

				-- Spell
				SpellBad = { sp = colors["cybercat_color11"], undercurl = true, bold = true, italic = true },
				SpellCap = { sp = colors["cybercat_color12"], undercurl = true, bold = true, italic = true },
				SpellLocal = { sp = colors["cybercat_color12"], undercurl = true, bold = true, italic = true },
				SpellRare = { sp = colors["cybercat_color04"], undercurl = true, bold = true, italic = true },

				-- Visual
				Visual = { bg = colors["cybercat_color16"], fg = colors["cybercat_color10"] },

				-- Operators & markup
				["@operator"] = { fg = colors["cybercat_color02"] },
				["@markup.strong"] = { fg = colors["cybercat_color24"], bold = true },
				["@markup.raw.markdown_inline"] = { fg = colors["cybercat_color02"] },

				-- Fold
				Folded = { bg = "NONE" },

				-- Markdown code
				RenderMarkdownCode = { bg = colors["cybercat_color07"], fg = colors["cybercat_color14"] },
				RenderMarkdownCodeInline = { bg = colors["cybercat_color02"], fg = colors["cybercat_color26"] },

				-- Floating windows
				NormalFloat = { bg = "NONE" },
				FloatBorder = { bg = colors["cybercat_color10"] },
				FloatTitle = { bg = colors["cybercat_color10"] },
				NotifyBackground = { bg = colors["cybercat_color10"] },

				-- LSP Inlay Hints (parameter names, type hints)
				LspInlayHint = {
					fg = colors["cybercat_color09"], -- Comment color (subtle gray)
					bg = "NONE",
					italic = true,
				},
			}

			for group, spec in pairs(hl) do
				highlights[group] = spec
			end

			-- Markdown heading backgrounds
			local md_headings = {
				Headline1Bg = { bg = colors["cybercat_color18"], fg = colors["cybercat_color04"] },
				Headline2Bg = { bg = colors["cybercat_color19"], fg = colors["cybercat_color02"] },
				Headline3Bg = { bg = colors["cybercat_color20"], fg = colors["cybercat_color03"] },
				Headline4Bg = { bg = colors["cybercat_color21"], fg = colors["cybercat_color01"] },
				Headline5Bg = { bg = colors["cybercat_color22"], fg = colors["cybercat_color05"] },
				Headline6Bg = { bg = colors["cybercat_color23"], fg = colors["cybercat_color08"] },

				Headline1Fg = { fg = colors["cybercat_color04"], bold = true },
				Headline2Fg = { fg = colors["cybercat_color02"], bold = true },
				Headline3Fg = { fg = colors["cybercat_color03"], bold = true },
				Headline4Fg = { fg = colors["cybercat_color01"], bold = true },
				Headline5Fg = { fg = colors["cybercat_color05"], bold = true },
				Headline6Fg = { fg = colors["cybercat_color08"], bold = true },
			}

			for name, spec in pairs(md_headings) do
				highlights[name] = spec
			end
		end,
	},
}
