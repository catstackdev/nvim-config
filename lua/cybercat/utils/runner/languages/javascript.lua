return {
	filetypes = { "javascript", "javascriptreact" },
	resolve = function(ctx)
		return { "node", ctx.file }, ctx.dir
	end,
	test = function(ctx)
		return { "bun", "test" }, ctx.root("package.json")
	end,
	-- stack frames: "at fn (/abs/file.js:3:7)" and "at /abs/file.js:3:7", minus runtime internals
	errorformat = "%-G%.%#node:%.%#,%-G%.%#bun:%.%#,%.%#at\\ %.%#(%f:%l:%c),%.%#at\\ %f:%l:%c",
}
