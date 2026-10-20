-- All-in-one file runner: one keymap, any language.
-- Each language lives in runner/languages/<name>.lua and returns
--   filetypes   string[]                       filetypes it handles
--   resolve     fun(ctx) -> cmd, cwd           command to run and where
--   test        fun(ctx) -> cmd, cwd           (optional) command to run its tests
--   testNearest fun(ctx) -> cmd?, cwd          (optional) test under the cursor; nil cmd = abort
--   testInFile  fun(ctx) -> cmd?, cwd          (optional) only the tests of the current file
--   errorformat string?                        parses failures into quickfix
--   errorRoot   fun(ctx) -> string?            dir the error paths are relative to
-- To add a language: create that file and list its name in `languageModules`.
local M = {}

local languageModules = {
	"rust",
	"go",
	"python",
	"typescript",
	"javascript",
	"shell",
	"lua",
}

---@class RunnerContext
---@field file string absolute path of the current buffer
---@field dir string directory of the current buffer
---@field root fun(marker: string|string[]): string nearest ancestor holding marker, else dir

local languages = {}
local lastRun = nil
local runId = 0
local output = { win = nil, buf = nil }
-- Per file: its latest terminal buffer and status, so <leader>ro shows the right output
local runs = {} ---@type table<string, { id: integer, buf: integer, job: integer?, stopped: boolean, status: table? }>
-- Program arguments remembered per file, used by every <leader>rr of that file
local runArgs = {} ---@type table<string, string>
-- File the output was deliberately reopened from; it must not auto-close right away
local keepOpenFor = nil

for _, name in ipairs(languageModules) do
	local ok, language = pcall(require, "cybercat.utils.runner.languages." .. name)
	if ok then
		for _, ft in ipairs(language.filetypes) do
			languages[ft] = language
		end
	else
		vim.notify("Runner language failed to load: " .. name, vim.log.levels.WARN)
	end
end

local function isValidWin(win)
	return win ~= nil and vim.api.nvim_win_is_valid(win)
end

-- Last run's state, shown in the output winbar and the statusline.
-- Kept here (not just on the window) so it survives closing and reopening the output.
local lastStatus = nil

local function refreshStatusline()
	local ok, lualine = pcall(require, "lualine")
	if ok then
		lualine.refresh()
	end
end

local function setStatus(win, hl, icon, text)
	lastStatus = { hl = hl, icon = icon, text = text }
	if isValidWin(win) then
		local safe = text:gsub("%%", "%%%%")
		vim.wo[win].winbar = string.format("%%#%s# %s %s %%*", hl, icon, safe)
	end
	refreshStatusline()
end

-- "cargo test", or "bash e.sh" for a long absolute file path
local function shortLabel(cmd)
	return table.concat(
		vim.tbl_map(function(part)
			return part:sub(1, 1) == "/" and vim.fs.basename(part) or part
		end, cmd),
		" "
	)
end

-- lualine component: text of the last run, "" before the first one
function M.status()
	return lastStatus and (lastStatus.icon .. " " .. lastStatus.text) or ""
end

function M.statusColor()
	return lastStatus and lastStatus.hl or "Normal"
end

-- Reuse one output window; each run replaces the previous terminal buffer
local OUTPUT_PADDING = 2

-- Fixed height, and a blank left margin so text doesn't touch the window edge
local SHOW_LINE_NUMBERS = true

-- 'statuscolumn' replaces the number column, so numbers must be part of it:
-- padding, then a right-aligned hybrid number (absolute on the cursor line, relative elsewhere)
local function outputStatusColumn()
	local padding = string.rep(" ", OUTPUT_PADDING)
	if not SHOW_LINE_NUMBERS then
		return padding
	end
	return padding .. "%=%{v:relnum ? v:relnum : v:lnum} "
end

local function styleOutputWindow(win)
	vim.wo[win].winfixheight = true
	vim.wo[win].number = SHOW_LINE_NUMBERS
	vim.wo[win].relativenumber = SHOW_LINE_NUMBERS
	vim.wo[win].signcolumn = "no"
	vim.wo[win].statuscolumn = outputStatusColumn()
end

