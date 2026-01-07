# LSP Architecture - New Flow

## Overview

The new LSP configuration uses Neovim's built-in `vim.lsp.config()` API (Neovim 0.10+) which automatically loads LSP server configurations from the `after/lsp/` directory.

## Architecture Components

### 1. **Global LSP Setup** - `lua/cybercat/lsp.lua`
**Loaded from**: `init.lua` (line 6: `require("cybercat.lsp")`)

**Purpose**: 
- Define global LSP keybindings (via `LspAttach` autocmd)
- Configure diagnostic signs and behavior
- Shared across ALL language servers

**Key Features**:
- ✅ Keybindings: `gR`, `gD`, `gd`, `gi`, `gt`, `<leader>ca`, `<leader>rn`, etc.
- ✅ Diagnostic navigation: `[d`, `]d`
- ✅ Diagnostic signs: Error (), Warn (), Hint (󰠠), Info ()

### 2. **LSP Plugin Config** - `lua/cybercat/plugins/lsp/lsp.lua`
**Loaded by**: lazy.nvim plugin manager

**Purpose**:
- Set up `cmp-nvim-lsp` for autocompletion capabilities
- Configure default capabilities for ALL LSP servers using `vim.lsp.config("*", {...})`

**Key Configuration**:
```lua
vim.lsp.config("*", {
  capabilities = capabilities,  -- Apply to all servers
})
```

### 3. **Per-Server Configs** - `after/lsp/*.lua`
**Auto-loaded by**: Neovim's `vim.lsp.config()` system

**Purpose**: 
- Per-language server customization
- Filetypes, commands, on_attach callbacks, etc.

**Available Configs**:
- `angularls.lua` - Angular Language Server
- `emmet_ls.lua` - Emmet abbreviations
- `eslint.lua` - ESLint linting
- `graphql.lua` - GraphQL
- `marksman.lua` - Markdown
- `svelte.lua` - Svelte framework

## How It Works

### Flow Diagram

```
init.lua
  └─> require("cybercat.lsp")  ────────────┐
         ├─> Global keybindings             │
         └─> Diagnostic config              │
                                            │
lazy.nvim                                   │
  └─> plugins/lsp/lsp.lua                   │
         ├─> cmp-nvim-lsp capabilities      │
         └─> vim.lsp.config("*", {...})     │
                                            ▼
                                    LSP Server Starts
                                            │
                                            ▼
                              after/lsp/{server}.lua
                                  (Auto-loaded by Neovim)
                                            │
                              ┌─────────────┴─────────────┐
                              │                           │
                         Server-specific            Server-specific
                           filetypes                  on_attach
                                            │
                                            ▼
                                    LspAttach event fires
                                            │
                                            ▼
                              Global keybindings applied
                                   (from lsp.lua)
```

### Step-by-Step

1. **Neovim starts** → `init.lua` loads
2. **`require("cybercat.lsp")`** → Sets up global keybindings and diagnostics
3. **lazy.nvim loads** → `plugins/lsp/lsp.lua` configures default capabilities
4. **You open a file** (e.g., `test.ts`)
5. **Neovim detects filetype** → Looks for matching LSP server
6. **Neovim checks** `after/lsp/*.lua` for server-specific config
7. **Server starts** with merged config (defaults + server-specific)
8. **LspAttach event fires** → Global keybindings attach to buffer
9. **You get LSP features**: autocomplete, diagnostics, go-to-definition, etc.

## Configuration Examples

### Example 1: Simple Filetype Override

**File**: `after/lsp/marksman.lua`
```lua
return {
  filetypes = { "markdown", "mdx" },
}
```

**Effect**: Marksman LSP only activates for `.md` and `.mdx` files.

### Example 2: Custom Command

**File**: `after/lsp/angularls.lua`
```lua
return {
  cmd = {
    "/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/bin/ngserver",
    "--stdio",
    "--tsProbeLocations",
    "/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/lib/node_modules/typescript",
    "--ngProbeLocations",
    "/Users/cybercat/.local/share/fnm/node-versions/v20.19.1/installation/lib/node_modules/@angular",
    "--angularCoreVersion",
    "18.0.1",
  },
  filetypes = { "typescript", "html", "typescriptreact", "htmlangular" },
  root_dir = require("lspconfig").util.root_pattern("angular.json", ".git"),
  on_attach = function(client, bufnr)
    print("Angular Language Server attached to " .. vim.bo.filetype)
    client.server_capabilities.documentFormattingProvider = false
  end,
}
```

**Effect**: 
- Custom Angular LSP binary path
- Specific Angular/TypeScript versions
- Disable formatting (use Conform instead)

### Example 3: Custom Autocmd

**File**: `after/lsp/svelte.lua`
```lua
return {
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.js", "*.ts" },
      callback = function(ctx)
        client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
      end,
    })
  end,
}
```

**Effect**: Notify Svelte LSP when JS/TS files change (for reactivity).

## Adding a New Language Server

### Method 1: Auto-Discovery (Recommended)

If the LSP server follows standard conventions:

1. Install the server (e.g., via Mason):
   ```vim
   :Mason
   " Search and install the server
   ```

2. **That's it!** The server will use:
   - Default capabilities from `plugins/lsp/lsp.lua`
   - Global keybindings from `lua/cybercat/lsp.lua`
   - Default filetypes from the server itself

### Method 2: Custom Configuration

If you need custom settings:

1. Install the server via Mason

