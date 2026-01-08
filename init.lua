vim.g.neovim_mode = vim.env.NEOVIM_MODE or "default"
vim.g.md_heading_bg = vim.env.MD_HEADING_BG

require("cybercat.core")
require("cybercat.lazy")
require("cybercat.lsp")
require("cybercat.cybercat-app")

if vim.g.neovim_mode == "skitty" then
	vim.wait(500, function()
		return false
	end) -- Wait for X miliseconds without doing anything
end

-- DEBUG: Test if gitcommit autocmd fires
-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = "gitcommit",
-- 	callback = function()
-- 		vim.notify("🔥 DEBUG: gitcommit filetype detected!", vim.log.levels.ERROR)
-- 	end,
-- })
-- DEBUG: Show filetype for commit-related buffers
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = { "COMMIT_EDITMSG", "*.git/COMMIT_EDITMSG", "*COMMIT_EDITMSG*" },
	callback = function()
		vim.defer_fn(function()
			local ft = vim.bo.filetype
			vim.notify(string.format("🔍 Buffer opened! Filetype: '%s'", ft), vim.log.levels.WARN)
		end, 100)
	end,
})
