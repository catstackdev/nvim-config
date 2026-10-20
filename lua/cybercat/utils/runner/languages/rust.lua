-- #[test], #[tokio::test], #[tokio::test(...)] but not #[cfg(test)]
local function isTestFn(fn)
	local sibling = fn:prev_sibling()
	while sibling and (sibling:type() == "attribute_item" or sibling:type() == "line_comment") do
		if
			sibling:type() == "attribute_item"
			and vim.treesitter.get_node_text(sibling, 0):match("^#%[[%w_:]*test[%]%(]")
		then
			return true
		end
		sibling = sibling:prev_sibling()
	end
	return false
end

local function nodeName(node)
	local name = node:field("name")[1]
	return name and vim.treesitter.get_node_text(name, 0)
end

-- "tests::adds" for #[test] fn adds inside `mod tests`; cargo matches it as a substring
local function testPathAtCursor()
	local ok, node = pcall(vim.treesitter.get_node)
	if not ok or not node then
		return nil
	end
	while node and not (node:type() == "function_item" and isTestFn(node)) do
		node = node:parent()
	end
	if not node then
		return nil
	end
	local parts = { nodeName(node) }
	local parent = node:parent()
	while parent do
		if parent:type() == "mod_item" then
			table.insert(parts, 1, nodeName(parent))
		end
		parent = parent:parent()
	end
	return table.concat(parts, "::")
end

-- cargo infers the package from cwd, so a workspace member runs on its own
return {
	filetypes = { "rust" },
	testNearest = function(ctx)
		local path = testPathAtCursor()
		if not path then
			vim.notify("Cursor is not inside a #[test] function", vim.log.levels.WARN)
			return nil
		end
		return { "cargo", "test", path }, ctx.root("Cargo.toml")
	end,
	-- tests/foo.rs is its own test binary; src/a/b.rs maps to module a::b
	testInFile = function(ctx)
		local root = ctx.root("Cargo.toml")
		local rel = ctx.file:sub(#root + 2):gsub("%.rs$", "")
		local integration = rel:match("^tests/([^/]+)$")
		if integration then
			return { "cargo", "test", "--test", integration }, root
		end
		local module = rel:gsub("^src/", ""):gsub("/mod$", "")
		if module == "lib" or module == "main" then
			return { "cargo", "test" }, root
		end
		return { "cargo", "test", (module:gsub("/", "::")) }, root
	end,
	resolve = function(ctx)
		-- -q hides cargo's Compiling/Finished/Running lines; errors still print
		return { "cargo", "run", "-q" }, ctx.root("Cargo.toml")
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
