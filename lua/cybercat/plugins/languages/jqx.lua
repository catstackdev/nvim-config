-- JSON/YAML explorer: browse keys with :JqxList, run jq/yq queries with :JqxQuery
-- Requires jq (json) and the *Python* yq (kislyuk, `pip install yq`) for yaml;
-- the Go yq (mikefarah, brew's default) is not compatible
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
	keys = {
		{ "<leader>jl", "<cmd>JqxList<cr>", desc = "Jqx list keys" },
		-- no <cr>: leaves the cmdline open so you type the query (takes it as the argument)
		{ "<leader>jq", ":JqxQuery ", desc = "Jqx query" },
	},
}
