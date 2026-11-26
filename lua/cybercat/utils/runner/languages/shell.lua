return {
	filetypes = { "sh", "bash", "zsh" },
	-- 1. filetype
	-- resolve = function(ctx)
	-- 	local shell = vim.bo.filetype == "zsh" and "zsh" or "bash"
	-- 	return { shell, ctx.file }, ctx.dir
	-- end,
	-- "script.sh: line 3: cmd: command not found"
	-- 2. shebang
	resolve = function(ctx)
		local file = ctx.file

		local f = io.open(file, "r")
		if not f then
			return { "bash", file }, ctx.dir
		end

		local first_line = f:read("*l") or ""
		f:close()

		local shell

		if first_line:match("^#!/.*zsh") then
			shell = "zsh"
		elseif first_line:match("^#!/.*bash") then
			shell = "bash"
		elseif first_line:match("^#!/.*sh") then
			shell = "sh"
		else
			shell = vim.bo.filetype == "zsh" and "zsh" or "bash"
		end

		return { shell, file }, ctx.dir
	end,
	errorformat = "%f:\\ line\\ %l:\\ %m",
}
