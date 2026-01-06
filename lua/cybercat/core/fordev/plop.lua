local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

-- This function runs the selected plop generator in a floating terminal
local function run_plop_generator(generator_name)
	local term_command = string.format("npm run plop %s", generator_name)

	-- Use Neovim's API to create a floating terminal for the interactive prompts
	local buffer = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_open_win(buffer, true, {
		relative = "editor",
		width = math.floor(vim.o.columns * 0.8),
		height = math.floor(vim.o.lines * 0.8),
		row = math.floor(vim.o.lines * 0.1),
		col = math.floor(vim.o.columns * 0.1),
		style = "minimal",
		border = "rounded",
		title = "Plop Generator",
		title_pos = "center",
	})
	vim.fn.termopen(term_command)
end

local M = {}

M.plop_picker = function(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Plop Generators",
			-- This command lists the available generators from your plopfile.js
			finder = finders.new_oneshot_job({ "npm", "run", "plop", "--", "--list-generators" }, {
				entry_maker = function(line)
					-- This simple parser finds generator names in plop's output.
					-- It looks for lines like "- component   Creates a new React component"
					local match = line:match("%- (%S+)")
					if match then
						return {
							value = match, -- The actual generator name, e.g., "component"
							display = line, -- The full line for context
							ordinal = line,
						}
					end
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						run_plop_generator(selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

return M