2. Create `after/lsp/{servername}.lua`:
   ```lua
   return {
     filetypes = { "your", "filetypes" },
     settings = {
       yourServer = {
         option1 = value1,
       },
     },
   }
   ```

3. Restart Neovim or `:LspRestart`

### Example: Add Python (pyright)

**Option A**: Just install via Mason (auto-works)
```vim
:Mason
" Install 'pyright'
```

**Option B**: Custom config
```lua
-- after/lsp/pyright.lua
return {
  filetypes = { "python" },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
      },
    },
  },
}
```

## Keybindings Reference

| Key | Mode | Action | Description |
|-----|------|--------|-------------|
| `gR` | n | Telescope lsp_references | Show references |
| `gD` | n | vim.lsp.buf.declaration | Go to declaration |
| `gd` | n | vim.lsp.buf.definition | Go to definition |
| `gi` | n | Telescope lsp_implementations | Show implementations |
| `gt` | n | Telescope lsp_type_definitions | Show type definitions |
| `<leader>ca` | n,v | vim.lsp.buf.code_action | Code actions |
| `<leader>rn` | n | vim.lsp.buf.rename | Smart rename |
| `<leader>D` | n | Telescope diagnostics | Buffer diagnostics |
| `<leader>d` | n | vim.diagnostic.open_float | Line diagnostics |
| `[d` | n | vim.diagnostic.jump(-1) | Previous diagnostic |
| `]d` | n | vim.diagnostic.jump(1) | Next diagnostic |
| `K` | n | vim.lsp.buf.hover | Hover documentation |
| `<leader>rs` | n | :LspRestart | Restart LSP |

## Migration from Old Config

### Old Structure (nvim-lspconfig style)

```lua
-- plugins/lsp/lspconfig.lua
return {
  "neovim/nvim-lspconfig",
  config = function()
    local lspconfig = require("lspconfig")
    
    lspconfig.lua_ls.setup({
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {...}
    })
    
    lspconfig.tsserver.setup({...})
    lspconfig.pyright.setup({...})
    -- ... 20 more servers
  end
}
```

**Problems**:
- ❌ All configs in one huge file
- ❌ Hard to find specific server config
- ❌ Duplicated on_attach for every server
- ❌ Difficult to maintain

### New Structure (vim.lsp.config style)

```
lua/cybercat/
  ├── lsp.lua                    # Global: keybindings, diagnostics
  └── plugins/lsp/
      └── lsp.lua                # Default: capabilities for all servers

after/lsp/
  ├── angularls.lua              # Per-server: Angular-specific
  ├── marksman.lua               # Per-server: Markdown-specific
  ├── pyright.lua                # Per-server: Python-specific
  └── ...                        # One file per server
```

**Benefits**:
- ✅ Modular: One file per server
- ✅ Clean: No boilerplate duplication
- ✅ Auto-discovery: Neovim finds configs automatically
- ✅ Maintainable: Easy to find and edit
- ✅ Scalable: Add servers without editing main config

## Debugging

### Check if LSP is running

```vim
:LspInfo
```

Should show active LSP clients for current buffer.

### Check loaded configs

```vim
:lua print(vim.inspect(vim.lsp.config))
```

Shows all registered LSP configs.

### Check if server config exists

```bash
ls -la nvim/.config/nvim/after/lsp/
```

Should show `.lua` files for each server.

### Enable LSP logging

```vim
:lua vim.lsp.set_log_level("debug")
```

Then check: `~/.local/state/nvim/lsp.log`

### Test server manually

```vim
:lua vim.lsp.start({ name = 'lua_ls', cmd = {'lua-language-server'} })
```

## Best Practices

### 1. Keep Global Settings in `lsp.lua`

✅ **Do**: Put shared keybindings in `lua/cybercat/lsp.lua`
```lua
keymap.set("n", "gd", vim.lsp.buf.definition, opts)
```

❌ **Don't**: Duplicate keybindings in every `after/lsp/*.lua` file

### 2. Minimal Server Configs

✅ **Do**: Only override what's necessary
```lua
-- after/lsp/marksman.lua
return {
  filetypes = { "markdown", "mdx" },
}
```

❌ **Don't**: Copy entire default config when only changing one option

### 3. Use Mason for Installation

✅ **Do**: Install servers via Mason
```vim
:Mason
```

❌ **Don't**: Manually install LSP servers unless necessary

### 4. One Config Per Server

✅ **Do**: Create separate files
```
after/lsp/lua_ls.lua
after/lsp/tsserver.lua
after/lsp/pyright.lua
```

❌ **Don't**: Combine multiple servers in one file

## Advantages Over Old Config

| Feature | Old (lspconfig.lua) | New (vim.lsp.config) |
|---------|---------------------|----------------------|
| File count | 1 huge file (270 lines) | Multiple small files (~5 lines each) |
| Maintainability | Hard to navigate | Easy to find |
| Boilerplate | High (repeated on_attach) | Low (inherited defaults) |
| Auto-discovery | No | Yes |
| Modularity | Poor | Excellent |
| Neovim version | 0.8+ | 0.10+ (required) |

## Conclusion

Your new LSP architecture is:
- ✅ **Cleaner**: Separated concerns
- ✅ **Modular**: One file per server
- ✅ **Maintainable**: Easy to find and edit
- ✅ **Modern**: Uses Neovim 0.10+ features
- ✅ **Scalable**: Easy to add new servers

**Old config preserved at**: `plugins/oldfile/lspconfig.lua` (reference only, not loaded)

---

**Created**: January 7, 2026  
**Neovim Version**: 0.10+  
**Status**: Active ✅
