-- Test coverage in the sign column. For Go it reads coverage.out in the project
-- root; <leader>tcr makes that file for the current package and shows it.
local GO_COVERAGE_FILE = "coverage.out"

--- `go test -coverprofile` for the current file's package (whole project outside Go files),
--- then show the result as signs.
local function run_go_coverage()
	local relative_dir = vim.fn.fnamemodify(vim.fn.expand("%:p:h"), ":.")
	local target = "./..."
	if vim.bo.filetype == "go" then
		target = relative_dir == "." and "." or "./" .. relative_dir
	end

	vim.notify("Coverage: go test " .. target)
	vim.system(
		{ "go", "test", "-coverprofile=" .. GO_COVERAGE_FILE, target },
		{ text = true, cwd = vim.fn.getcwd() },
		vim.schedule_wrap(function(result)
			if vim.uv.fs_stat(vim.fn.getcwd() .. "/" .. GO_COVERAGE_FILE) then
				require("coverage").load(true)
			end
			if result.code ~= 0 then
				vim.notify("go test failed:\n" .. (result.stdout or ""):sub(-500), vim.log.levels.WARN)
			end
		end)
	)
end

return {
	"andythigpen/nvim-coverage",
	version = "*",
	dependencies = { "nvim-lua/plenary.nvim" },
	cmd = {
		"Coverage",
		"CoverageLoad",
		"CoverageShow",
		"CoverageHide",
		"CoverageToggle",
		"CoverageClear",
		"CoverageSummary",
	},
	opts = {
		lang = { go = { coverage_file = GO_COVERAGE_FILE } },
	},
	keys = {
		{ "<leader>tcr", run_go_coverage, desc = "Coverage: run tests and show" },
		{ "<leader>tct", "<cmd>CoverageToggle<cr>", desc = "Coverage: show/hide signs" },
		{ "<leader>tcs", "<cmd>CoverageSummary<cr>", desc = "Coverage: summary" },
		{ "<leader>tcx", "<cmd>CoverageClear<cr>", desc = "Coverage: clear" },
	},
}