-- Only the same file's previous output is replaced; other files keep theirs
local function openOutputWindow(file)
	local origin = vim.api.nvim_get_current_win()
	if not isValidWin(output.win) then
		-- split the code window (not botright) so a sidebar like nvim-tree keeps its full height
		vim.cmd("belowright 15new")
		output.win = vim.api.nvim_get_current_win()
		styleOutputWindow(output.win)
	else
		vim.api.nvim_set_current_win(output.win)
		vim.cmd("enew")
	end
	local previous = runs[file] and runs[file].buf
	styleOutputWindow(output.win)
	output.buf = vim.api.nvim_get_current_buf()
	vim.bo[output.buf].bufhidden = "hide"
	if previous and previous ~= output.buf and vim.api.nvim_buf_is_valid(previous) then
		vim.api.nvim_buf_delete(previous, { force = true })
	end
	return origin
end

local function fillQuickfix(run, buf)
	if not run.errorformat or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local previousCwd = vim.fn.chdir(run.errorRoot)
	vim.fn.setqflist({}, " ", { lines = lines, efm = run.errorformat, title = table.concat(run.cmd, " ") })
	vim.fn.chdir(previousCwd)
	local count = #vim.tbl_filter(function(item)
		return item.valid == 1 and item.lnum > 0
	end, vim.fn.getqflist())
	if count > 0 then
		vim.notify(count .. " error location(s) in quickfix: ]q / [q to jump", vim.log.levels.INFO)
	end
end

local function execute(run)
	runId = runId + 1
	local thisRun = runId
	local startedAt = vim.uv.hrtime()
	local label = shortLabel(run.cmd)

	local origin = openOutputWindow(run.file)
	local win, buf = output.win, output.buf
	runs[run.file] = { id = thisRun, buf = buf, job = nil, stopped = false }
	-- every run keeps its own file's status; the shared bar follows only the newest run
	local function report(hl, icon, text)
		runs[run.file].status = { hl = hl, icon = icon, text = text }
		if thisRun == runId then
			setStatus(win, hl, icon, text)
		end
	end
	report("DiagnosticWarn", "⟳", label)

	local job = vim.fn.jobstart(run.cmd, {
		term = true,
		cwd = run.cwd,
		on_exit = function(_, code)
			vim.schedule(function()
				if not runs[run.file] or runs[run.file].id ~= thisRun then
					return -- a newer run of this file replaced this one
				end
				local seconds = (vim.uv.hrtime() - startedAt) / 1e9
				if runs[run.file].stopped then
					report("DiagnosticWarn", "■", string.format("%s · stopped · %.1fs", label, seconds))
					return
				end
				local ok = code == 0
				local summary = string.format("%s · %s · %.1fs", label, ok and "ok" or ("exit " .. code), seconds)
				report(ok and "DiagnosticOk" or "DiagnosticError", ok and "✓" or "✗", summary)
				local visible = isValidWin(win) and vim.api.nvim_win_get_buf(win) == buf
				if not visible then
					-- output is closed: still tell the user how it went
					vim.notify(
						(ok and "✓ " or "✗ ") .. summary .. "  (<leader>ro to view)",
						ok and vim.log.levels.INFO or vim.log.levels.ERROR
					)
				end
				if not ok then
					fillQuickfix(run, buf)
				end
			end)
		end,
	})
	runs[run.file].job = job
	styleOutputWindow(win) -- starting the terminal job resets number/signcolumn
	vim.keymap.set("n", "q", M.close, { buffer = buf, silent = true, desc = "Close runner" })
	vim.api.nvim_win_call(win, function()
		vim.cmd("normal! G")
	end)
	-- keep reading the code; the output follows on its own
	if isValidWin(origin) then
		vim.api.nvim_set_current_win(origin)
	end
end

-- action: "resolve" runs the file, "test" runs its tests (languages without one are skipped)
local function launch(action)
	local ft = vim.bo.filetype
	local language = languages[ft]
	if not language then
		vim.notify("No runner for filetype: " .. ft, vim.log.levels.WARN)
		return
	end
	local build = language[action]
	if not build then
		vim.notify("No " .. action .. " command for filetype: " .. ft, vim.log.levels.WARN)
		return
	end
	if vim.bo.modified then
		vim.cmd("write")
	end
	local file = vim.fn.expand("%:p")
	local dir = vim.fs.dirname(file)
	local ctx = {
		file = file,
		dir = dir,
		root = function(marker)
			return vim.fs.root(file, marker) or dir
		end,
	}
	local cmd, cwd = build(ctx)
	if not cmd then
		return -- the language module already said why (e.g. cursor not in a test)
	end
	local args = action == "resolve" and runArgs[file] or nil
	if args and args ~= "" then
		if language.argsSeparator then
			table.insert(cmd, language.argsSeparator)
		end
		vim.list_extend(cmd, vim.split(args, "%s+", { trimempty = true }))
	end
	if vim.fn.executable(cmd[1]) == 0 then
		vim.notify(cmd[1] .. " is not installed", vim.log.levels.ERROR)
		return
	end
	lastRun = {
		file = file,
		cmd = cmd,
		cwd = cwd,
		errorformat = language.errorformat,
		errorRoot = language.errorRoot and language.errorRoot(ctx) or cwd,
	}
	execute(lastRun)
