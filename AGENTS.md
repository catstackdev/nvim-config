# Agent Guidelines for Neovim Configuration

## Overview
Custom Neovim configuration (~2,200 lines of Lua) using lazy.nvim plugin manager. Organized under `cybercat` namespace with 100+ plugins. Supports multiple modes via `NEOVIM_MODE` environment variable.

## Build/Lint/Test Commands

### Plugin Management
```vim
:Lazy sync          " Install/update all plugins
:Lazy update        " Update plugins only
:Lazy check         " Check for updates
:Lazy clean         " Remove unused plugins
:Lazy restore       " Restore plugins from lockfile
:Mason              " Open Mason UI for LSP/tools
:MasonUpdate        " Update Mason packages
```

### Linting
```vim
<leader>l           " Manually trigger linting (nvim-lint)
:CspellToggle       " Toggle spell checking
```

**Active Linters** (lua/cybercat/plugins/linting.lua):
- JavaScript/TypeScript: `eslint_d`, `cspell`
- Python: `pylint`, `cspell`
- Markdown/HTML/Text: `cspell`

**Lint Events**: `BufEnter`, `BufWritePost`, `InsertLeave`

### Formatting
```vim
:Conform format     " Format current buffer (currently disabled)
<leader>fa          " Fix all (imports + code via LSP)
<leader>fi          " Fix imports (add + remove + organize)
```

**Note**: LSP formatting on save is **enabled** (lua/cybercat/lsp.lua:55-62)

### Testing
No formal test framework. Manual testing via:
- `lua/cybercat/cybercat-app/test/` modules
- `:lua require('module').function()` for unit testing

### LSP Commands
```vim
:LspInfo            " Show attached LSP servers
:LspRestart         " Restart LSP server
<leader>lp          " Open LspInfo
gd                  " Go to definition (LSP)
gR                  " Show references (Telescope)
<leader>ca          " Code actions
<leader>rn          " Rename symbol
K                   " Hover documentation
```

## Code Style Guidelines

### Lua Style

#### Indentation & Formatting
- **2 spaces** (tabs expanded to spaces - options.lua:17-18)
- **No line wrapping** (options.lua:22)
- **Cursorline enabled** (options.lua:28)

#### Naming Conventions
```lua
-- Variables: camelCase
local userName = "cybercat"
local isEnabled = true
local maxRetries = 3

-- Functions: camelCase
local function getUserConfig() end
local function setupKeymap() end

-- Modules/Plugins: PascalCase or lowercase
require("cybercat.core.options")
require("cybercat.plugins.telescope")

-- Constants: UPPER_CASE (rare in this codebase)
local MAX_BUFFER_SIZE = 1024
```

#### Module Pattern
```lua
-- Plugin configuration (lazy.nvim style)
return {
  "author/plugin-name",
  event = { "BufReadPre", "BufNewFile" },  -- Lazy load trigger
  dependencies = {
    "dep1",
    "dep2",
  },
  config = function()
    local plugin = require("plugin")
    plugin.setup({
      -- Configuration options
    })
  end,
}
```

#### Import Pattern
```lua
-- Require at top of file
local telescope = require("telescope")
local actions = require("telescope.actions")
local keymap = vim.keymap

-- Safely require with pcall for optional dependencies
local ok, plugin = pcall(require, "optional-plugin")
if not ok then
  vim.notify("Plugin not available", vim.log.levels.WARN)
  return
end
```

#### Error Handling
```lua
-- Use pcall for potentially failing operations
local ok, result = pcall(function()
  return risky_operation()
end)
if not ok then
  vim.notify("Operation failed: " .. result, vim.log.levels.ERROR)
end

-- Check if LSP is attached before operations
if not vim.lsp.buf_is_attached(bufnr) then
  vim.notify("No language server attached", vim.log.levels.WARN)
  return
end

-- Graceful degradation for commands
if not command -v tool_name then
  return  -- Silently skip
end
```

#### Keymaps
```lua
-- Always include description for which-key
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", {
  desc = "Fuzzy find files in cwd"
})

-- Specify mode explicitly
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
keymap.set("n", "<leader>wa", "<cmd>wall<CR>", { desc = "Save all files" })

-- Buffer-local keymaps in LSP attach
local opts = { buffer = bufnr, silent = true }
opts.desc = "Show LSP references"
keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
```

**Leader Key**: Space (` `)

**Common Prefixes**:
- `<leader>f` - Find/Telescope operations
- `<leader>l` - LSP operations
- `<leader>g` - Git operations
- `<leader>w` - Window/write operations
- `<leader>q` - Quit operations
- `<leader>t` - Tab/terminal operations

