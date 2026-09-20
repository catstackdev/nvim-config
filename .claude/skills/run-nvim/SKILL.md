---
name: run-nvim
description: Run, test, and verify this Neovim config headlessly instead of guessing whether a change works. Use this whenever you edit anything under ~/.config/nvim (init.lua, lua/cybercat/**, plugin specs, LSP or keymap files), whenever the user says "run nvim", "check my config", "did that break anything", "why isn't this plugin loading", "is the LSP attaching", or reports a startup error, slow startup, or a plugin that misbehaves. Also use it before telling the user a Neovim change is done - a config edit is not verified until it has been loaded headlessly.
---

# Running this Neovim config

This is a 118-plugin lazy.nvim config at `~/.config/nvim` (a stow symlink into
`~/dotfiles/nvim/.config/nvim`). Lua edits fail loudly at *load* time, not at edit time,
so "it looks right" is not evidence. Load it and read the output.

## Never launch interactive nvim

`nvim` without `--headless` takes over the terminal and never returns — the session hangs
and the user has to rescue it. Every command below is headless and exits on its own.
If you genuinely need an interactive check, ask the user to run it and report back.

## The default move: verify.sh

```bash
~/.config/nvim/verify.sh --quick    # ~5s: syntax, startup, plugins, lockfile, startup time
~/.config/nvim/verify.sh            # ~15s: adds :checkhealth
```

Exit code 0 means no errors; 1 means something is broken and the failing lines are printed.
Run `--quick` after any Lua edit. Run the full version when touching LSP, mason, treesitter,
or providers, since `:checkhealth` is what actually knows whether a server is installed.

Startup output that mentions cloning is lazy.nvim installing a missing plugin — harmless,
but rerun so you see a clean pass rather than reporting the noise as a result.

## Targeted checks

Reach for these when verify.sh says something is wrong and you need to localize it, or when
the question is narrower than "is the config healthy".

**Syntax-check one file** (no plugins, instant, empty output means fine):
```bash
nvim --headless --clean -c "lua assert(loadfile('lua/cybercat/plugins/ui/lualine.lua'))" -c 'qa'
```

**See startup errors in full** — stderr carries them even when the exit code is 0:
```bash
nvim --headless '+qa' 2>&1 | head -40
```

**Is a plugin loaded, and why not:**
```bash
nvim --headless -c 'lua local p = require("lazy.core.config").plugins["telescope.nvim"]; print(vim.inspect({ installed = p._.installed, loaded = p._.loaded ~= nil, lazy = p.lazy }))' -c 'qa'
```

**What a keymap is bound to:**
```bash
nvim --headless -c 'lua print(vim.fn.maparg("<leader>ff", "n"))' -c 'qa'
```

**Does the LSP attach to a real file** (open an actual file of that type and wait — servers
attach asynchronously, so a check without `vim.wait` reports an empty list and lies to you):
```bash
nvim --headless /path/to/file.ts \
  -c 'lua vim.wait(8000, function() return #vim.lsp.get_clients({bufnr=0}) > 0 end)' \
  -c 'lua print(vim.inspect(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr=0}))))' \
  -c 'qa'
```

**One plugin's healthcheck** instead of the whole 3000-line report:
```bash
nvim --headless '+checkhealth lazy' '+w! /tmp/h.txt' '+qa' && cat /tmp/h.txt
```

**Plugin install / restore to the lockfile:**
```bash
nvim --headless '+Lazy! restore' '+qa'   # match lazy-lock.json exactly
nvim --headless '+Lazy! sync' '+qa'      # install + update + clean; can take minutes
```

## Both startup modes

`init.lua` branches on `NEOVIM_MODE` (`default`, and `skitty` which adds a 500ms wait).
A change that only works in one mode is a bug the user will hit later, so check both when
you touch `init.lua` or core startup:

```bash
NEOVIM_MODE=skitty nvim --headless '+qa' 2>&1 | head -20
```

verify.sh already covers both.

## Experimenting without risking the real config

`NVIM_APPNAME` gives nvim a separate config *and* data directory, so a throwaway experiment
cannot corrupt the working setup or its plugin state:

```bash
NVIM_APPNAME=nvim-scratch nvim --headless '+qa'
```

Use this when trying a plugin the user has not committed to, and clean up
`~/.config/nvim-scratch` and `~/.local/share/nvim-scratch` afterwards.

## Timeouts and patience

Give headless commands room: plain startup is ~120ms, `:checkhealth` ~15s, and a `Lazy sync`
or mason install can run for minutes. Set a generous timeout rather than killing a run
halfway — a half-finished plugin install leaves state the next run has to repair.

## Reporting back

Say what you ran and what it printed. "verify.sh --quick passes, 118 plugins, 105ms startup"
is a result; "the config should work now" is not. If `:checkhealth` reports errors that
predate your change (missing optional providers, a plugin's own broken healthcheck), say so
explicitly rather than presenting them as new breakage or hiding them.
