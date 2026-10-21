-- Reports <leader> keymap collisions: a mapping whose lhs is a strict prefix of another mapping that is
-- live in the same buffer and mode (Vim waits 'timeoutlen' before firing the shorter one), and buffer-local
-- mappings that silently override a global one.
-- Run with the full config loaded:  ./scripts/check-keymaps.sh

local leader = vim.g.mapleader or " "
local MODES = { "n", "x" }
-- One file per filetype whose buffer-local mappings matter; package.json triggers package-info
local PROBES = { "probe.rs", "probe.lua", "probe.md", "probe.http", "probe.py", "package.json" }

-- Intentional overrides: buffer-local mappings that replace a global one on purpose
local ALLOWED_OVERRIDES = {
	["probe.http"] = { ["n"] = { [leader .. "rr"] = true, [leader .. "rl"] = true, [leader .. "ro"] = true } },
}

---@param buf integer? nil for global maps
---@param mode string
---@return table<string, table> lhs -> map
local function leader_maps(buf, mode)
	local list = buf and vim.api.nvim_buf_get_keymap(buf, mode) or vim.api.nvim_get_keymap(mode)
	local out = {}
	for _, map in ipairs(list) do
		local lhs = map.lhsraw or map.lhs
		if vim.startswith(lhs, leader) and #lhs > #leader then
			out[lhs] = map
		end
	end
	return out
end

local function pretty(lhs)
	return (lhs:gsub("^" .. vim.pesc(leader), "<leader>"))
end

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")

local findings = {}
local seen = {}

---@param key string
---@param message string
local function report(key, message)
	if not seen[key] then
		seen[key] = true
		table.insert(findings, message)
	end
end

for _, name in ipairs(PROBES) do
	local path = dir .. "/" .. name
	vim.fn.writefile({ "" }, path)
	vim.cmd("silent! edit " .. vim.fn.fnameescape(path))
	vim.wait(1500, function()
		return false
	end, 100) -- let VeryLazy, FileType and LspAttach-style schedulers run

	local buf = vim.api.nvim_get_current_buf()
	for _, mode in ipairs(MODES) do
		local global, local_ = leader_maps(nil, mode), leader_maps(buf, mode)
		local live = vim.tbl_extend("force", global, local_)

		for lhs in pairs(local_) do
			local allowed = ALLOWED_OVERRIDES[name] and ALLOWED_OVERRIDES[name][mode] and ALLOWED_OVERRIDES[name][mode][lhs]
			if global[lhs] and not allowed then
				report(mode .. lhs .. "override", ("[%s] %s overrides a global mapping in %s"):format(mode, pretty(lhs), name))
			end
		end

		local keys = vim.tbl_keys(live)
		table.sort(keys)
		for i, short in ipairs(keys) do
			local next_lhs = keys[i + 1]
			if next_lhs and vim.startswith(next_lhs, short) then
				report(
					mode .. short .. "prefix",
					("[%s] %s (%s) shadows %s... (%s) in %s"):format(
						mode,
						pretty(short),
						live[short].desc or "no desc",
						pretty(next_lhs),
						live[next_lhs].desc or "no desc",
						name
					)
				)
			end
		end
	end
end

vim.fn.delete(dir, "rf")

if #findings == 0 then
	print("keymap check: no collisions")
	vim.cmd("qa!")
else
	table.sort(findings)
	print(("keymap check: %d collision(s)\n  %s"):format(#findings, table.concat(findings, "\n  ")))
	vim.cmd("cquit 1")
end
