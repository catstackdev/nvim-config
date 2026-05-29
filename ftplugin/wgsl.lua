---@diagnostic disable: undefined-global
local buf = vim.api.nvim_get_current_buf()
local opts = { buffer = buf, silent = true }

-- Walk upward from the current file (up to 10 levels) to find the workspace's
-- WGSL shader root. Used by <leader>gd / <leader>gr to grep for definitions.
local function find_wgsl_root()
	local current = vim.fn.expand("%:p:h")
	for _ = 1, 10 do
		-- Prefer the WGSL library dir if it exists; fall back to the
		-- experiments dir (which is where most WGSL lives today).
		local wgsl_lib = current .. "/src/shaders/wgsl"
		if vim.fn.isdirectory(wgsl_lib) == 1 then
			return wgsl_lib
		end
		local experiments = current .. "/src/experiments"
		if vim.fn.isdirectory(experiments) == 1 then
			return experiments
		end
		local parent = vim.fn.fnamemodify(current, ":h")
		if parent == current then
			return nil
		end
		current = parent
	end
	return nil
end

local wgsl_root = find_wgsl_root()
if wgsl_root then
	-- <leader>gd  → go to WGSL function/struct/const definition (word under cursor)
	vim.keymap.set("n", "<leader>gd", function()
		local word = vim.fn.expand("<cword>")
		if word == "" then
			return
		end
		-- WGSL function shapes:
		--   fn name(...)         — plain
		--   fn name(...) -> T    — with return
		-- WGSL struct/var shapes:
		--   struct Name {
		--   const NAME ...
		--   var<...> name : ...
		local pattern = string.format([[\b(fn|struct|const|var)\s+%s\b]], word)
		local cmd
		if vim.fn.executable("rg") == 1 then
			cmd = string.format(
				"rg --vimgrep --no-heading -e %s %s",
				vim.fn.shellescape(pattern),
				vim.fn.shellescape(wgsl_root)
			)
		else
			cmd = string.format("grep -rnE %s %s", vim.fn.shellescape(pattern), vim.fn.shellescape(wgsl_root))
		end
		local results = vim.fn.systemlist(cmd)
		if #results == 0 then
			vim.notify("No WGSL definition found for " .. word, vim.log.levels.WARN, { title = "wgsl" })
			return
		end
		-- Filter out comments
		local defs = {}
		for _, line in ipairs(results) do
			local _, _, c = line:find("^[^:]+:%d+:%d+:(.*)$")
			if not c then
				_, _, c = line:find("^[^:]+:%d+:(.*)$")
			end
			if c then
				local trimmed = c:gsub("^%s+", "")
				if not trimmed:match("^//") and not trimmed:match("^/%*") then
					table.insert(defs, line)
				end
			end
		end
		if #defs == 0 then
			defs = results
		end
		if #defs >= 1 then
			local file, lnum = defs[1]:match("([^:]+):(%d+):")
			if file then
				vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(file))
			end
		end
	end, vim.tbl_extend("force", opts, { desc = "WGSL: go to definition" }))

	-- <leader>gr  → list all references (call-sites + decls) for the word under cursor
	vim.keymap.set("n", "<leader>gr", function()
		local word = vim.fn.expand("<cword>")
		if word == "" then
			return
		end
		local pattern = [[\b]] .. word .. [[\b]]
		vim.cmd("silent grep! " .. vim.fn.shellescape(pattern) .. " " .. vim.fn.shellescape(wgsl_root))
		vim.cmd("copen")
	end, vim.tbl_extend("force", opts, { desc = "WGSL: list references" }))
end

local job_id = nil

local function is_running()
	return job_id and vim.fn.jobwait({ job_id }, 0)[1] == -1
end

local function stop_preview()
	if is_running() then
		vim.fn.jobstop(job_id)
	end
	job_id = nil
end

local function start_preview()
	local file = vim.fn.expand("%:p")
	job_id = vim.fn.jobstart({ "wgsl-playground", file }, {
		on_stderr = function(_, data)
			local msg = table.concat(data or {}, "\n")
			if msg:match("%S") then
				vim.schedule(function()
					vim.notify(msg, vim.log.levels.WARN, { title = "wgsl-playground" })
				end)
			end
		end,
		on_exit = function()
			job_id = nil
		end,
	})
end

vim.keymap.set("n", "<leader>gp", function()
	if is_running() then
		stop_preview()
		vim.notify("WGSL preview stopped", vim.log.levels.INFO, { title = "wgsl-playground" })
	else
		start_preview()
		vim.notify("WGSL preview started", vim.log.levels.INFO, { title = "wgsl-playground" })
	end
end, vim.tbl_extend("force", opts, { desc = "WGSL playground preview (toggle)" }))

vim.keymap.set("n", "<leader>gv", function()
	local file = vim.fn.expand("%:p")
	local stderr_chunks = {}
	vim.fn.jobstart({ "naga", file }, {
		on_stderr = function(_, data)
			for _, line in ipairs(data or {}) do
				if line ~= "" then
					table.insert(stderr_chunks, line)
				end
			end
		end,
		on_exit = function(_, code)
			vim.schedule(function()
				if code == 0 then
					vim.notify("WGSL valid", vim.log.levels.INFO, { title = "naga" })
				else
					local msg = #stderr_chunks > 0 and table.concat(stderr_chunks, "\n")
						or ("naga exited with code " .. code)
					vim.notify(msg, vim.log.levels.ERROR, { title = "naga" })
				end
			end)
		end,
	})
end, vim.tbl_extend("force", opts, { desc = "WGSL validate (naga)" }))

local group = vim.api.nvim_create_augroup("wgsl_preview_" .. buf, { clear = true })
vim.api.nvim_create_autocmd("BufUnload", {
	group = group,
	buffer = buf,
	callback = stop_preview,
})
