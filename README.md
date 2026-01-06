# Cybercat's Neovim Configuration

A feature-rich Neovim configuration with AI-powered coding assistance, modern
UI, and extensive plugin ecosystem. Built for productivity and customization.

![Neovim](https://img.shields.io/badge/Neovim-0.10+-green.svg?style=flat-square&logo=neovim)
![Lua](https://img.shields.io/badge/Lua-5.1+-blue.svg?style=flat-square&logo=lua)
![License](https://img.shields.io/badge/license-MIT-purple.svg?style=flat-square)

## Features

### 🤖 AI-Powered Coding

- **Avante** - AI pair programming assistant
- **Aider** - Command-line AI coding assistant integration
- **LLM** - Direct LLM integration for code generation
- Multiple AI provider support (Claude, GPT, DeepSeek, Ollama)

### 🎨 Beautiful UI

- **Colorschemes**: Catppuccin, Gruvbox, Nightfox, Eldritch
- **Bufferline**: Tab-like buffer management
- **Lualine**: Sleek statusline
- **Snacks**: Dashboard and notification system
- **Indent Blankline**: Visual indent guides
- **Illuminate**: Highlight word under cursor

### 📝 Editor Enhancements

- **Treesitter**: Advanced syntax highlighting and text objects
- **LSP**: Full language server protocol support (Mason)
- **Autocomplete**: nvim-cmp with multiple sources
- **Snippets**: LuaSnip for code snippets
- **Auto-pairs**: Smart bracket pairing
- **Comment**: Easy commenting with gcc/gbc
- **Surround**: Manipulate surrounding characters
- **Multi-cursor**: Visual multi-cursor editing

### 🔍 Navigation & Search

- **Telescope**: Fuzzy finder for files, buffers, grep
- **Harpoon**: Quick file navigation
- **Snipe**: Fast buffer switching
- **Neo-tree**: File explorer sidebar
- **Mini.files**: Alternative file manager
- **Flash**: Enhanced f/t motions
- **Which-key**: Keybinding helper

### 🛠️ Development Tools

- **Git Integration**: Gitsigns, Lazygit, Neogit, Git Conflict
- **Testing**: Neotest for running tests
- **Debugging**: DAP support
- **REST Client**: Test HTTP APIs
- **Database**: DadBod UI for SQL queries
- **Docker/Kubernetes**: kubectl integration

### 📦 Language Support

- Full LSP support for multiple languages
- Treesitter parsers for syntax highlighting
- Language-specific formatters (conform.nvim)
- Linting with nvim-lint

### ✨ Markdown & Writing

- **Render Markdown**: Beautiful markdown rendering
- **Markdown Preview**: Live preview in browser
- **Headlines**: Highlight markdown headings
- **Image**: Display images in terminal
- **Spell Check**: Built-in spell checking

## Installation

### Prerequisites

**Required:**

- Neovim >= 0.10.0
- Git
- A Nerd Font (recommended: MesloLGS NF)

**Optional (for full functionality):**

- ripgrep (for Telescope grep)
- fd (for Telescope file finding)
- lazygit (for git UI)
- Node.js (for LSP servers)
- Python 3 (for some plugins)
- make, gcc (for Treesitter parsers)

### Windows

```powershell
# Install Neovim
winget install Neovim.Neovim
# or: choco install neovim
# or: scoop install neovim

# Install dependencies
winget install BurntSushi.ripgrep.MSVC
winget install sharkdp.fd
winget install JesseDuffield.lazygit

# Clone config
git clone https://github.com/catstackdev/nvim-config.git "$env:LOCALAPPDATA\nvim"

# Launch Neovim (plugins will auto-install)
nvim
```

### macOS

```bash
# Install Neovim
brew install neovim

# Install dependencies
brew install ripgrep fd lazygit

# Clone config
git clone https://github.com/catstackdev/nvim-config.git ~/.config/nvim

# Launch Neovim (plugins will auto-install)
nvim
```

### Linux

```bash
# Install Neovim (example for Ubuntu/Debian)
sudo apt install neovim

# Install dependencies
sudo apt install ripgrep fd-find
# Note: fd may be named 'fdfind' on Debian/Ubuntu

# Clone config
git clone https://github.com/catstackdev/nvim-config.git ~/.config/nvim

# Launch Neovim (plugins will auto-install)
nvim
```

## Post-Installation

### 1. First Launch

On first launch, lazy.nvim will automatically install all plugins. This may
take a few minutes.

```vim
:Lazy sync
```

### 2. Install LSP Servers

Press `<Space>` to open Which-key menu, then:

```vim
:Mason
```

Install language servers you need (e.g., `lua_ls`, `tsserver`, `pyright`)

### 3. Update Treesitter Parsers

```vim
:TSUpdate
```

### 4. Configure AI Features (Optional)

For AI features, you'll need API keys:

- Edit `lua/cybercat/plugins/avante.lua` for Avante configuration
- Edit `lua/cybercat/plugins/ai-aider.lua` for Aider configuration
- Set environment variables for API keys:

```bash
# In your shell profile (.bashrc, .zshrc, etc.)
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"
export DEEPSEEK_API_KEY="your-key"
```

## Key Bindings

Leader key: `<Space>`

### General

| Key           | Description                 |
| ------------- | --------------------------- |
| `<Space>`     | Open Which-key menu         |
| `<C-h/j/k/l>` | Navigate splits             |
| `<C-s>`       | Save file                   |
| `jk` / `kj`   | Exit insert mode (probably) |

### File Navigation

| Key         | Description                  |
| ----------- | ---------------------------- |
| `<Space>ff` | Find files (Telescope)       |
| `<Space>fg` | Live grep (Telescope)        |
| `<Space>fb` | Find buffers (Telescope)     |
| `<Space>e`  | Toggle file explorer         |
| `<Space>a`  | Harpoon add file             |
| `<C-e>`     | Harpoon quick menu (probably)|

### Git

| Key         | Description          |
| ----------- | -------------------- |
| `<Space>gg` | Open Lazygit         |
| `<Space>gc` | Git commits          |
| `<Space>gs` | Git status           |
| `]c` / `[c` | Next/prev git hunk   |

### LSP

| Key         | Description               |
| ----------- | ------------------------- |
| `gd`        | Go to definition          |
| `gr`        | Find references           |
| `K`         | Hover documentation       |
| `<Space>ca` | Code action               |
| `<Space>rn` | Rename symbol             |
| `[d` / `]d` | Next/prev diagnostic      |

### AI Features

| Key         | Description               |
| ----------- | ------------------------- |
| `<Space>aa` | Open Avante               |
| `<Space>ai` | AI chat                   |

> **Note:** Full keybindings are defined in `lua/cybercat/core/keymaps.lua` and
> individual plugin configs. Press `<Space>` in Neovim to see all available
> keybindings via Which-key.

## Configuration Structure

```
nvim/
├── init.lua                    # Entry point
├── lua/
│   └── cybercat/
│       ├── core/               # Core configuration
│       │   ├── init.lua        # Core initialization
│       │   ├── options.lua     # Vim options
│       │   ├── keymaps.lua     # Global keymaps
│       │   ├── autocmds.lua    # Autocommands
│       │   └── colors.lua      # Color utilities
│       ├── lazy.lua            # Lazy.nvim plugin manager
│       ├── plugins/            # Plugin configurations
│       │   ├── lsp/            # LSP configs
│       │   ├── colorscheme/    # Colorscheme configs
│       │   └── *.lua           # Individual plugin configs
│       ├── cybercat-app/       # Custom chat application
│       ├── modules/            # Reusable modules
│       └── utils/              # Utility functions
└── spell/                      # Spell check dictionaries
```

## Customization

### Changing Colorscheme

Edit `lua/cybercat/plugins/colorscheme.lua`:

```lua
-- Available: catppuccin, gruvbox, nightfox, eldritch
vim.cmd("colorscheme catppuccin")
```

### Adding Plugins

Create a new file in `lua/cybercat/plugins/`:

```lua
-- lua/cybercat/plugins/my-plugin.lua
return {
  "author/plugin-name",
  config = function()
    require("plugin-name").setup({
      -- your config
    })
  end,
}
```

### Disabling Plugins

Add to `lua/cybercat/plugins/disabled.lua` or set `enabled = false`:

```lua
return {
  "plugin/name",
  enabled = false,
}
```

## Environment Variables

| Variable          | Description                      | Default   |
| ----------------- | -------------------------------- | --------- |
| `NEOVIM_MODE`     | Neovim mode (default, skitty)    | `default` |
| `MD_HEADING_BG`   | Markdown heading background      | -         |
| `OPENAI_API_KEY`  | OpenAI API key for AI features   | -         |
| `ANTHROPIC_API_KEY` | Anthropic API key for Claude   | -         |
| `DEEPSEEK_API_KEY`  | DeepSeek API key               | -         |

## Troubleshooting

### Plugins not loading

```vim
:Lazy sync
:Lazy health
```

### LSP not working

```vim
:LspInfo
:Mason
```

### Treesitter issues

```vim
:checkhealth nvim-treesitter
:TSUpdate
```

### Clear cache and reinstall

```bash
# Backup first!
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim

# Restart Neovim
nvim
```

## Performance

This config is optimized for performance with:

- Lazy loading of plugins (lazy.nvim)
- Treesitter performance optimizations
- Async LSP operations
- Minimal startup plugins

Typical startup time: < 50ms

## Contributing

This is a personal configuration, but feel free to:

- Fork and customize for your needs
- Open issues for bugs
- Submit PRs for improvements

## Credits

Built with and inspired by:

- [LazyVim](https://github.com/LazyVim/LazyVim)
- [NvChad](https://github.com/NvChad/NvChad)
- [Neovim](https://neovim.io/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)

## License

MIT License - feel free to use and modify as you wish.

---

**Author:** [@catstackdev](https://github.com/catstackdev)

**Last Updated:** January 2025
# Test Sync - Tue Jan  6 23:55:19 +0630 2026

