-- cargo infers the package from cwd, so a workspace member runs on its own
return {
	filetypes = { "rust" },
	resolve = function(ctx)
		return { "cargo", "run" }, ctx.root("Cargo.toml")
	end,
	test = function(ctx)
		return { "cargo", "test" }, ctx.root("Cargo.toml")
	end,
	-- cargo prints paths relative to the workspace root (the outermost Cargo.toml)
	errorRoot = function(ctx)
		local manifests = vim.fs.find("Cargo.toml", { upward = true, path = ctx.dir, limit = math.huge })
		return manifests[#manifests] and vim.fs.dirname(manifests[#manifests]) or ctx.dir
	end,
	errorformat = table.concat({
		"%-G",
		"%-Gerror: aborting %.%#",
		"%-Gerror: could not compile %.%#",
		"%Eerror: %m",
		"%Eerror[E%n]: %m",
		"%Wwarning: %m",
		"%Inote: %m",
		"%C\\ %#-->\\ %f:%l:%c",
		"%Ethread\\ '%.%#'%.%#panicked\\ at\\ %f:%l:%c:,%Z%m",
	}, ","),
}
