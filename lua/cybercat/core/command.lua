vim.api.nvim_create_user_command("OpenChatUI", function()
	require("cybercat.ui.chat_ui").create_ui()
end, {})

-- Start Tree-sitter highlighting for markdown buffers automatically
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(args)
		vim.treesitter.start(args.buf, "markdown")
		vim.schedule(function()
			local parser = vim.treesitter.get_parser(0, "markdown")
			if not parser then
				print("No parser yet")
			end
		end)
	end,
})

-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = "markdown",
-- 	callback = function()
-- 		-- Start Tree-sitter highlighting
-- 		vim.treesitter.start()
-- 	end,
-- })
vim.api.nvim_create_autocmd("FileType", {
	pattern = "Outline",
	callback = function()
		vim.keymap.set("n", "K", function()
			local params = vim.lsp.util.make_position_params()
			if params then
				vim.lsp.buf.hover()
			else
				vim.notify("No symbol under cursor", vim.log.levels.WARN)
			end
		end, { buffer = true, silent = true })
	end,
})
