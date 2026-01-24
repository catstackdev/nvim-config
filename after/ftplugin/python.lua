-- Python-specific settings for AI/ML development
-- FastAPI, LangChain, LlamaIndex optimized

local keymap = vim.keymap
local bufnr = vim.api.nvim_get_current_buf()

-- Python-specific indentation (PEP 8: 4 spaces)
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.expandtab = true

-- Useful for AI development with long chains
vim.opt_local.textwidth = 88 -- Black formatter default
-- vim.opt_local.colorcolumn = "88"

-- Keymap options (silent for snippets)
local opts_silent = { buffer = bufnr, silent = true, noremap = true }
-- Options for commands that show output (NO silent, NO noremap)
local opts_output = { buffer = bufnr }

-- FastAPI route quickstart - similar to NestJS decorators
opts_silent.desc = "Insert FastAPI GET route"
keymap.set(
	"n",
	"<leader>pg",
	"i@app.get('/')<CR>async def read_root():<CR>return {'message': 'Hello World'}<Esc>",
	opts_silent
)

opts_silent.desc = "Insert FastAPI POST route"
keymap.set("n", "<leader>pp", "i@app.post('/')<CR>async def create_item(item: dict):<CR>return item<Esc>", opts_silent)

opts_silent.desc = "Insert Pydantic model"
keymap.set("n", "<leader>pm", "iclass Model(BaseModel):<CR>pass<Esc>", opts_silent)

-- LangChain quick snippets
opts_silent.desc = "Insert LangChain chain template"
keymap.set(
	"n",
	"<leader>plc",
	"ifrom langchain.chains import LLMChain<CR>from langchain.prompts import PromptTemplate<CR><CR>",
	opts_silent
)

-- Run Python file (like npm run dev for NestJS)
-- Uses 'python' which points to pyenv version
-- Opens in a split terminal to show output
opts_output.desc = "Run current Python file"
keymap.set("n", "<leader>pr", function()
	vim.cmd("w") -- Save file first
	local file = vim.fn.expand("%:p") -- Full path to current file
	vim.cmd("split | terminal python " .. vim.fn.shellescape(file))
	vim.cmd("startinsert") -- Enter insert mode to see output
end, opts_output)

-- Run with uvicorn (FastAPI dev server)
opts_output.desc = "Start FastAPI dev server"
keymap.set("n", "<leader>pf", function()
	vim.cmd("split | terminal uvicorn main:app --reload")
	vim.cmd("startinsert")
end, opts_output)

-- Virtual environment activation reminder
opts_output.desc = "Show active Python path (pyenv version)"
keymap.set("n", "<leader>pv", function()
	print(vim.fn.system("which python"))
end, opts_output)

-- Quick import statements (like auto-imports in NestJS)
opts_silent.desc = "Import FastAPI"
keymap.set("n", "<leader>pif", "ifrom fastapi import FastAPI<CR>app = FastAPI()<Esc>", opts_silent)

opts_silent.desc = "Import LangChain OpenAI"
keymap.set("n", "<leader>pio", "ifrom langchain.llms import OpenAI<CR>llm = OpenAI()<Esc>", opts_silent)

-- Create pyproject.toml with ruff config
opts_output.desc = "Create pyproject.toml template"
keymap.set("n", "<leader>ptoml", function()
	local template_path = vim.fn.stdpath("config") .. "/templates/pyproject.toml"
	vim.cmd("edit pyproject.toml")
	vim.cmd("read " .. template_path)
	vim.cmd("1delete") -- Remove first empty line
	vim.notify("Created pyproject.toml with Ruff config!", vim.log.levels.INFO)
end, opts_output)
