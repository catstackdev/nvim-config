-- Python Language Server (Pyright)
-- Optimized for AI/ML development with LangChain, LlamaIndex, FastAPI
local util = require("lspconfig.util")

local function get_python_path(workspace)
	-- Check for .venv (uv/venv standard)
	if vim.fn.executable(workspace .. "/.venv/bin/python") == 1 then
		return workspace .. "/.venv/bin/python"
	end

	-- Check for venv
	if vim.fn.executable(workspace .. "/venv/bin/python") == 1 then
		return workspace .. "/venv/bin/python"
	end

	-- Check for VIRTUAL_ENV environment variable
	if vim.env.VIRTUAL_ENV then
		return vim.env.VIRTUAL_ENV .. "/bin/python"
	end

	-- Fallback to pyenv global or system python
	return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
end

return {
	before_init = function(_, config)
		config.settings.python.pythonPath = get_python_path(config.root_dir)
	end,
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly",
				typeCheckingMode = "basic", -- Not strict - good for AI frameworks
				-- Enable auto-import completions
				autoImportCompletions = true,
				-- Stub path for type stubs (helps with AI libraries)
				stubPath = "typings",
				-- Diagnostics settings (relaxed for AI development)
				diagnosticSeverityOverrides = {
					reportUnusedImport = "warning",
					reportUnusedVariable = "warning",
					reportDuplicateImport = "warning",
					-- Relax these for AI frameworks (they use dynamic imports)
					reportMissingImports = "warning",
					reportMissingTypeStubs = "none",
					reportGeneralTypeIssues = "warning",
					reportOptionalMemberAccess = "warning",
					reportOptionalSubscript = "warning",
				},
				-- Inlay hints (great for learning FastAPI routes)
				inlayHints = {
					variableTypes = true,
					functionReturnTypes = true,
					callArgumentNames = true,
					parameterNames = true,
				},
			},
		},
	},
}
