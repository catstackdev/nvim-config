return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	enabled = true,
	opts = {
		-- >> Bullet Lists <<
		bullet = {
			enabled = true,
			render_modes = false,
			-- You can also customize icons for different list levels
			icons = { "●", "○", "◆", "◇" },

			ordered_icons = function(ctx)
				local value = vim.trim(ctx.value)
				local index = tonumber(value:sub(1, #value - 1))
				return ("%d."):format(index > 1 and index or ctx.index)
			end,
			left_pad = 0,
			right_pad = 0,
			highlight = "RenderMarkdownBullet",
			-- scope_highlight = {},
		},

		-- >> Checkboxes / Task Lists <<
		checkbox = {
			enabled = true,
			render_modes = false,
			right_pad = 1,
			unchecked = {
				icon = "󰄱 ", -- Nerd Font: nf-md-checkbox_blank_outline
				highlight = "RenderMarkdownUnchecked",
			},
			checked = {
				icon = "󰱒 ", -- Nerd Font: nf-md-checkbox_marked
				highlight = "RenderMarkdownChecked",
			},
			custom = {
				toggled = {
					raw = "[-]",
					rendered = "󰰵 ", -- Nerd Font: nf-md-minus_box_outline
					highlight = "RenderMarkdownToggled",
				},
				pending = {
					raw = "[~]",
					rendered = "󰦕 ", -- Nerd Font: nf-md-progress_clock for pending
					highlight = "RenderMarkdownPending",
				},
				progress = {
					raw = "[/]",
					rendered = "󰦗 ", -- Nerd Font: nf-md-progress_check for in progress
					highlight = "RenderMarkdownProgress",
				},
			},
		},

		-- >> Headings <<
		heading = {
			enabled = true,
			-- Conceal '#' and show icons on the left
			position = "overlay",
			icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " }, -- Nerd Font Header Icons
			-- Decorative borders
			above = "▄",
			below = "▀",
			backgrounds = {
				"RenderMarkdownH1Bg",
				"RenderMarkdownH2Bg",
				"RenderMarkdownH3Bg",
				"RenderMarkdownH4Bg",
				"RenderMarkdownH5Bg",
				"RenderMarkdownH6Bg",
			},
			foregrounds = {
				"RenderMarkdownH1",
				"RenderMarkdownH2",
				"RenderMarkdownH3",
				"RenderMarkdownH4",
				"RenderMarkdownH5",
				"RenderMarkdownH6",
			},
		},

		-- >> Code Blocks & Inline Code <<
		-- For inline `code` spans
		code = {
			-- Upgraded: Change to "normal" for better rendering
			style = "normal",
		},
		-- Code block rendering (fence removed in newer versions, handled by code block)
		-- code_block = {
		-- 	enabled = true,
		-- 	style = "full",
		-- 	left_pad = 1,
		-- 	right_pad = 1,
		-- 	language = {
		-- 		enabled = true,
		-- 		highlight = "RenderMarkdownCodeBlockLang",
		-- 	},
		-- 	border = "thick",
		-- },

		-- >> Links & Images <<
		link = {
			enabled = true,

			-- Additional modes to render links.
			render_modes = false,

			footnote = {
				-- Turn on / off footnote rendering.
				enabled = true,
				-- Replace value with superscript equivalent.
				superscript = true,
				-- Added before link content.
				prefix = "",
				-- Added after link content.
				suffix = "",
			},
			-- Icon for general links (respects your custom skitty mode check)
			-- icon = vim.g.neovim_mode == "skitty" and "" or "󰥶 ", -- Nerd Font: nf-md-link_variant
			-- Icon for images ![alt](src)
			image = "󰈟 ", -- Nerd Font: nf-md-image
			email = "󰀓 ",
			-- Fallback icon for 'inline_link' and 'uri_autolink' elements.
			hyperlink = "󰌹 ",
			-- Applies to the inlined icon as a fallback.
			highlight = "RenderMarkdownLink",
			-- Applies to WikiLink elements.
			wiki = {
				icon = "󱗖 ",
				body = function()
					return nil
				end,
				highlight = "RenderMarkdownWikiLink",
			},
			-- Add more custom rules for specific domains
			custom = {
				web = { pattern = "^http", icon = "󰖟 " },
				["github.com"] = { pattern = "github%.com", icon = "󰊤 " }, -- Nerd Font: nf-md-github
				gitlab = { pattern = "gitlab%.com", icon = "󰮠 " },

				stackoverflow = { pattern = "stackoverflow%.com", icon = "󰓌 " },
				wikipedia = { pattern = "wikipedia%.org", icon = "󰖬 " },
				["youtu.be"] = { pattern = "youtu%.be", icon = "󰗃 " }, -- Nerd Font: nf-md-youtube
				["youtube.com"] = { pattern = "youtube%.com", icon = "󰗃 " },
				["neovim.io"] = { pattern = "neovim%.io", icon = " " }, -- Custom Neovim icon
				-- Upgraded: Add more domains
				["x.com"] = { pattern = "x%.com", icon = "󰗤 " }, -- Nerd Font: nf-md-twitter (rebranded to X)
				["wikipedia.org"] = { pattern = "wikipedia%.org", icon = "󰖬 " }, -- Nerd Font: nf-md-book_open_variant
				["reddit.com"] = { pattern = "reddit%.com", icon = "󰑍 " }, -- Nerd Font: nf-md-reddit
			},
		},

		-- >> More Rendered Elements (Previously Disabled or Not Set) <<
		-- For horizontal rules like --- or ***
		-- rule = {
		-- 	enabled = true,
		-- 	char = "─", -- Character to repeat for the line
		-- 	highlight = "RenderMarkdownRule",
		-- },//oldversion
		dash = { -- //new with specific
			enabled = true,
			icon = "─",
		},

		-- For blockquotes >
		quote = {
			enabled = true,
			icon = "▎", -- Icon to show at the start of the quote
			highlight = "RenderMarkdownQuote",
			-- scope_highlight = "RenderMarkdownQuoteScope", //old version
		},

		-- Enable rendering for other filetypes embedded in Markdown
		html = { enabled = true },
		latex = { -- use for latex equations
			enabled = false,
			converter = "latex2text", -- or "latex2mathml"
			highlight = "RenderMarkdownMath",
		},
		yaml = { enabled = true },

		-- Pipe tables (GitHub-style tables)
		pipe_table = {
			enabled = true,
			preset = "round", -- "none" | "round" | "double" | "heavy" | "grouped"
			style = "full",
			alignment_indicator = "━",
			head = "RenderMarkdownTableHead",
			row = "RenderMarkdownTableRow",
		},

		-- Upgraded: Add anti-conceal to show original text when cursor is on the line
		anti_conceal = {
			enabled = true,
			-- Which elements to always show, ignoring anti conceal behavior. Values can either be
			-- booleans to fix the behavior or string lists representing modes where anti conceal
			-- behavior will be ignored. Valid values are:
			--   head_icon, head_background, head_border, code_language, code_background, code_border,
			--   dash, bullet, check_icon, check_scope, quote, table_border, callout, link, sign
			ignore = {
				code_background = true,
				sign = true,
			},
			above = 0,
			below = 0,
		},

		-- Sign column icons for headings/bullets
		sign = {
			enabled = true,
			highlight = "RenderMarkdownSign",
		},

		-- Win options to apply when rendering
		win_options = {
			conceallevel = { default = 2, rendered = 2 },
			concealcursor = { default = "", rendered = "nc" },
		},

		-- Upgraded: Add callouts for special blockquotes like > [!NOTE]
		callout = {
			note = { raw = "[!NOTE]", rendered = "󰎛 ", highlight = "RenderMarkdownInfo" }, -- Nerd Font: nf-md-information
			tip = { raw = "[!TIP]", rendered = "󰌶 ", highlight = "RenderMarkdownSuccess" }, -- Nerd Font: nf-md-lightbulb
			important = { raw = "[!IMPORTANT]", rendered = "󰅾 ", highlight = "RenderMarkdownHint" }, -- Nerd Font: nf-md-exclamation
			warning = { raw = "[!WARNING]", rendered = "󰀪 ", highlight = "RenderMarkdownWarn" }, -- Nerd Font: nf-md-alert
			caution = { raw = "[!CAUTION]", rendered = "󰳾 ", highlight = "RenderMarkdownError" }, -- Nerd Font: nf-md-fire
			abstract = { raw = "[!ABSTRACT]", rendered = "󰨸 Abstract", highlight = "RenderMarkdownInfo" },
			summary = { raw = "[!SUMMARY]", rendered = "󰨸 Summary", highlight = "RenderMarkdownInfo" },
			tldr = { raw = "[!TLDR]", rendered = "󰨸 Tldr", highlight = "RenderMarkdownInfo" },
			info = { raw = "[!INFO]", rendered = "󰋽 Info", highlight = "RenderMarkdownInfo" },
			todo = { raw = "[!TODO]", rendered = "󰗡 Todo", highlight = "RenderMarkdownInfo" },
			hint = { raw = "[!HINT]", rendered = "󰌶 Hint", highlight = "RenderMarkdownSuccess" },
			success = { raw = "[!SUCCESS]", rendered = "󰄬 Success", highlight = "RenderMarkdownSuccess" },
			check = { raw = "[!CHECK]", rendered = "󰄬 Check", highlight = "RenderMarkdownSuccess" },
			done = { raw = "[!DONE]", rendered = "󰄬 Done", highlight = "RenderMarkdownSuccess" },
			question = { raw = "[!QUESTION]", rendered = "󰘥 Question", highlight = "RenderMarkdownWarn" },
			help = { raw = "[!HELP]", rendered = "󰘥 Help", highlight = "RenderMarkdownWarn" },
			faq = { raw = "[!FAQ]", rendered = "󰘥 Faq", highlight = "RenderMarkdownWarn" },
			attention = { raw = "[!ATTENTION]", rendered = "󰀪 Attention", highlight = "RenderMarkdownWarn" },
			failure = { raw = "[!FAILURE]", rendered = "󰅖 Failure", highlight = "RenderMarkdownError" },
			fail = { raw = "[!FAIL]", rendered = "󰅖 Fail", highlight = "RenderMarkdownError" },
			missing = { raw = "[!MISSING]", rendered = "󰅖 Missing", highlight = "RenderMarkdownError" },
			danger = { raw = "[!DANGER]", rendered = "󱐌 Danger", highlight = "RenderMarkdownError" },
			error = { raw = "[!ERROR]", rendered = "󱐌 Error", highlight = "RenderMarkdownError" },
			bug = { raw = "[!BUG]", rendered = "󰨰 Bug", highlight = "RenderMarkdownError" },
			example = { raw = "[!EXAMPLE]", rendered = "󰉹 Example", highlight = "RenderMarkdownHint" },
			quote = { raw = "[!QUOTE]", rendered = "󱆨 Quote", highlight = "RenderMarkdownQuote" },
			cite = { raw = "[!CITE]", rendered = "󱆨 Cite", highlight = "RenderMarkdownQuote" },
		},
	},
}
