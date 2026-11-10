-- Rust: codelldb from Mason. `cargo build` runs first and the binary is read
-- from cargo's own JSON output, so it works for any crate/bin name.
local M = {}

---@return string?
local function findCargoRoot()
	local manifest = vim.fs.find("Cargo.toml", { upward = true, path = vim.fn.expand("%:p:h") })[1]
	return manifest and vim.fs.dirname(manifest) or nil
end

---@return string?
local function buildAndPickExecutable()
	local root = findCargoRoot()
	if not root then
		vim.notify("No Cargo.toml found above the current file", vim.log.levels.ERROR)
		return nil
	end

	local result = vim.system({ "cargo", "build", "--message-format=json" }, { cwd = root, text = true }):wait()
	if result.code ~= 0 then
		vim.notify("cargo build failed:\n" .. (result.stderr or ""), vim.log.levels.ERROR)
		return nil
	end

	local executables = {}
	for line in vim.gsplit(result.stdout or "", "\n", { plain = true }) do
		local ok, message = pcall(vim.json.decode, line)
		if ok and type(message) == "table" and message.executable and message.target then
			if vim.tbl_contains(message.target.kind or {}, "bin") then
				table.insert(executables, message.executable)
			end
		end
	end

	if #executables == 0 then
		return vim.fn.input("Path to executable: ", root .. "/target/debug/", "file")
	end
	if #executables == 1 then
		return executables[1]
	end

	local choice = vim.fn.inputlist(vim.list_extend(
		{ "Select binary:" },
		vim.tbl_map(function(path)
			return vim.fn.fnamemodify(path, ":t")
		end, executables)
	))
	return executables[choice]
end

function M.setup()
	local codelldb = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"
	if vim.fn.executable(codelldb) ~= 1 then
		vim.notify("codelldb not found! Run :Mason to install", vim.log.levels.WARN)
		return
	end

	local dap = require("dap")
	dap.adapters.codelldb = {
		type = "server",
		port = "${port}",
		executable = { command = codelldb, args = { "--port", "${port}" } },
	}

	dap.configurations.rust = {
		{
			name = "Launch (cargo build)",
			type = "codelldb",
			request = "launch",
			program = buildAndPickExecutable,
			cwd = function()
				return findCargoRoot() or vim.fn.getcwd()
			end,
			stopOnEntry = false,
		},
	}
end

return M
