-- molten-nvim: run Jupyter cells inside Neovim with inline output (plots via image.nvim)
-- Notebook / ML workflow. Pairs with jupytext.lua (edit .ipynb as text) and ui/image.lua.
--
-- Per-project setup (uv):
--   uv add ipykernel numpy pandas matplotlib scikit-learn
--   uv run python -m ipykernel install --user --name <project-name>
-- Then in Neovim:  <leader>ji  -> pick the kernel  ->  <leader>jl to run a line
--
-- Host deps live in the pyenv interpreter used by g:python3_host_prog
-- (pynvim, jupyter_client, jupytext, nbformat — already installed).
return {
	"benlubas/molten-nvim",
	version = "^1.0.0",
	build = ":UpdateRemotePlugins", -- registers the remote (python) plugin
	dependencies = { "3rd/image.nvim" },
	ft = { "python", "markdown", "quarto" },
	init = function()
		-- These MUST be set before the plugin loads.
		vim.g.molten_image_provider = "image.nvim"
		vim.g.molten_output_win_max_height = 20
		vim.g.molten_auto_open_output = false -- don't auto-cover the buffer; use <leader>jo
		vim.g.molten_wrap_output = true
		vim.g.molten_virt_text_output = true -- show output as virtual text under the cell
		vim.g.molten_virt_lines_off_by_1 = true
		vim.g.molten_use_border_highlights = true
		-- vim.g.molten_output_win_hide_on_leave = false

		-- Molten writes the kernel connection file to <jupyter_data>/runtime/ but does
		-- NOT create that dir (runtime.py:63-66). On a fresh machine it won't exist
		-- until the first `jupyter` command runs, so MoltenInit fails with ENOENT.
		-- Ensure it exists. (macOS path; Jupyter also honors JUPYTER_RUNTIME_DIR.)
		if vim.fn.has("mac") == 1 then
			vim.fn.mkdir(vim.fn.expand("~/Library/Jupyter/runtime"), "p")
		end
	end,
	config = function()
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
		end

		-- Cell helpers: treat `# %%` lines as cell boundaries (like Jupyter/VSCode).
		-- Any lines before the first marker count as an implicit first cell.
		local function get_cells()
			local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			local starts = {}
			for i, line in ipairs(lines) do
				if line:match("^%s*# %%%%") then
					starts[#starts + 1] = i
				end
			end
			if #starts == 0 or starts[1] > 1 then
				table.insert(starts, 1, 1) -- implicit first cell starting at line 1
			end
			local cells = {}
			for idx, s in ipairs(starts) do
				local e = starts[idx + 1] and (starts[idx + 1] - 1) or #lines
				cells[#cells + 1] = { s = s, e = e }
			end
			return cells
		end

		-- The kernel inherits NEOVIM's cwd, so sys.path[0] is the project root, not
		-- the buffer's directory. A script that imports a package sitting next to it
		-- (learningDemo/01.python_fundamentals/06.modules/01.imports.py ->
		-- `import greetings`) then dies with ModuleNotFoundError, even though
		-- `python 01.imports.py` works — because running a FILE puts that file's
		-- directory on sys.path and a kernel does not. Put it there ourselves, once
		-- per directory, just before the first cell from that directory runs.
		local synced_dir = nil
		local function sync_sys_path()
			local dir = vim.fn.expand("%:p:h")
			if dir == "" or dir == synced_dir then
				return
			end
			synced_dir = dir
			pcall(
				vim.cmd,
				string.format(
					'MoltenEvaluateArgument import sys; sys.path.insert(0, "%s") if "%s" not in sys.path else None',
					dir,
					dir
				)
			)
		end

		-- A fresh kernel has a fresh sys.path, so forget what we synced into the old one.
		vim.api.nvim_create_autocmd("User", {
			pattern = { "MoltenKernelReady", "MoltenDeinitPost" },
			callback = function()
				synced_dir = nil
			end,
			desc = "Molten: re-sync sys.path into the new kernel",
		})

		-- Molten exposes EvaluateRange as a function taking 1-indexed (start, end) lines.
		-- It runs the kernel check itself, so this works even right after MoltenInit.
		local function eval_range(s, e)
			sync_sys_path()
			pcall(vim.fn.MoltenEvaluateRange, s, e)
		end

		local function run_current_cell()
			local cur = vim.api.nvim_win_get_cursor(0)[1]
			for _, c in ipairs(get_cells()) do
				if cur >= c.s and cur <= c.e then
					eval_range(c.s, c.e)
					return
				end
			end
		end

		local function run_all_cells()
			for _, c in ipairs(get_cells()) do
				eval_range(c.s, c.e)
			end
		end

		local function run_cells_to_cursor()
			local cur = vim.api.nvim_win_get_cursor(0)[1]
			for _, c in ipairs(get_cells()) do
				if c.s <= cur then -- every cell starting at/above the cursor (incl. current)
					eval_range(c.s, c.e)
				end
			end
		end

		-- <leader>j = "jupyter" (note: <leader>jj is markdown headings, left intact)
		map("n", "<leader>ji", ":MoltenInit<CR>", "Molten: init / pick kernel")
		map("n", "<leader>jl", function()
			sync_sys_path()
			vim.cmd("MoltenEvaluateLine")
		end, "Molten: run line")
		map("n", "<leader>jr", ":MoltenReevaluateCell<CR>", "Molten: re-run cell")
		map("n", "<leader>je", ":MoltenEvaluateOperator<CR>", "Molten: run (operator/motion)")
		-- Run visual selection, then restore the selection
		map("v", "<leader>jv", ":<C-u>MoltenEvaluateVisual<CR>gv", "Molten: run selection")
		map("n", "<leader>jo", ":MoltenShowOutput<CR>", "Molten: show output")
		map("n", "<leader>jh", ":MoltenHideOutput<CR>", "Molten: hide output")
		map("n", "<leader>jO", ":noautocmd MoltenEnterOutput<CR>", "Molten: enter output window")
		map("n", "<leader>jd", ":MoltenDelete<CR>", "Molten: delete cell")
		map("n", "<leader>jx", ":MoltenInterrupt<CR>", "Molten: interrupt kernel")
		map("n", "<leader>jR", ":MoltenRestart!<CR>", "Molten: restart kernel")

		-- The notebook essentials: run a cell, run everything, run everything above.
		map("n", "<leader>jc", run_current_cell, "Molten: run current cell")
		map("n", "<leader>ja", run_all_cells, "Molten: run ALL cells")
		map("n", "<leader>ju", run_cells_to_cursor, "Molten: run cells up to cursor")
		map("n", "<leader>jf", function()
			-- file save
			vim.cmd("write")

			local file = vim.fn.expand("%:p")
			-- 1. showing at noti
			vim.system({ "uv", "run", "python", file }, { text = true }, function(result)
				vim.schedule(function()
					vim.notify(result.stdout .. result.stderr)
				end)
			end)

			-- 2 showing split terminal
			vim.cmd("botright split | terminal uv run python " .. vim.fn.shellescape(file))

			-- q = close this terminal window
			vim.keymap.set("n", "q", "<cmd>close<CR>", {
				buffer = true,
				silent = true,
			})
		end, "Python: save and run file")
	end,
}
