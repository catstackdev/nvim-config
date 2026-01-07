-- set leader key to space
vim.g.mapleader = " "
local mySignature = "Cyber Cat"

local keymap = vim.keymap -- for conciseness

---------------------
-- General Keymaps -------------------

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

--use W mean write all  ------- ----------------------------add by 3
keymap.set("n", "<leader>wa", "<cmd>wall<CR>", { desc = "Save all files in this root dir" })
keymap.set("n", "<leader>wqa", "<cmd>wall<CR>:qall<CR>", { desc = "Save all files and quit" })
keymap.set("n", "<leader>wf", "<cmd>w<CR>", { desc = "Save only this files" })
keymap.set("n", "<leader>qf", "<cmd>q<CR>", { desc = "quit only this files" })
keymap.set("n", "<leader>qa", "<cmd>qall<CR>", { desc = "quit all ,exit all" })
keymap.set("n", "<leader>q!", "<cmd>qall!<CR>", { desc = "quit all no save ,exit all no save" })

keymap.set("n", "<leader>lzo", "<cmd>Lazy<CR>", { desc = "Open Lazy" })
keymap.set("n", "<leader>lzu", "<cmd>Lazy update<CR>", { desc = "Update Lazy" })

keymap.set("n", "<leader>mn", "<cmd>Mason<CR>", { desc = "Update Lazy" })

keymap.set("n", "<leader>lp", "<cmd>LspInfo<CR>", { desc = "open LspInfo" })

-- wlear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- delete single character without copying into register
keymap.set("n", "x", '"_x')

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

keymap.set("n", "<leader>uk", '<cmd>lua require("kubectl").toggle()<cr>', { noremap = true, silent = true })
-- keymap.del({ "o", "x" }, "R")
--
-- vim.keymap.set("n", "<leader>sd", function()
-- 	require("snacks.dashboard").open()
-- end, { desc = "Open Snacks Dashboard" })
-- NOTE: Removed global 'gd' keybinding - it conflicts with LSP-specific binding in lsp.lua
-- The LspAttach autocmd in lsp.lua sets buffer-local gd when LSP attaches
-- This ensures gd works correctly with LSP servers like angularls, ts_ls, etc.

-- NOTE: Also removed global <leader>ca - it's already defined in lsp.lua with buffer scope

keymap.set("n", "<leader>qf", function()
	vim.lsp.buf.code_action({
		context = { only = { "quickfix" } },
		apply = true,
	})
end, { desc = "Apply Quick Fix (Auto Import)" })

local imports = require("cybercat.utils.import")
-- Individual import actions
vim.keymap.set("n", "<leader>ai", imports.add_missing_imports, {
	desc = "Add missing imports",
})

vim.keymap.set("n", "<leader>ri", imports.remove_unused_imports, {
	desc = "Remove unused imports",
})

vim.keymap.set("n", "<leader>oi", imports.organize_imports, {
	desc = "Organize imports",
})

-- Combined actions (recommended)
vim.keymap.set("n", "<leader>fi", imports.fix_all_imports, {
	desc = "Fix all imports (add + remove + organize)",
})

vim.keymap.set("n", "<leader>fa", imports.fix_all, {
	desc = "Fix all (imports + code issues)",
})

-- Debugging & stats
vim.keymap.set("n", "<leader>ad", imports.debug_code_actions, {
	desc = "Debug code actions",
})

vim.keymap.set("n", "<leader>is", imports.import_stats, {
	desc = "Show import statistics",
})

local function apply_action(kind, next_fn)
	local params = vim.lsp.util.make_range_params()
	params.context = {
		only = { kind },
		diagnostics = {}, -- <- prevents LS error
	}

	vim.lsp.buf_request(bufnr, "textDocument/codeAction", params, function(err, actions)
		if err then
			vim.notify("LSP code action error: " .. err.message, vim.log.levels.ERROR)
		elseif actions and not vim.tbl_isempty(actions) then
			for _, action in ipairs(actions) do
				if action.edit then
					vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
				elseif action.command then
					vim.lsp.buf.execute_command(action.command)
				end
			end
			vim.notify(kind .. " applied!", vim.log.levels.INFO)
		else
			-- vim.notify("No '" .. kind .. "' action available", vim.log.levels.INFO)
		end
		if next_fn then
			next_fn()
		end
	end)
end

keymap.set("n", "<leader>fi", function()
	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.lsp.buf_is_attached(bufnr) then
		vim.notify("No language server attached", vim.log.levels.WARN)
		return
	end

	-- Step by step sequence
	apply_action("source.addMissingImports", function()
		apply_action("source.removeUnusedImports", function()
			apply_action("source.organizeImports", function()
				-- you can chain more actions here
			end)
		end)
	end)
end, { desc = "Add, remove unused, and organize imports" })

keymap.set("n", "<leader>fa", function()
	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.lsp.buf_is_attached(bufnr) then
		vim.notify("No language server attached", vim.log.levels.WARN)
		return
	end

	-- Step by step sequence
	apply_action("source.addMissingImports", function()
		apply_action("source.removeUnusedImports", function()
			apply_action("source.organizeImports", function()
				apply_action("source.fixAll") -- Step 4: run all available fixes
				-- you can chain more actions here
			end)
		end)
	end)
end, { desc = "fix all including code" })

-- Git commit with AI auto-generate (use terminal git commit which works)
vim.keymap.set("n", "<leader>gc", function()
  -- Close lazygit if open
  vim.cmd("q")
  -- Run git commit in terminal which triggers auto-generate
  vim.cmd("terminal git commit")
  vim.cmd("startinsert")
end, { desc = "Git commit with AI (terminal)" })
