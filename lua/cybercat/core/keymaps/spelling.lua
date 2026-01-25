-- Spell checking keymaps
local keymap = vim.keymap

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Keymap to switch spelling language to English lamw25wmal
-- To save the language settings configured on each buffer, you need to add
-- "localoptions" to vim.opt.sessionoptions in the `lua/config/options.lua` file
-- vim.keymap.set("n", "<leader>msle", function()
-- 	vim.opt.spelllang = "en"
-- 	vim.cmd("echo 'Spell language set to English'")
-- end, { desc = "[P]Spelling language English" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Keymap to switch spelling language to Spanish lamw25wmal
-- vim.keymap.set("n", "<leader>msls", function()
-- 	vim.opt.spelllang = "es"
-- 	vim.cmd("echo 'Spell language set to Spanish'")
-- end, { desc = "[P]Spelling language Spanish" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Keymap to switch spelling language to both spanish and english lamw25wmal
-- vim.keymap.set("n", "<leader>mslb", function()
-- 	vim.opt.spelllang = "en,es"
-- 	vim.cmd("echo 'Spell language set to Spanish and English'")
-- end, { desc = "[P]Spelling language Spanish and English" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Show spelling suggestions / spell suggestions
-- NOTE: I changed this to accept the first spelling suggestion
vim.keymap.set("n", "<leader>mss", function()
	-- Simulate pressing "z=" with "m" option using feedkeys
	-- vim.api.nvim_replace_termcodes ensures "z=" is correctly interpreted
	-- 'm' is the {mode}, which in this case is 'Remap keys'. This is default.
	-- If {mode} is absent, keys are remapped.
	--
	-- I tried this keymap as usually with
	vim.cmd("normal! 1z=")
	-- But didn't work, only with nvim_feedkeys
	-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("z=", true, false, true), "m", true)
end, { desc = "[P]Spelling suggestions" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- markdown good, accept spell suggestion
-- Add word under the cursor as a good word
vim.keymap.set("n", "<leader>msg", function()
	vim.cmd("normal! zg")
	-- I do a write so that harper is updated
	vim.cmd("silent write")
end, { desc = "[P]Spelling add word to spellfile" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Undo zw, remove the word from the entry in 'spellfile'.
vim.keymap.set("n", "<leader>msu", function()
	vim.cmd("normal! zug")
end, { desc = "[P]Spelling undo, remove word from list" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Repeat the replacement done by |z=| for all matches with the replaced word
-- in the current window.
vim.keymap.set("n", "<leader>msr", function()
	-- vim.cmd(":spellr")
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":spellr\n", true, false, true), "m", true)
end, { desc = "[P]Spelling repeat" })

-- Surround the http:// url that the cursor is currently in with ``
vim.keymap.set("n", "gsu", function()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- Adjust for 0-index in Lua
	-- This makes the `s` optional so it matches both http and https
	local pattern = "https?://[^ ,;'\"<>%s)]*"
	-- Find the starting and ending positions of the URL
	local s, e = string.find(line, pattern)
	while s and e do
		if s <= col and e >= col then
			-- When the cursor is within the URL
			local url = string.sub(line, s, e)
			-- Update the line with backticks around the URL
			local new_line = string.sub(line, 1, s - 1) .. "`" .. url .. "`" .. string.sub(line, e + 1)
			vim.api.nvim_set_current_line(new_line)
			vim.cmd("silent write")
			return
		end
		-- Find the next URL in the line
		s, e = string.find(line, pattern, e + 1)
		-- Save the file to update trouble list
	end
	print("No URL found under cursor")
end, { desc = "[P]Add surrounding to URL" })