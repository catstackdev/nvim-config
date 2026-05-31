---@diagnostic disable: undefined-global
-- Floating preview for the webgpu_fmt.py CLI toolbelt.
-- Opens a terminal-buffer float beside the cursor so ANSI colors from the
-- shell tools (swatches, sign/exp/frac highlighting) come through unchanged.
-- Closes on the next cursor move in the origin buffer or q/<Esc> in the float.

local M = {}

local PY = vim.fn.expand("~/.config/cybercat/profile/src/webgpu_fmt.py")

-- ─── float ──────────────────────────────────────────────────────────────────

local function open_float(cmd, args)
	if vim.fn.filereadable(PY) == 0 then
		vim.notify("webgpu_fmt.py not found at " .. PY, vim.log.levels.ERROR, { title = "webgpu" })
		return
	end

	local origin_win = vim.api.nvim_get_current_win()
	local origin_buf = vim.api.nvim_get_current_buf()
	local buf = vim.api.nvim_create_buf(false, true)

	local title = " " .. cmd
	if #args > 0 then
		local joined = table.concat(args, " ")
		if #joined > 36 then
			joined = joined:sub(1, 33) .. "…"
		end
		title = title .. ": " .. joined
	end
	title = title .. " "

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "cursor",
		row = 1,
		col = 0,
		width = 78,
		height = 18,
		style = "minimal",
		border = "rounded",
		title = title,
		title_pos = "left",
	})

	local job_args = { "python3", PY, cmd }
	for _, a in ipairs(args) do
		table.insert(job_args, a)
	end
	vim.fn.termopen(job_args)
	vim.api.nvim_set_current_win(origin_win)

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		if vim.api.nvim_win_is_valid(win) then
			pcall(vim.api.nvim_win_close, win, true)
		end
		if vim.api.nvim_buf_is_valid(buf) then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
	end

	-- Shrink the window to fit actual output once the script exits.
	-- Strips trailing blanks and the "[Process exited 0]" terminal footer.
	vim.api.nvim_create_autocmd("TermClose", {
		buffer = buf,
		once = true,
		callback = vim.schedule_wrap(function()
			if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
				return
			end
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			local last = #lines
			while last > 0 and (lines[last] == "" or lines[last]:match("^%[Process exited")) do
				last = last - 1
			end
			local h = math.max(3, math.min(24, last + 1))
			pcall(vim.api.nvim_win_set_height, win, h)
			pcall(vim.api.nvim_win_call, win, function()
				vim.cmd("normal! gg")
			end)
		end),
	})

	-- Defer the close trigger so the WinEnter/BufEnter from returning focus
	-- to the origin window doesn't immediately trip it.
	vim.schedule(function()
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave" }, {
			buffer = origin_buf,
			once = true,
			callback = close,
		})
	end)

	vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true })
end

-- ─── text source helpers ────────────────────────────────────────────────────

local function visual_text()
	-- Works whether called mid-visual (from `x` keymap) or after exit.
	local mode = vim.fn.mode()
	local s, e
	if mode == "v" or mode == "V" or mode == "\22" then
		s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
	else
		s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
	end
	local sl, sc, el, ec = s[2], s[3], e[2], e[3]
	if sl > el or (sl == el and sc > ec) then
		sl, sc, el, ec = el, ec, sl, sc
	end
	local ok, lines = pcall(vim.api.nvim_buf_get_text, 0, sl - 1, sc - 1, el - 1, ec, {})
	if not ok or not lines then
		return ""
	end
	return table.concat(lines, " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function cword_text()
	return vim.fn.expand("<cWORD>"):gsub("[,;]+$", "")
end

local function run_with(text, cmd, multi)
	if text == nil or text == "" then
		vim.notify("webgpu: no text under cursor", vim.log.levels.WARN, { title = "webgpu" })
		return
	end
	if multi then
		local args = {}
		for w in text:gmatch("%S+") do
			table.insert(args, w)
		end
		open_float(cmd, args)
	else
		open_float(cmd, { text })
	end
end

-- ─── public API ─────────────────────────────────────────────────────────────

function M.cword(cmd) run_with(cword_text(), cmd, false) end
function M.cword_split(cmd) run_with(cword_text(), cmd, true) end
function M.visual(cmd) run_with(visual_text(), cmd, false) end
function M.visual_split(cmd) run_with(visual_text(), cmd, true) end
function M.help() open_float("help", {}) end
function M.run(cmd, args) open_float(cmd, args or {}) end

-- Set up the standard <leader>i* keymaps for the current buffer.
-- Called from shader ftplugins; safe to call from anywhere.
function M.setup_keymaps(buf)
	local base = { buffer = buf, silent = true }

	local function pair(lhs, cmd, multi, desc)
		local n_fn = multi and function() M.cword_split(cmd) end or function() M.cword(cmd) end
		local x_fn = multi and function() M.visual_split(cmd) end or function() M.visual(cmd) end
		vim.keymap.set("n", lhs, n_fn, vim.tbl_extend("force", base, { desc = desc }))
		vim.keymap.set("x", lhs, x_fn, vim.tbl_extend("force", base, { desc = desc }))
	end

	-- Bit / float inspectors
	pair("<leader>ib", "bits",     false, "Inspect: bits (dec/hex/bin)")
	pair("<leader>i3", "f32",      false, "Inspect: f32 (IEEE-754)")
	pair("<leader>ih", "f16",      false, "Inspect: f16 (IEEE-754)")

	-- Colors
	pair("<leader>ic", "rgb",      false, "Inspect: hex → swatch + vec3f")
	pair("<leader>iC", "unrgb",    false, "Inspect: vec → hex")
	pair("<leader>ip", "palette",  true,  "Inspect: palette of hex colors")
	pair("<leader>ig", "gradient", true,  "Inspect: gradient between two colors")

	-- Shader math
	pair("<leader>ia", "align",    true,  "Inspect: buffer alignment")
	pair("<leader>id", "dispatch", true,  "Inspect: dispatch math")
	pair("<leader>i2", "pow2",     false, "Inspect: next power of two")

	vim.keymap.set("n", "<leader>i?", M.help,
		vim.tbl_extend("force", base, { desc = "Inspect: WebGPU toolbelt help" }))
end

return M
