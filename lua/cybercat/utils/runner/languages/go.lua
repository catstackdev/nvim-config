return {
	filetypes = { "go" },
	resolve = function(ctx)
		return { "go", "run", ctx.file }, ctx.dir
	end,
	-- go test prints paths relative to the package dir, so test that package
	test = function(ctx)
		return { "go", "test", "." }, ctx.dir
	end,
	errorformat = "%-G#%.%#,%f:%l:%c: %m,%f:%l: %m,%\\s%#%f:%l: %m",
}
