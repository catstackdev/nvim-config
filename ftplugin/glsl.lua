---@diagnostic disable: undefined-global
local term_preview = require("cybercat.utils.term_preview")

local buf = vim.api.nvim_get_current_buf()
local opts = { buffer = buf, silent = true }

local TMP_FRAG = "/tmp/nvim_glsl_preview.frag"
local TMP_VERT = "/tmp/nvim_glsl_preview.vert"

-- Read default flags from ~/.config/glslviewer/config (one flag per line, # = comment)
local function load_config_flags()
	local cfg = vim.fn.expand("~/.config/glslviewer/config")
	if vim.fn.filereadable(cfg) == 0 then
		return ""
	end
	local flags = {}
	for _, line in ipairs(vim.fn.readfile(cfg)) do
		if line ~= "" and not line:match("^#") then
			table.insert(flags, line)
		end
	end
	return table.concat(flags, " ")
end

local DEFAULT_FLAGS = load_config_flags()

local THREE_VERT_HEADER = {
	"uniform mat4 modelMatrix;",
	"uniform mat4 modelViewMatrix;",
	"uniform mat4 projectionMatrix;",
	"uniform mat4 viewMatrix;",
	"uniform mat3 normalMatrix;",
	"uniform vec3 cameraPosition;",
	"attribute vec3 position;",
	"attribute vec3 normal;",
	"attribute vec2 uv;",
	"",
}

-- Resolve `#include "/..."` paths against the workspace's shader root.
-- Walk upward from the current file (up to 10 levels) so this works even when
-- the file is opened from a deep path or with cwd outside the project.
local function find_shader_root()
	local current = vim.fn.expand("%:p:h")
	for _ = 1, 10 do
		local candidate = current .. "/src/shaders/glsl"
		if vim.fn.isdirectory(candidate) == 1 then
			return candidate
		end
		local parent = vim.fn.fnamemodify(current, ":h")
		if parent == current then
			return nil
		end
		current = parent
	end
	return nil
end

local shader_root = find_shader_root()
if shader_root then
	vim.opt_local.path:append(shader_root)
	-- gf workflow:
	--   1. vim takes the filename under cursor: `/sdf/sdf.glsl`
	--   2. includeexpr strips the leading slash:  `sdf/sdf.glsl`
	--   3. vim searches each directory in `path` for that file
	--   4. with shader_root in path, finds <root>/sdf/sdf.glsl
	-- NOTE: includeexpr is a *vimscript* expression, not Lua.
	-- `v:fname:sub(2)` would be a Lua method call and fails to parse.
	vim.opt_local.includeexpr = "substitute(v:fname, '^/', '', '')"

	-- <leader>gd  → go to GLSL library function definition (word under cursor)
	-- Greps the shader root for a definition-shaped match (`type name(`).
	-- Works whether or not the include is present in the current file.
	vim.keymap.set("n", "<leader>gd", function()
		local word = vim.fn.expand("<cword>")
		if word == "" then
			return
		end
		local pattern = [[\b]] .. word .. [[\s*\(]]
		local cmd
		if vim.fn.executable("rg") == 1 then
			cmd = string.format(
				"rg --vimgrep --no-heading -e %s %s",
				vim.fn.shellescape(pattern),
				vim.fn.shellescape(shader_root)
			)
		else
			cmd = string.format("grep -rnE %s %s", vim.fn.shellescape(pattern), vim.fn.shellescape(shader_root))
		end
		local results = vim.fn.systemlist(cmd)
		if #results == 0 then
			vim.notify("No definition found for " .. word, vim.log.levels.WARN, { title = "glsl" })
			return
		end
		-- Filter to definition-shaped lines (type, name, paren) on the actual
		-- content. `rg --vimgrep` formats as file:line:col:content (4 parts);
		-- plain `grep -n` formats as file:line:content (3 parts). Handle both.
		local function extract_content(line)
			local _, _, c = line:find("^[^:]+:%d+:%d+:(.*)$")
			if not c then
				_, _, c = line:find("^[^:]+:%d+:(.*)$")
			end
			return c
		end
		local defs = {}
		for _, line in ipairs(results) do
			local content = extract_content(line)
			if content then
				-- Skip lines that are comments
				local trimmed = content:gsub("^%s+", "")
				if not trimmed:match("^//") and not trimmed:match("^%*") then
					-- Definition shape: <type> <name>(  at start of (trimmed) content
					if trimmed:match("^[%w_]+[%s%*]+" .. word .. "%s*%(") then
						table.insert(defs, line)
					end
				end
			end
		end
		if #defs == 0 then
			defs = results
		end
		-- if #defs == 1 then
		-- 	local file, lnum = defs[1]:match("([^:]+):(%d+):")
		-- 	if file then
		-- 		vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(file))
		-- 	end
		-- else
		if #defs >= 1 then
			local file, lnum = defs[1]:match("([^:]+):(%d+):")
			if file then
				vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(file))
			end
		else
			vim.fn.setqflist({}, " ", { title = "GLSL: " .. word, lines = defs })
			vim.cmd("copen")
		end
	end, vim.tbl_extend("force", opts, { desc = "GLSL: go to definition" }))

	-- <leader>gr  → list all references (call-sites) for the word under cursor
	vim.keymap.set("n", "<leader>gr", function()
		local word = vim.fn.expand("<cword>")
		if word == "" then
			return
		end
		local pattern = [[\b]] .. word .. [[\b]]
		vim.cmd("silent grep! " .. vim.fn.shellescape(pattern) .. " " .. vim.fn.shellescape(shader_root))
		vim.cmd("copen")
	end, vim.tbl_extend("force", opts, { desc = "GLSL: list references" }))
end

local function find_paired(file)
	local paired
	if file:match("%.vert%.glsl$") then
		paired = file:gsub("%.vert%.glsl$", ".frag.glsl")
	elseif file:match("%.frag%.glsl$") then
		paired = file:gsub("%.frag%.glsl$", ".vert.glsl")
	elseif file:match("%.vert$") then
		paired = file:gsub("%.vert$", ".frag")
	elseif file:match("%.frag$") then
		paired = file:gsub("%.frag$", ".vert")
	end
	if paired and vim.fn.filereadable(paired) == 1 then
		return paired
	end
end

local function sync_to_tmp(file)
	if file:match("%.vert") then
		local lines = vim.list_extend(vim.deepcopy(THREE_VERT_HEADER), vim.fn.readfile(file))
		vim.fn.writefile(lines, TMP_VERT)
	else
		vim.fn.writefile(vim.fn.readfile(file), TMP_FRAG)
	end
end

vim.api.nvim_create_autocmd("BufWritePost", {
	buffer = buf,
	callback = function()
		sync_to_tmp(vim.fn.expand("%:p"))
		local paired = find_paired(vim.fn.expand("%:p"))
		if paired then
			sync_to_tmp(paired)
		end
	end,
})

local function build_args(file)
	local paired = find_paired(file)
	sync_to_tmp(file)
	if paired then
		sync_to_tmp(paired)
		return TMP_VERT .. " " .. TMP_FRAG
	end
	return TMP_FRAG
end

-- vim.defer_fn(function()
-- 	vim.schedule(function()
-- 		if vim.api.nvim_win_is_valid(term_win) then
-- 			vim.api.nvim_win_close(term_win, true)
-- 		end
-- 	end)
-- end, 5000)
-- vim.api.nvim_set_current_win(origin)

vim.keymap.set("n", "<leader>gp", function()
	term_preview.launch("glslviewer " .. build_args(vim.fn.expand("%:p")) .. " " .. DEFAULT_FLAGS)
end, vim.tbl_extend("force", opts, { desc = "GLSL preview" }))

vim.keymap.set("n", "<leader>gv", function()
	sync_to_tmp(vim.fn.expand("%:p"))
	term_preview.launch("glslviewer " .. TMP_FRAG .. " --shadertoy " .. DEFAULT_FLAGS)
end, vim.tbl_extend("force", opts, { desc = "GLSL Shadertoy preview" }))
