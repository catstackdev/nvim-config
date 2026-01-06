return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	-- dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")
		dashboard.section.header.val = {
			"                                /\\_/\\                   ",

			"                               ( o.o )                  ",
			"                                > ^ < ",
			-- "                           C y b e r C a t                      ",
			"",
			" ██████╗██╗   ██╗██████╗ ███████╗██████╗        ██████╗ █████╗ ████████╗",
			"██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗      ██╔════╝██╔══██╗╚══██╔══╝",
			"██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝█████╗██║     ███████║   ██║   ",
			"██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗╚════╝██║     ██╔══██║   ██║   ",
			"╚██████╗   ██║   ██████╔╝███████╗██║  ██║      ╚██████╗██║  ██║   ██║   ",
			" ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝       ╚═════╝╚═╝  ╚═╝   ╚═╝   ",
			"                                                                        ",
		}

		-- Set menu
		dashboard.section.buttons.val = {
			dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
			dashboard.button("SPC ee", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
			dashboard.button("SPC ff", "󰱼 > Find File", "<cmd>Telescope find_files<CR>"),
			dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
			dashboard.button("SPC wr", "󰁯  > Restore Session For Current Directory", "<cmd>SessionRestore<CR>"),
			dashboard.button("q", " > Quit NVIM", "<cmd>qa<CR>"),
		}
		-- -- Define the recently opened files section
		-- dashboard.section.recent_files.val = {
		-- 	preview = {
		-- 		enable = true,
		-- 	},
		-- 	max_entries = 10, -- Display up to 10 recent files
		-- }
		local cyber_tips = {
			"// Optimize your data streams. //",
			"// Watch your back, citizen. //",
			"// The code is the law. //",
			"// Engage the system. //",
			"// Always patch your kernel. //",
			"// Trust no one, code everything. //",
			"// Data is power. //",
		}

		dashboard.section.tips = {
			type = "group",
			val = {
				{
					type = "text",
					val = " ", -- Spacer
				},
				{
					type = "text",
					val = "                           -- CYBER TIPS --",
					opts = { hl = "AlphaButtons" }, -- Use a highlight group for consistency
				},
				{
					type = "text",
					val = cyber_tips[math.random(#cyber_tips)], -- Pick a random tip
					opts = { hl = "Comment" }, -- A subtle highlight for the tip text
				},
				{
					type = "text",
					val = " ", -- Spacer
				},
			},
			position = "center",
		}
		-- Define the dynamic footer with system info
		dashboard.section.footer.val = function()
			local git_branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
			local current_time = os.date("%H:%M:%S")
			local current_date = os.date("%Y-%m-%d")
			local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t") -- Gets just the folder name

			local msg = "                                  " -- Leading spaces for alignment

			msg = msg .. "CWD: " .. cwd .. "  |  SYS: " .. current_date .. " " .. current_time

			if git_branch ~= "" then
				msg = msg .. "  |  GIT: " .. git_branch
			else
				msg = msg .. "  |  GIT: N/A" -- Indicate when not in a Git repo
			end

			return msg
		end

		-- Send config to alpha
		alpha.setup(dashboard.opts)
		-- Disable folding on alpha buffer
		vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
	end,
}
