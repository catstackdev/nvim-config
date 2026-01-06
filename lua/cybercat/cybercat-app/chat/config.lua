local M = {}

M.defaults = {
	-- UI
	width = 20,
	input_height = 5,
	position = "right",
	filetype = "sidebar",
	border = "rounded",
	title = "  AI Chat ",
	show_title = true,
	winblend = 10,
	hl = {
		normal = "ChatNormal",
		border = "ChatBorder",
		title = "ChatTitle",
	},

	-- Behavior
	auto_open = true,
	persist_history = true,
	history_format = "markdown", -- 'json' or 'markdown'
	max_history_size = 10000, -- characters

	-- Messages
	message_template = "[{time}] {sender}: {content}",
	send_on_enter = true,
	syntax_highlight = true,
	virtual_text = true, -- show typing indicators

	-- API
	api = {
		provider = "openai", -- 'ollama', 'custom'
		timeout = 30000,
		model = "gpt-4",
		temperature = 0.7,
		context_window = 4096,
	},

	-- Keymaps
	mappings = {
		open = "<leader>ll",
		close = "q",
		scroll_up = "<C-u>",
		scroll_down = "<C-d>",
		toggle_sidebar = "<leader>cc",

		back = "<C-h>",
		move_sidebar = "<C-l>",

		toggle = "<leader>cc",
		send = "<CR>",
		new = "<leader>cn",
		yank_last = "<leader>cy",
		interrupt = "<C-c>",
		history_complete = "<C-n>",
	},

	-- Providers
	providers = {
		openai = {
			api_key = os.getenv("OPENAI_API_KEY"),
			endpoint = "https://api.openai.com/v1/chat/completions",
		},
		ollama = {
			endpoint = "http://localhost:11434/api/chat",
			model = "llama2",
		},
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
	-- M.validate()
end

function M.validate()
	-- Validate configuration
	if M.options.api.provider == "openai" and not M.options.providers.openai.api_key then
		vim.notify("OpenAI API key not configured", vim.log.levels.WARN)
	end
end

return M
