# Agent Guidelines for Neovim Configuration

## Build/Lint/Test Commands

### Plugin Management
- **Install/Update Plugins**: `Lazy sync` or `Lazy update`
- **Check Plugin Status**: `Lazy check`
- **Clean Unused Plugins**: `Lazy clean`

### Linting
- **Lint Current File**: `<leader>l` (triggers nvim-lint)
- **Toggle CSpell**: `:CspellToggle`
- **Active Linters**:
  - JavaScript/TypeScript: `eslint_d`, `cspell`
  - Python: `pylint`, `cspell`
  - Markdown/HTML/Text: `cspell`

### Formatting
- **Format Current File**: `:Conform format` (when conform.nvim is enabled)
- **Auto-format on Save**: Currently disabled, enable in `lua/cybercat/plugins/conform.lua`

### Testing
- **Run Single Test**: No formal test framework detected
- **Manual Testing**: Use cybercat-app test modules in `lua/cybercat/cybercat-app/test/`

## Code Style Guidelines

### Lua Style
- **Indentation**: 2 spaces (tabs expanded to spaces)
- **Naming**: camelCase for variables/functions, PascalCase for modules
- **Requires**: Use `require()` at top of files
- **Local Variables**: Use `local` for all variables unless global is needed
- **Tables**: Use consistent formatting with proper indentation
- **Functions**: Use `function` keyword, not lambda syntax
- **Comments**: Minimal comments, prefer self-documenting code

### Plugin Configuration Pattern
```lua
return {
  "plugin/name",
  dependencies = { "dep1", "dep2" },
  config = function()
    -- Configuration here
  end,
}
```

### Keymaps
- **Leader Key**: Space (` `)
- **Pattern**: `<leader>[single_char]` for common actions
- **Descriptions**: Always include `desc` field for discoverability
- **Modes**: Specify mode explicitly (`n`, `i`, `v`, etc.)

### Error Handling
- **LSP Operations**: Use `pcall()` for potentially failing operations
- **User Notifications**: Use `vim.notify()` with appropriate log levels
- **Graceful Degradation**: Check if services are available before using them

### Imports and Dependencies
- **Lazy Loading**: Use `lazy = true` and appropriate `event` triggers
- **Conditional Loading**: Check for required tools before loading plugins
- **Plugin Dependencies**: Explicitly declare all dependencies

### File Organization
- **Core Modules**: `lua/cybercat/core/` - essential functionality
- **Plugins**: `lua/cybercat/plugins/` - plugin configurations
- **Applications**: `lua/cybercat/cybercat-app/` - custom applications
- **Modules**: `lua/cybercat/modules/` - utility modules

### Shell Scripts
- **Shebang**: Include `#!/bin/bash` or appropriate interpreter
- **Error Handling**: Use `set -e` for strict error checking
- **Functions**: Define reusable functions at top of scripts
- **Documentation**: Add comments for complex operations

## Cursor Rules
No Cursor rules (.cursor/rules/ or .cursorrules) found in the repository.

## Copilot Rules
No Copilot rules (.github/copilot-instructions.md) found in the repository.

## Additional Notes
- **Plugin Manager**: Uses lazy.nvim for plugin management
- **LSP**: Configured with mason.nvim for language server management
- **Theme**: Custom color scheme loaded from shell script
- **Performance**: Optimized with disabled RTP plugins and lazy loading
- **Security**: No malicious code detected, safe for agent operations</content>
</xai:function_call/>
</xai:function_call name="todowrite">
<parameter name="todos">[{"content": "Analyze Neovim configuration codebase structure and patterns", "status": "completed", "priority": "high", "id": "analyze_codebase"}, {"content": "Identify build/lint/test commands from plugin configurations", "status": "completed", "priority": "high", "id": "identify_commands"}, {"content": "Extract code style patterns from Lua files and configurations", "status": "completed", "priority": "high", "id": "extract_style_patterns"}, {"content": "Check for Cursor and Copilot rules in repository", "status": "completed", "priority": "medium", "id": "check_existing_rules"}, {"content": "Create comprehensive AGENTS.md file with all guidelines", "status": "completed", "priority": "high", "id": "create_agents_md"}]