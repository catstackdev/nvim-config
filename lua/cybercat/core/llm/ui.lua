local M = {
	_api = nil,
	state = {
		windows = {},
		buffers = {},
		config = {
			width = math.min(80, vim.o.columns - 10), -- Dynamic width
			height = math.min(20, vim.o.lines - 10), -- Dynamic height
			input_height = 5,
			border = "rounded",
			stream_delay = 50, -- ms between stream updates
		},
		keymaps = {
			submit = "<CR>", -- Shift+Enter to submit
			new_line = "<C-n>", -- Enter for new line
			move_up = "<C-k>", -- Ctrl+k to move up
			move_down = "<C-j>", -- Ctrl+j to move down
			close = "q", -- q to close
		},
	},
}
function M._setup_input_keymaps(buf)
	local km = M.state.keymaps

	-- Submit prompt (Shift+Enter)
	vim.keymap.set("i", km.submit, function()
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local prompt = table.concat(
			vim.tbl_filter(function(l)
				return l ~= "" and not l:match("^> ?")
			end, lines),
			"\n"
		)

		if #prompt == 0 then
			return
		end

		-- Clear input completely
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "> " })
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
		vim.api.nvim_win_set_cursor(M.state.windows.input, { 1, 2 })

		-- Add to chat
		M.append(M.state.buffers.chat, {
			"👤 You:",
			prompt,
			"⌛ Processing...",
			"",
		})

		-- Query API
		if M._api then
			M._api.query(prompt, { buf_id = M.state.buffers.chat })
		end
	end, { buffer = buf })

	-- New line (Enter)
	vim.keymap.set("i", km.new_line, function()
		local cursor = vim.api.nvim_win_get_cursor(M.state.windows.input)
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf, cursor[1], cursor[1], false, { "" })
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
		vim.api.nvim_win_set_cursor(M.state.windows.input, { cursor[1] + 1, 0 })
	end, { buffer = buf })

	-- Move between windows (Ctrl+j/k)
	vim.keymap.set("i", km.move_down, function()
		if M.state.windows.chat and vim.api.nvim_win_is_valid(M.state.windows.chat) then
			vim.api.nvim_set_current_win(M.state.windows.chat)
		end
	end, { buffer = buf })

	vim.keymap.set("i", km.move_up, function()
		if M.state.windows.input and vim.api.nvim_win_is_valid(M.state.windows.input) then
			vim.api.nvim_set_current_win(M.state.windows.input)
		end
	end, { buffer = buf })

	-- Close chat (q in normal mode)
	vim.keymap.set("n", km.close, function()
		M.close_all()
	end, { buffer = buf })

	-- Start in insert mode
	vim.api.nvim_command("startinsert!")
end

function M.inject_api(api)
	M._api = api
end

function M.init()
	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			M.close_all()
		end,
	})
end

function M.is_open()
	return next(M.state.windows) ~= nil
end

function M.open()
	if M.is_open() then
		return
	end

	-- Calculate centered position
	local ui_width = M.state.config.width
	local ui_height = M.state.config.height + M.state.config.input_height + 1
	local col = math.floor((vim.o.columns - ui_width) / 2)
	local row = math.floor((vim.o.lines - ui_height) / 2)

	-- Main chat window
	local chat_win, chat_buf = M._create_window({
		type = "chat",
		width = M.state.config.width,
		height = M.state.config.height,
		row = row,
		col = col,
		border = M.state.config.border,
		title = "💬 LLM Chat",
	})

	-- Input window (positioned below chat)
	local input_win, input_buf = M._create_window({
		type = "input",
		width = M.state.config.width,
		height = M.state.config.input_height,
		row = row + M.state.config.height + 1,
		col = col,
		border = "single",
		title = "✏️ Input (Ctrl+Enter to submit)",
	})

	M.state.buffers.chat = chat_buf
	M.state.buffers.input = input_buf

	M._setup_input_keymaps(input_buf)
	vim.api.nvim_set_current_win(input_win)
end

function M._create_window(opts)
	local buf = vim.api.nvim_create_buf(false, true)
	local win_opts = {
		relative = "editor",
		width = opts.width,
		height = opts.height,
		row = opts.row,
		col = opts.col,
		style = "minimal",
		border = opts.border,
		title = opts.title,
		title_pos = "center",
	}

	-- Remove nil values to avoid errors
	for k, v in pairs(win_opts) do
		if v == nil then
			win_opts[k] = nil
		end
	end

	local win = vim.api.nvim_open_win(buf, true, win_opts)

	-- Configure buffer
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	if opts.type == "input" then
		vim.api.nvim_buf_set_option(buf, "buftype", "prompt")
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" }) -- Start with empty line
	end

	M.state.windows[opts.type] = win
	M.state.buffers[opts.type] = buf

	return win, buf
end

function M._setup_input_keymaps(buf)
	-- Submit prompt (Ctrl+Enter)
	vim.keymap.set("i", "<C-CR>", function()
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local prompt = table.concat(
			vim.tbl_filter(function(l)
				return l ~= "" and not l:match("^> ?")
			end, lines),
			"\n"
		)

		if #prompt == 0 then
			return
		end

		-- Clear input completely (not keeping empty line)
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
		vim.fn.prompt_setprompt(buf, "> ")
		vim.api.nvim_buf_set_option(buf, "modifiable", false)

		-- Add to chat
		M.append(M.state.buffers.chat, {
			"👤 You:",
			prompt,
			"⌛ Processing...",
			"",
		})

		-- Query API
		if M._api then
			M._api.query(prompt, { buf_id = M.state.buffers.chat })
		end
	end, { buffer = buf, nowait = true })

	-- New line (Enter)
	vim.keymap.set("i", "<CR>", function()
		local cursor = vim.api.nvim_win_get_cursor(M.state.windows.input)
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf, cursor[1], cursor[1], false, { "" })
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
		vim.api.nvim_win_set_cursor(M.state.windows.input, { cursor[1] + 1, 0 })
	end, { buffer = buf, nowait = true })

	-- Close chat (q in normal mode)
	vim.keymap.set("n", "q", function()
		M.close_all()
	end, { buffer = buf, nowait = true })

	-- Ensure we start in insert mode
	vim.api.nvim_command("startinsert!")
end

function M.close_all()
	-- Cancel any ongoing API requests
	if M._api then
		M._api.cancel_all()
	end

	-- Close windows if they exist
	for type, win in pairs(M.state.windows) do
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	-- Clear state
	M.state.windows = {}
	M.state.buffers = {}
end

return M