#### Comments
```lua
-- Single-line comments with space after --

-- Function documentation above function
-- Parameters: arg1 (string), arg2 (number)
-- Returns: boolean
local function myFunction(arg1, arg2)
  -- Implementation comments inline
  return true
end
```

Avoid excessive comments - prefer self-documenting code.

### File Organization

```
lua/cybercat/
├── core/              # Core Neovim configuration
│   ├── init.lua       # Loads all core modules
│   ├── options.lua    # vim.opt settings
│   ├── keymaps.lua    # Global keymaps
│   ├── autocmds.lua   # Autocommands
│   ├── command.lua    # Custom commands
│   └── highlights/    # Color scheme customizations
├── plugins/           # Plugin configurations (100+ files)
│   ├── lsp/          # LSP-specific plugins
│   │   ├── lsp.lua   # Main LSP config
│   │   └── mason.lua # Mason setup
│   └── *.lua         # Individual plugin configs
├── cybercat-app/     # Custom applications
│   └── test/         # Test modules
├── lsp.lua           # LSP keymaps & autocmds
└── lazy.lua          # Lazy.nvim bootstrap
```

**Plugin Loading** (lazy.lua:17-19):
- `cybercat.plugins` - Main plugins
- `cybercat.plugins.lsp` - LSP plugins
- `cybercat.plugins.colorscheme` - Theme plugins

### LSP Configuration

#### Server Setup Pattern
Servers configured in `after/lsp/{server_name}.lua`:

```lua
-- after/lsp/lua_ls.lua
return {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      completion = {
        callSnippet = "Replace",
      },
    },
  },
  on_attach = function(client, bufnr)
    -- Custom setup per server
  end,
}
```

**Installed LSP Servers** (mason.lua:30-49):
- ts_ls, html, cssls, tailwindcss, svelte
- lua_ls, graphql, emmet_ls, prismals
- pyright, terraformls, jsonls, dockerls
- marksman (markdown), angularls

#### LSP Capabilities
Enhanced completion capabilities (lsp.lua:38-54):
- Snippet support
- Markdown documentation
- Insert/replace mode
- Label details

## Environment Variables

```bash
NEOVIM_MODE=default|skitty    # Changes UI behavior
MD_HEADING_BG=<color>         # Markdown heading background
```

**Skitty Mode** (init.lua:9-13, options.lua:8-14):
- Disables line numbers
- Enables auto-save plugin
- 500ms startup delay

## Plugin System

### Lazy Loading Strategy
```lua
-- Load on event
event = { "BufReadPre", "BufNewFile" }

-- Load on command
cmd = "Telescope"

-- Load on filetype
ft = { "lua", "vim" }

-- Load on key press
keys = { "<leader>ff" }

-- Dependencies load before main plugin
dependencies = { "nvim-lua/plenary.nvim" }
```

### Disabled Plugins (disabled.lua:12-13)
```lua
{ "akinsho/bufferline.nvim", enabled = is_neovide }
{ "Rics-Dev/project-explorer.nvim", enabled = is_neovide }
```

## Git Workflow

### Debug Code Policy
**NEVER** commit debug code like init.lua:15-32 (gitcommit notifications).
Remove before committing:
```lua
-- DELETE debug autocmds
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.notify("DEBUG", vim.log.levels.ERROR)  -- REMOVE THIS
  end,
})
```

## Common Patterns

### Conditional Plugin Loading
```lua
enabled = vim.g.neovim_mode == "skitty"  -- Only in skitty mode
enabled = not vim.g.neovide               -- Disable in Neovide
```

### Safe Require
```lua
local ok, module = pcall(require, "module-name")
if not ok then return end
```

### Notification Levels
```lua
vim.notify("Info message", vim.log.levels.INFO)
vim.notify("Warning", vim.log.levels.WARN)
vim.notify("Error occurred", vim.log.levels.ERROR)
```

## Performance Notes
- Disabled RTP plugins (lazy.lua:33-42): gzip, tarPlugin, tohtml, zipPlugin
- Plugin updates don't notify (lazy.lua:27)
- Config changes don't notify (lazy.lua:46)

## Cursor/Copilot Rules
No external rules files found (`.cursor/rules/`, `.cursorrules`, `.github/copilot-instructions.md`).

## Testing Guidelines
When modifying:
1. Source file: `:luafile %`
2. Test keymaps work as expected
3. Check `:Lazy check` for errors
4. Verify LSP with `:LspInfo` in appropriate filetype
5. Remove any debug print() or vim.notify() statements
