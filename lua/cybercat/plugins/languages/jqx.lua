-- JSON/YAML explorer: browse keys with :JqxList, run jq/yq queries with :JqxQuery
-- Requires jq (json) and the *Python* yq (kislyuk, `pip install yq`) for yaml;
-- the Go yq (mikefarah, brew's default) is not compatible

-- :JqxList lists top-level keys as `<file>|<line> col <col>| <key>`: a long temp path, no hint
-- of the value, keys sorted alphabetically, and nothing at all for the indexes of a top-level
-- array. The list below replaces it for json objects and arrays: file order, one line per
-- entry showing a short preview, <CR> jumps to the entry, and the value key opens it in a popup.

---one jq output line per entry, same order as the entries in the file
local PREVIEW_FILTER = {
	array = ".[] | tojson",
	object = [[to_entries[] | .value
		| if type == "array" then "[array, \(length)]"
		elif type == "object" then "{object, \(length) keys}"
		else tojson end]],
}

---quickfixtextfunc: `<key or index>  <preview>`, keys padded into a column
function _G.jqx_qf_text(info)
	local items = vim.fn.getqflist({ id = info.id, items = 1 }).items
	local width = 0
	for i = info.start_idx, info.end_idx do
		width = math.min(24, math.max(width, vim.fn.strdisplaywidth(items[i].text)))
	end
	local lines = {}
	for i = info.start_idx, info.end_idx do
		local pad = (" "):rep(width - vim.fn.strdisplaywidth(items[i].text))
		lines[#lines + 1] = ("%s%s  %s"):format(items[i].text, pad, items[i].user_data.preview)
	end
	return lines
end

---Show the entry under the cursor in the jqx popup. Replaces the plugin's own key, which
---reads the displayed line and so cannot work with the custom text above.
local function show_entry()
	local item = vim.fn.getqflist()[vim.fn.line(".")]
	if not item or not item.bufnr or not vim.api.nvim_buf_is_valid(item.bufnr) then
		return
	end
	local text = table.concat(vim.api.nvim_buf_get_lines(item.bufnr, 0, -1, false), "\n")
	local res = vim.system({ "jq", item.user_data.query }, { stdin = text, text = true }):wait()
	local floating = require("nvim-jqx.floating")
	local buf = floating.floating_window(require("nvim-jqx.config").geometry)
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(vim.trim(res.code == 0 and res.stdout or res.stderr), "\n"))
	floating.set_fw_opts(buf)
	vim.cmd("normal! gg")
end

---Entries of the top-level json value: array elements, or object pairs.
---@param value TSNode the top-level array or object node
---@return { text: string, query: string, row: integer, col: integer }[]
local function top_level_entries(value)
	local entries = {}
	for child in value:iter_children() do
		local row, col = child:start()
		if value:type() == "array" and child:named() then
			local index = #entries
			entries[#entries + 1] = { text = tostring(index), query = (".[%d]"):format(index), row = row, col = col }
		elseif value:type() == "object" and child:type() == "pair" then
			local key_node = child:field("key")[1]
			local key = vim.json.decode(vim.treesitter.get_node_text(key_node, 0))
			entries[#entries + 1] = { text = key, query = (".[%s]"):format(vim.json.encode(key)), row = row, col = col }
		end
	end
	return entries
end

local function list_keys()
	if vim.bo.filetype ~= "json" then
		return vim.cmd("JqxList")
	end
	-- same prettify step JqxList does, so each entry starts on its own line
	vim.cmd("silent %! jq .")
	local ok, parser = pcall(vim.treesitter.get_parser, 0, "json")
	local value = ok and parser:parse()[1]:root():named_child(0)
	local kind = value and value:type()
	if kind ~= "array" and kind ~= "object" then
		return vim.cmd("JqxList")
	end

	local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	local previews = vim.split(
		vim.system({ "jq", "-r", PREVIEW_FILTER[kind] }, { stdin = text, text = true }):wait().stdout,
		"\n"
	)
	local items = {}
	for i, entry in ipairs(top_level_entries(value)) do
		local preview = previews[i] or ""
		items[i] = {
			bufnr = vim.api.nvim_get_current_buf(),
			lnum = entry.row + 1,
			col = entry.col + 1,
			text = entry.text,
			user_data = { query = entry.query, preview = #preview > 80 and preview:sub(1, 79) .. "…" or preview },
		}
	end
	vim.fn.setqflist({}, " ", { title = "jqx", items = items, quickfixtextfunc = "v:lua.jqx_qf_text" })
	vim.cmd("copen")
	vim.keymap.set("n", require("nvim-jqx.config").query_key, show_entry, { buffer = 0, desc = "Show entry value" })
end

return {
	"gennaro-tedesco/nvim-jqx",
	ft = { "json", "jsonc", "yaml" },
	cmd = { "JqxList", "JqxQuery" },
	init = function()
		local jqx = require("nvim-jqx.config")
		jqx.geometry.width = 0.6
		jqx.geometry.height = 0.6
		jqx.query_key = "v" -- key in the quickfix list that shows a key's value (default X)

		-- The popup is a scratch buffer with filetype "jqx" and `style = minimal`.
		-- Filetype must stay "jqx": the plugin's WinLeave autocmd closes it by that name.
		-- Registering it as json lets treesitter modules (<C-space> incremental selection)
		-- attach to it like any json buffer.
		vim.treesitter.language.register("json", "jqx")

		-- `style = minimal` strips window options; restore the useful ones
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "jqx",
			group = vim.api.nvim_create_augroup("JqxPopup", { clear = true }),
			callback = function(args)
				vim.keymap.set(
					"n",
					"q",
					"<cmd>close<cr>",
					{ buffer = args.buf, nowait = true, desc = "Close jqx popup" }
				)
				vim.wo.number = true
				vim.wo.relativenumber = vim.o.relativenumber
				vim.wo.cursorline = true
				vim.wo.foldenable = false
			end,
		})
	end,
	config = function()
		-- The plugin's own completion offers only the array indexes ("0") for a top-level
		-- array, which JqxQuery turns into the invalid `.0`. Offer valid continuations instead:
		-- `[]`, `[0]` and `[].field` for arrays, plain keys for objects. Reads the buffer
		-- text (not the file on disk), so unsaved and stdin buffers complete too.
		local keys_filter = [[
			if type == "array" then
				(["[]", "[0]"] + [.[0]? | objects | keys_unsorted[] | "[]." + .])[]
			elif type == "object" then keys_unsorted[]
			else empty end
		]]

		---@param arg_lead string
		---@return string[]
		local function complete_query(arg_lead)
			if vim.bo.filetype ~= "json" then
				return vim.fn.FileKeys(arg_lead, "", 0) -- yaml: keep the plugin's behaviour
			end
			local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
			local res = vim.system({ "jq", "-r", keys_filter }, { stdin = text, text = true }):wait()
			if res.code ~= 0 then
				return {}
			end
			return vim.tbl_filter(function(key)
				return vim.startswith(key, arg_lead)
			end, vim.split(vim.trim(res.stdout), "\n", { trimempty = true }))
		end

		vim.api.nvim_create_user_command("JqxQuery", function(opts)
			require("nvim-jqx").query_jq(opts.args)
		end, { nargs = "?", complete = complete_query, force = true })
	end,
	keys = {
		{ "<leader>jl", list_keys, desc = "Jqx list keys" },
		-- no <cr>: leaves the cmdline open so you type the query (takes it as the argument)
		{ "<leader>jq", ":JqxQuery ", desc = "Jqx query" },
	},
}
