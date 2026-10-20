return {
	filetypes = { "python" },
	resolve = function(ctx)
		return { "uv", "run", "python", ctx.file }, ctx.dir
	end,
	test = function(ctx)
		return { "uv", "run", "pytest" }, ctx.root({ "pyproject.toml", ".git" })
	end,
	-- traceback frames, then pytest's "file.py:12: Error" lines
	errorformat = '%C %.%#,%A  File "%f"\\, line %l%.%#,%Z%[%^ ]%\\@=%m,%f:%l: %m',
}
