return {
	filetypes = { "typescript", "typescriptreact" },
	resolve = function(ctx)
		return { "bun", "run", ctx.file }, ctx.dir
	end,
	test = function(ctx)
		return { "bun", "test" }, ctx.root("package.json")
	end,
	-- stack frames: "at fn (/abs/file.ts:3:7)" and "at /abs/file.ts:3:7", minus runtime internals
	errorformat = "%-G%.%#node:%.%#,%-G%.%#bun:%.%#,%.%#at\\ %.%#(%f:%l:%c),%.%#at\\ %f:%l:%c",
}
