return {
	filetypes = { "lua" },
	resolve = function(ctx)
		return { "nvim", "-l", ctx.file }, ctx.dir
	end,
	-- "path/file.lua:3: message"
	errorformat = "%f:%l: %m",
}
