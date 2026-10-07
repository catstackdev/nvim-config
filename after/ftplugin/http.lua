-- .http files: run them with the `api` CLI (personal-lib/api), next to kulala.
-- kulala owns <leader>R*; these live under <leader>a ("api") and are buffer-local.
--   <leader>ar  run the request under the cursor
--   <leader>ap  print it (--dry): the curl, nothing is sent
--   <leader>aA  run every request in the file
--   <leader>al  list the requests in the file
--   <leader>aE  choose the env (vim.g.api_env); unset = the config's default_env
--   <leader>aB  set the base URL (vim.g.api_base) for files with no .api.toml
--
-- api runs in the .http file's own directory: it finds .api.toml by walking up from
-- the current directory, so the config nearest the FILE applies wherever nvim started.
-- nvim does not see your shell session (api keeps API_* unexported on purpose), so the
-- server comes from that config (an env + default_env), from <leader>aE, or from a
-- base URL it asks for when no .api.toml is found. For a token, log in once per env
-- and let the token cache carry it:
--   api config set defaults.token_cache true --global
--   api login --env dev
-- Snippets for writing these files: apinew, apireq, apiget, apipost, apicheck, apiname,
-- apifilter, apiassert, apivar, apichain, apifile, apiuuid (snippets/http-api.json).

vim.bo.commentstring = "# %s"

local keymap = vim.keymap
local opts = { buffer = true, silent = true }

local function set(name)
	return vim.g[name] and vim.g[name] ~= ""
end

-- Name of the request under the cursor: its `# @name`, else the text after `###`.
-- nil above the first `###` (a one-request file needs no selector).
local function request_name()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local start
	for i = vim.fn.line("."), 1, -1 do
		if lines[i]:match("^###") then
			start = i
			break
		end
	end
	if not start then
		return nil
	end
	local heading = lines[start]:gsub("^#+", "")
	local name = vim.trim(heading)
	for i = start + 1, #lines do
		if lines[i]:match("^###") then
			break
		end
		local named = lines[i]:match("^[#/]+%s*@name%s+(.+)$")
		if named then
			name = vim.trim(named)
		end
	end
	return name ~= "" and name or nil
end

local function api_run(extra, with_name)
	if vim.bo.modified then
		vim.cmd("silent write") -- api reads the file from disk
	end
	local file = vim.fn.expand("%:p")
	local dir = vim.fn.expand("%:p:h")
	local name = with_name and request_name() or nil -- read now: the prompt below is async

	local function launch()
		local cmd = { "api" }
		if set("api_env") then
			vim.list_extend(cmd, { "--env", vim.g.api_env })
		end
		if set("api_base") then
			vim.list_extend(cmd, { "--base", vim.g.api_base })
		end
		vim.list_extend(cmd, { "run", file })
		if name then
			table.insert(cmd, name)
		end
		vim.list_extend(cmd, extra)
		-- :lcd on the new split only: nvim's own working directory is left alone
		vim.cmd(
			"botright 15split | lcd "
				.. vim.fn.fnameescape(dir)
				.. " | terminal "
				.. table.concat(vim.tbl_map(vim.fn.shellescape, cmd), " ")
		)
	end

	local has_config = vim.fs.find(".api.toml", { upward = true, path = dir, limit = 1 })[1] ~= nil
	if has_config or set("api_base") or set("api_env") then
		return launch()
	end
	vim.ui.input({
		prompt = "No .api.toml above " .. vim.fn.fnamemodify(dir, ":~") .. ". Base URL (empty = your global config): ",
	}, function(base)
		if base == nil then
			return -- cancelled
		end
		if base ~= "" then
			vim.g.api_base = base
		end
		launch()
	end)
end

opts.desc = "api: run request"
keymap.set("n", "<leader>ar", function()
	api_run({}, true)
end, opts)

opts.desc = "api: print request (--dry)"
keymap.set("n", "<leader>ap", function()
	api_run({ "--dry" }, true)
end, opts)

opts.desc = "api: run all requests"
keymap.set("n", "<leader>aA", function()
	api_run({ "--all" }, false)
end, opts)

opts.desc = "api: list requests"
keymap.set("n", "<leader>al", function()
	api_run({ "--list" }, false)
end, opts)

local function ask(var, prompt, label)
	return function()
		vim.ui.input({ prompt = prompt, default = vim.g[var] or "" }, function(value)
			if value ~= nil then
				vim.g[var] = value
				vim.notify(label .. ": " .. (value ~= "" and value or "unset"), vim.log.levels.INFO)
			end
		end)
	end
end

opts.desc = "api: choose env"
keymap.set("n", "<leader>aE", ask("api_env", "api env (empty = default): ", "api env"), opts)

opts.desc = "api: set base URL"
keymap.set("n", "<leader>aB", ask("api_base", "api base URL (empty = unset): ", "api base"), opts)
