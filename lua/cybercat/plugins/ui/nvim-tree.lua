-- :h nvim-tree > options (ctrl + ])  i alreaaaady nvim-tree
return {
	"nvim-tree/nvim-tree.lua",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		local nvimtree = require("nvim-tree")

		-- recommended settings from nvim-tree documentation
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
		-- -- change color for arrows in tree to light blue
		-- vim.cmd([[ highlight NvimTreeFolderArrowClosed guifg=#3FC5FF ]])
		-- vim.cmd([[ highlight NvimTreeFolderArrowOpen guifg=#3FC5FF ]])

		local function get_node_path()
			local api = require("nvim-tree.api")
			local node = api.tree.get_node_under_cursor()
			if not node or node.type == "directory" then
				return nil, nil
			end
			local path = node.absolute_path
			local ext = path:match("%.(%w+)$")
			return path, ext and ext:lower() or ""
		end

		local function preview_node()
			local path, ext = get_node_path()
			if not path then
				return
			end

			local images =
				{ png = true, jpg = true, jpeg = true, gif = true, webp = true, svg = true, bmp = true, ico = true }
			local videos = { mp4 = true, mov = true, avi = true, mkv = true, webm = true }
			local audio = { mp3 = true, flac = true, wav = true, aac = true, ogg = true, m4a = true }
			local ql = { pdf = true, ttf = true, otf = true, woff = true, zip = true, dmg = true }

			local name = vim.fn.fnamemodify(path, ":t")

			if images[ext] then
				if os.getenv("TMUX") then
					vim.fn.jobstart({ "qlmanage", "-p", path }, { detach = true })
				else
					vim.cmd("split | terminal wezterm imgcat " .. vim.fn.shellescape(path))
				end
			elseif videos[ext] then
				vim.fn.jobstart({ "mpv", path }, { detach = true })
				vim.notify("▶ mpv: " .. name, vim.log.levels.INFO)
			elseif audio[ext] then
				-- afplay is macOS built-in, no GUI window, plays in background
				vim.fn.jobstart({ "afplay", path }, { detach = true })
				vim.notify("♪ playing: " .. name, vim.log.levels.INFO)
			elseif ql[ext] then
				vim.fn.jobstart({ "qlmanage", "-p", path }, { detach = true })
			else
				vim.notify("No preview for ." .. ext, vim.log.levels.WARN)
			end
		end

		local function stop_audio()
			vim.fn.jobstart({ "pkill", "-x", "afplay" }, { detach = true })
			vim.notify("♪ stopped", vim.log.levels.INFO)
		end

		local function open_system()
			local path, _ = get_node_path()
			if not path then
				return
			end
			vim.fn.jobstart({ "open", path }, { detach = true })
		end

		local function on_attach(bufnr)
			local api = require("nvim-tree.api")
			api.config.mappings.default_on_attach(bufnr)
			local map = function(key, fn, desc)
				vim.keymap.set("n", key, fn, { buffer = bufnr, desc = desc, nowait = true })
			end
			map("v", preview_node, "Preview / Play file")
			map("V", stop_audio, "Stop audio (afplay)")
			map("O", open_system, "Open with system default app")
		end

		nvimtree.setup({
			on_attach = on_attach,
			view = {
				-- width = 35,
				width = 40,
				relativenumber = true,
			},
			-- change folder arrow icons
			renderer = {
				indent_markers = {
					enable = true,
				},
				icons = {
					glyphs = {
						folder = {
							arrow_closed = "", -- arrow when folder is closed
							arrow_open = "", -- arrow when folder is open
						},
					},
				},
			},
			-- disable window_picker for
			-- explorer to work well with
			-- window splits
			actions = {
				open_file = {
					window_picker = {
						enable = false,
					},
				},
			},
			filters = {
				custom = { ".DS_Store" },
			},
			git = {
				ignore = false,
			},
		})

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
		keymap.set(
			"n",
			"<leader>ef",
			"<cmd>NvimTreeFindFileToggle<CR>",
			{ desc = "Toggle file explorer on current file" }
		) -- toggle file explorer on current file
		keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" }) -- collapse file explorer
		keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" }) -- refresh file explorer
		keymap.set("n", "<leader><tab>", "<cmd>NvimTreeFocus<CR>", { desc = "goto file explorer" }) -- toggle file explorer
	end,
}
