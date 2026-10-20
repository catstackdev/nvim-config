return {
	filetypes = { "sh", "bash", "zsh" },
	resolve = function(ctx)
		local shell = vim.bo.filetype == "zsh" and "zsh" or "bash"
		return { shell, ctx.file }, ctx.dir
	end,
	-- "script.sh: line 3: cmd: command not found"
	errorformat = "%f:\\ line\\ %l:\\ %m",
}
