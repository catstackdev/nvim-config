return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")
		local lazy_status = require("lazy.status") -- to configure lazy pending updates count

		local colors = {
			blue = "#65D1FF",
			green = "#3EFFDC",
			violet = "#FF61EF",
			yellow = "#FFDA7B",
			red = "#FF4A4A",
			fg = "#c3ccdc",
			bg = "#112638",
			inactive_bg = "#2c3043",
			semilightgray = "#828997",
		}

		local my_lualine_theme = {
			normal = {
				a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			insert = {
				a = { bg = colors.green, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			visual = {
				a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			command = {
				a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			replace = {
				a = { bg = colors.red, fg = colors.bg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			inactive = {
				a = { bg = colors.inactive_bg, fg = colors.semilightgray, gui = "bold" },
				b = { bg = colors.inactive_bg, fg = colors.semilightgray },
				c = { bg = colors.inactive_bg, fg = colors.semilightgray },
			},
		}

		-- AI and helper clients attach to nearly every buffer, so they are not worth showing
		local LSP_NAMES_IGNORED = { copilot = true, codeium = true, ["null-ls"] = true, ["none-ls"] = true }
		local LSP_NAMES_SHOWN = 3

		local function lspNames()
			local names = {}
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
				if not LSP_NAMES_IGNORED[client.name] then
					names[#names + 1] = client.name
				end
			end
			return names
		end

		-- Commits ahead/behind the upstream ("↑2 ↓1"), refreshed in the background
		local GIT_SYNC_THROTTLE_MS = 5000
		local gitSync = ""
		local gitSyncCheckedAt = 0

		local function refreshGitSync()
			local now = vim.uv.now()
			if now - gitSyncCheckedAt < GIT_SYNC_THROTTLE_MS then
				return
			end
			gitSyncCheckedAt = now
			vim.system(
				{ "git", "rev-list", "--left-right", "--count", "@{upstream}...HEAD" },
				{ text = true, cwd = vim.fn.getcwd() },
				vim.schedule_wrap(function(result)
					local behind, ahead = (result.stdout or ""):match("(%d+)%s+(%d+)")
					local parts = {}
					if result.code == 0 and tonumber(ahead) and tonumber(ahead) > 0 then
						parts[#parts + 1] = "↑" .. ahead
					end
					if result.code == 0 and tonumber(behind) and tonumber(behind) > 0 then
						parts[#parts + 1] = "↓" .. behind
					end
					local text = table.concat(parts, " ")
					if text ~= gitSync then
						gitSync = text
						lualine.refresh()
					end
				end)
			)
		end

		vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained", "BufEnter", "BufWritePost", "DirChanged" }, {
			group = vim.api.nvim_create_augroup("LualineGitSync", { clear = true }),
			desc = "Lualine: refresh ahead/behind counts",
			callback = refreshGitSync,
		})

		-- Name of the active python virtualenv; uv's ".venv" is named after its project
		local function virtualenvName()
			local venv = vim.env.VIRTUAL_ENV
			if not venv or venv == "" then
				return ""
			end
			local name = vim.fs.basename(venv)
			if name == ".venv" or name == "venv" then
				name = vim.fs.basename(vim.fs.dirname(venv))
			end
			return " " .. name
		end

		-- Load distant statusline component
		local distantStatusOk, distantStatus = pcall(require, "cybercat.plugins.distant-portal.statusline")
		local distantComponent = nil
		if distantStatusOk then
			distantComponent = distantStatus.component()
		end

		-- configure lualine with modified theme
		lualine.setup({
			options = {
				theme = my_lualine_theme,
				-- one statusline spanning the full editor width instead of
				-- one per split, so the full directory path always has room
				globalstatus = true,
			},
			sections = {
				lualine_b = {
					{ "branch" },
					{
						function()
							return gitSync
						end,
						cond = function()
							return gitSync ~= ""
						end,
					},
					{ "diff" },
					{ "diagnostics" },
				},
				lualine_c = {
					-- path = 1: path relative to cwd (project root), shorting_target = 0
					-- disables shortening so the directory never gets abbreviated
					{
						"filename",
						path = 1,
						shorting_target = 0,
						symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]", newfile = "[New]" },
					},
				},
				lualine_x = {
					-- Distant connection status (if available)
					distantComponent or {},
					-- This file's last run (utils/runner): "✓ 1.2s", "✗ exit 1 · 0.4s"
					{
						function()
							return require("cybercat.utils.runner").status()
						end,
						cond = function()
							return require("cybercat.utils.runner").status() ~= ""
						end,
						-- text colour only, from this bar's palette, like the other items
						color = function()
							local byGroup = {
								DiagnosticOk = colors.green,
								DiagnosticError = colors.red,
								DiagnosticWarn = colors.yellow,
							}
							return { fg = byGroup[require("cybercat.utils.runner").statusColor()] or colors.fg }
						end,
					},
					{
						lazy_status.updates,
						cond = lazy_status.has_updates,
						color = { fg = "#ff9e64" },
					},
					-- names of the language servers attached to this buffer
					{
						function()
							local names = lspNames()
							local shown = vim.list_slice(names, 1, LSP_NAMES_SHOWN)
							local hidden = #names - #shown
							return " " .. table.concat(shown, ", ") .. (hidden > 0 and (" +" .. hidden) or "")
						end,
						cond = function()
							return #lspNames() > 0
						end,
					},
					{
						virtualenvName,
						cond = function()
							return vim.bo.filetype == "python" and virtualenvName() ~= ""
						end,
					},
					-- only worth showing when they differ from the usual utf-8 / unix
					{
						"encoding",
						cond = function()
							return vim.bo.fileencoding ~= "" and vim.bo.fileencoding ~= "utf-8"
						end,
					},
					{
						"fileformat",
						cond = function()
							return vim.bo.fileformat ~= "unix"
						end,
					},
					-- dimmed, so the coloured items (run status, updates) stand out
					{ "filetype", color = { fg = colors.semilightgray } },
				},
			},
		})
	end,
}
