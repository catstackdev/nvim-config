local M = {}

-- Helper: Check if TypeScript LSP is attached
local function is_ts_lsp_attached()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	for _, client in ipairs(clients) do
		if client.name == "ts_ls" or client.name == "tsserver" or client.name == "angularls" then
			return true, client
		end
	end
	return false, nil
end

-- Helper: Execute code action by kind
local function execute_code_action(kind, callback)
	local params = vim.lsp.util.make_range_params()
	params.context = {
		only = { kind },
		diagnostics = {},
	}

	vim.lsp.buf_request(0, "textDocument/codeAction", params, function(err, actions)
		if err then
			vim.notify("LSP error: " .. vim.inspect(err), vim.log.levels.ERROR)
			return
		end

		if not actions or vim.tbl_isempty(actions) then
			if callback then
				callback(false)
			end
			return
		end

		local applied = 0
		for _, action in ipairs(actions) do
			if action.edit then
				vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
				applied = applied + 1
			elseif action.command then
				vim.lsp.buf.execute_command(action.command)
				applied = applied + 1
			end
		end

		if callback then
			callback(true, applied)
		end
	end)
end

-- Add missing imports (TypeScript/JavaScript)
M.add_missing_imports = function()
	local attached, client = is_ts_lsp_attached()
	if not attached then
		vim.notify("TypeScript LSP not attached", vim.log.levels.WARN)
		return
	end

	execute_code_action("source.addMissingImports.ts", function(success, count)
		if success then
			vim.notify(string.format("Added %d import(s)", count or 0), vim.log.levels.INFO)
		else
			vim.notify("No missing imports found", vim.log.levels.INFO)
		end
	end)
end

-- Remove unused imports
M.remove_unused_imports = function()
	local attached, client = is_ts_lsp_attached()
	if not attached then
		vim.notify("TypeScript LSP not attached", vim.log.levels.WARN)
		return
	end

	execute_code_action("source.removeUnusedImports.ts", function(success, count)
		if success then
			vim.notify("Removed unused imports", vim.log.levels.INFO)
		else
			vim.notify("No unused imports found", vim.log.levels.INFO)
		end
	end)
end

-- Organize imports (TypeScript/JavaScript)
M.organize_imports = function()
	local attached, client = is_ts_lsp_attached()
	if not attached then
		vim.notify("TypeScript LSP not attached", vim.log.levels.WARN)
		return
	end

	-- Try TypeScript organize command first
	local success = pcall(vim.lsp.buf.execute_command, {
		command = "_typescript.organizeImports",
		arguments = { vim.api.nvim_buf_get_name(0) },
	})

	if success then
		vim.notify("Imports organized", vim.log.levels.INFO)
	else
		-- Fallback to code action
		execute_code_action("source.organizeImports.ts", function(ok)
			if ok then
				vim.notify("Imports organized", vim.log.levels.INFO)
			else
				vim.notify("Failed to organize imports", vim.log.levels.WARN)
			end
		end)
	end
end

-- Fix all imports (add missing → remove unused → organize)
M.fix_all_imports = function()
	local attached, client = is_ts_lsp_attached()
	if not attached then
		vim.notify("TypeScript LSP not attached", vim.log.levels.WARN)
		return
	end

	vim.notify("Fixing imports...", vim.log.levels.INFO)

	-- Step 1: Add missing imports
	execute_code_action("source.addMissingImports.ts", function(success1)
		-- Step 2: Remove unused imports
		vim.defer_fn(function()
			execute_code_action("source.removeUnusedImports.ts", function(success2)
				-- Step 3: Organize imports
				vim.defer_fn(function()
					M.organize_imports()
				end, 100)
			end)
		end, 100)
	end)
end

-- Fix all code issues (imports + eslint fixes)
M.fix_all = function()
	local attached, client = is_ts_lsp_attached()
	if not attached then
		vim.notify("TypeScript LSP not attached", vim.log.levels.WARN)
		return
	end

	vim.notify("Fixing all issues...", vim.log.levels.INFO)

	-- Step 1: Fix imports
	execute_code_action("source.addMissingImports.ts", function()
		vim.defer_fn(function()
			execute_code_action("source.removeUnusedImports.ts", function()
				vim.defer_fn(function()
					M.organize_imports()
					-- Step 2: Fix all other issues
					vim.defer_fn(function()
						execute_code_action("source.fixAll", function(success)
							if success then
								vim.notify("All issues fixed!", vim.log.levels.INFO)
							else
								vim.notify("Import fixes applied", vim.log.levels.INFO)
							end
						end)
					end, 150)
				end, 100)
			end)
		end, 100)
	end)
end

-- Debug: Show available code actions
M.debug_code_actions = function()
	local params = vim.lsp.util.make_range_params()
	params.context = {
		diagnostics = vim.lsp.diagnostic.get_line_diagnostics(),
	}

	vim.lsp.buf_request(0, "textDocument/codeAction", params, function(err, actions)
		if err then
			print("❌ Error:", vim.inspect(err))
			return
		end

		if not actions or vim.tbl_isempty(actions) then
			print("ℹ️  No code actions available")
			return
		end

		print("📋 Available code actions:")
		for i, action in ipairs(actions) do
			print(string.format("  %d. %s", i, action.title or action.kind))
			if action.kind then
				print(string.format("     Kind: %s", action.kind))
			end
		end
	end)
end

-- Show import statistics for current file
M.import_stats = function()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local import_count = 0
	local unused_count = 0

	-- Count imports
	for _, line in ipairs(lines) do
		if line:match("^import ") or line:match("^import{") then
			import_count = import_count + 1
		end
	end

	-- Get diagnostics for unused imports
	local diagnostics = vim.diagnostic.get(0)
	for _, diag in ipairs(diagnostics) do
		if diag.message:match("is declared but") or diag.message:match("never used") then
			unused_count = unused_count + 1
		end
	end

	vim.notify(string.format("Imports: %d total, %d unused", import_count, unused_count), vim.log.levels.INFO)
end

return M