end

function M.runFile()
	launch("resolve")
end

function M.testFile()
	launch("test")
end

-- Optional per-language narrower scopes (see testNearest/testInFile in a language module)
function M.testNearest()
	launch("testNearest")
end

function M.testInFile()
	launch("testInFile")
end

-- Ask for the program arguments of this file (empty clears them), then run it
function M.runWithArgs()
	local file = vim.fn.expand("%:p")
	vim.ui.input({ prompt = "Args: ", default = runArgs[file] or "" }, function(input)
		if input == nil then
			return -- cancelled
		end
		runArgs[file] = vim.trim(input)
		launch("resolve")
	end)
end

-- Kill the running job of this file, else of the newest run
function M.stop()
	local mine = runs[vim.fn.expand("%:p")]
	local target = mine and mine.job and mine or nil
	if not target then
		for _, run in pairs(runs) do
			if run.id == runId then
				target = run
			end
		end
	end
	if not target or not target.job or vim.fn.jobwait({ target.job }, 0)[1] ~= -1 then
		vim.notify("Nothing is running", vim.log.levels.INFO)
		return
	end
	target.stopped = true
	vim.fn.jobstop(target.job)
end

function M.runLast()
	if not lastRun then
		vim.notify("Nothing has been run yet", vim.log.levels.WARN)
		return
	end
	execute(lastRun)
end

-- Bring back the last run's output without running anything again
-- Shows only the current file's own output, never another file's
function M.open()
	local mine = runs[vim.fn.expand("%:p")]
	if not mine or not vim.api.nvim_buf_is_valid(mine.buf) then
		vim.notify("This file has no output yet: <leader>rr to run it", vim.log.levels.WARN)
		return
	end
	local buf, status = mine.buf, mine.status
	if isValidWin(output.win) and vim.api.nvim_win_get_buf(output.win) == buf then
		return
	end
	local origin = vim.api.nvim_get_current_win()
	keepOpenFor = vim.api.nvim_buf_get_name(0)
	if not isValidWin(output.win) then
		vim.cmd("belowright 15split")
		output.win = vim.api.nvim_get_current_win()
		styleOutputWindow(output.win)
	end
	vim.api.nvim_win_set_buf(output.win, buf)
	styleOutputWindow(output.win) -- set_buf restores the buffer's old window options
	output.buf = buf
	if status then
		setStatus(output.win, status.hl, status.icon, status.text)
	end
	vim.api.nvim_win_call(output.win, function()
		vim.cmd("normal! G")
	end)
	vim.api.nvim_set_current_win(origin)
end

-- A passed run is done with once you move on to another file; a failed or
-- still-running one stays open so you can fix errors with the output in view.
vim.api.nvim_create_autocmd("BufEnter", {
	group = vim.api.nvim_create_augroup("RunnerAutoClose", { clear = true }),
	desc = "Runner: close output of a passed run when switching file",
	callback = function(event)
		if not (isValidWin(output.win) and lastRun and lastStatus and lastStatus.hl == "DiagnosticOk") then
			return
		end
		local name = vim.api.nvim_buf_get_name(event.buf)
		if name == keepOpenFor then
			return
		end
		local isOtherFile = vim.bo[event.buf].buftype == "" and name ~= "" and name ~= lastRun.file
		if isOtherFile and vim.api.nvim_get_current_win() ~= output.win then
			keepOpenFor = nil
			M.close()
		end
	end,
})

-- One key: hide this file's output when it is showing, otherwise bring it back
function M.toggle()
	local mine = runs[vim.fn.expand("%:p")]
	if isValidWin(output.win) and (not mine or vim.api.nvim_win_get_buf(output.win) == mine.buf) then
		M.close()
	else
		M.open()
	end
end

function M.close()
	if isValidWin(output.win) then
		vim.api.nvim_win_close(output.win, true)
	end
	output.win = nil
end

return M
