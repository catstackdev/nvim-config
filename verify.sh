#!/bin/bash

# Neovim Configuration Verification Script
# Loads the config headlessly and reports anything broken.
# Usage: ./verify.sh [-q|--quick] [-h|--help]

set -uo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUICK=0

echo "🔍 Verifying Neovim Configuration"
echo "================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; WARNINGS=$((WARNINGS + 1)); }
error()   { echo -e "${RED}❌ $1${NC}"; ERRORS=$((ERRORS + 1)); }
info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }

usage() {
    cat <<EOF
Usage: verify.sh [options]

  -q, --quick   Skip :checkhealth (much faster, ~2s instead of ~30s)
  -h, --help    Show this help

Exit code is 0 when no errors were found, 1 otherwise.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -q|--quick) QUICK=1; shift ;;
        -h|--help)  usage; exit 0 ;;
        *) error "Unknown option: $1"; usage; exit 1 ;;
    esac
done

TMPDIR_RUN="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_RUN"' EXIT

# Check nvim itself and the tools the config shells out to
check_prereqs() {
    info "Checking prerequisites..."

    if ! command -v nvim >/dev/null 2>&1; then
        error "nvim not found in PATH"
        return 1
    fi

    local version
    version="$(nvim --version | head -1 | sed 's/^NVIM v//')"
    local major minor
    major="$(echo "$version" | cut -d. -f1)"
    minor="$(echo "$version" | cut -d. -f2)"
    if [[ "$major" -gt 0 ]] || [[ "$minor" -ge 10 ]]; then
        success "Neovim $version"
    else
        error "Neovim $version is too old (config expects 0.10+)"
    fi

    # Required: without these the config or lazy.nvim cannot function
    local required=(git curl)
    local tool
    for tool in "${required[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            success "$tool found"
        else
            error "$tool not found (required)"
        fi
    done

    # Optional: features degrade but nothing breaks at startup
    local optional=(rg fd node npm python3 go cargo lazygit fzf trash)
    local missing=()
    for tool in "${optional[@]}"; do
        command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        success "All optional tools present (${optional[*]})"
    else
        warning "Missing optional tools: ${missing[*]}"
    fi
}

# Make sure nvim is actually reading the dotfiles copy, not a stale ~/.config/nvim
check_stow_link() {
    info "Checking config location..."

    local active
    active="$(nvim --headless -c 'lua io.write(vim.fn.stdpath("config"))' -c 'qa' 2>/dev/null)"

    if [[ -z "$active" ]]; then
        warning "Could not determine active config directory"
        return
    fi

    local active_real config_real
    active_real="$(cd "$active" 2>/dev/null && pwd -P)"
    config_real="$(cd "$CONFIG_DIR" && pwd -P)"

    if [[ "$active_real" == "$config_real" ]]; then
        success "nvim loads this config ($active)"
    else
        warning "nvim loads $active, but this script lives in $CONFIG_DIR (run 'stow nvim'?)"
    fi
}

# Pure syntax pass over every Lua file - catches typos lazy loading would hide
check_lua_syntax() {
    info "Checking Lua syntax..."

    local checker="$TMPDIR_RUN/syntax.lua"
    cat > "$checker" <<'LUA'
local root = vim.env.CYBERCAT_CONFIG_DIR
local bad = 0
for _, file in ipairs(vim.fn.globpath(root .. "/lua", "**/*.lua", false, true)) do
  local ok, err = loadfile(file)
  if not ok then
    bad = bad + 1
    io.write(err .. "\n")
  end
end
local init = root .. "/init.lua"
local ok, err = loadfile(init)
if not ok then
  bad = bad + 1
  io.write(err .. "\n")
end
os.exit(bad == 0 and 0 or 1)
LUA

    local out
    if out="$(CYBERCAT_CONFIG_DIR="$CONFIG_DIR" nvim --headless --clean -l "$checker" 2>&1)"; then
        local count
        count="$(find "$CONFIG_DIR/lua" -name '*.lua' | wc -l | tr -d ' ')"
        success "All $count Lua files parse cleanly"
    else
        error "Lua syntax errors:"
        echo "$out" | sed 's/^/    /'
    fi
}

# The real test: start the config the way a user would and catch anything on stderr
check_startup() {
    local mode="$1"
    info "Starting config headlessly (NEOVIM_MODE=$mode)..."

    local out status
    out="$(NEOVIM_MODE="$mode" nvim --headless '+qa' 2>&1)"
    status=$?

    if [[ $status -ne 0 ]]; then
        error "nvim exited with status $status in $mode mode"
        echo "$out" | sed 's/^/    /'
        return
    fi

    # Lazy.nvim and plugin errors surface on stderr without failing the exit code.
    # Git progress uses carriage returns and ANSI colour, so flatten it before judging.
    local cleaned
    cleaned="$(printf '%s' "$out" \
        | tr '\r' '\n' \
        | sed -E 's/\x1b\[[0-9;]*m//g' \
        | grep -vE 'objects:|Resolving deltas|Updating files|^ *remote:|Cloning into|Running task|Finished task|^ *$')"

    if [[ -z "$out" ]]; then
        success "Clean startup in $mode mode"
    elif [[ -z "$cleaned" ]]; then
        info "lazy.nvim installed/updated plugins during this run; startup was otherwise clean"
    else
        warning "Startup produced output in $mode mode:"
        printf '%s\n' "$cleaned" | head -20 | sed 's/^/    /'
    fi
}

# Report plugins lazy.nvim knows about but has not cloned yet
check_plugins() {
    info "Checking lazy.nvim plugins..."

    local probe="$TMPDIR_RUN/plugins.lua"
    cat > "$probe" <<'LUA'
local ok, lazy = pcall(require, "lazy")
if not ok then
  io.write("LAZY_MISSING\n")
  return
end
local total, missing = 0, {}
for _, plugin in ipairs(lazy.plugins()) do
  total = total + 1
  if not plugin._.installed then
    table.insert(missing, plugin.name)
  end
end
io.write(("TOTAL %d\n"):format(total))
if #missing > 0 then
  io.write("MISSING " .. table.concat(missing, " ") .. "\n")
end
LUA

    local out
    out="$(nvim --headless -c "luafile $probe" -c 'qa' 2>/dev/null)"

    if [[ "$out" == *LAZY_MISSING* ]] || [[ -z "$out" ]]; then
        error "lazy.nvim is not loaded (bootstrap failed?)"
        return
    fi

    local total
    total="$(echo "$out" | awk '/^TOTAL/ {print $2}')"
    success "$total plugins registered"

    local missing
    missing="$(echo "$out" | sed -n 's/^MISSING //p')"
    if [[ -n "$missing" ]]; then
        warning "Not installed yet: $missing"
        info "Fix with: nvim --headless '+Lazy! restore' +qa"
    else
        success "All plugins installed"
    fi
}

# The lockfile is what makes the config reproducible on another machine
check_lockfile() {
    info "Checking lazy-lock.json..."

    local lock="$CONFIG_DIR/lazy-lock.json"
    if [[ ! -f "$lock" ]]; then
        warning "lazy-lock.json not found"
        return
    fi

    if command -v jq >/dev/null 2>&1; then
        if jq empty "$lock" >/dev/null 2>&1; then
            success "lazy-lock.json valid ($(jq 'length' "$lock") pinned plugins)"
        else
            error "lazy-lock.json is not valid JSON"
        fi
    else
        success "lazy-lock.json present (install jq to validate it)"
    fi
}

check_startuptime() {
    info "Measuring startup time..."

    local log="$TMPDIR_RUN/startuptime.log"
    nvim --headless --startuptime "$log" '+qa' >/dev/null 2>&1
    if [[ ! -f "$log" ]]; then
        warning "Could not measure startup time"
        return
    fi

    # The summary line is "--- NVIM STARTED ---"; it is not always the last line
    local ms
    ms="$(awk '/NVIM STARTED/ {print $1}' "$log" | tail -1)"
    if [[ -z "$ms" ]]; then
        warning "Could not parse startup time from $log"
        return
    fi

    local whole="${ms%%.*}"
    if [[ "$whole" -lt 300 ]]; then
        success "Startup ${ms}ms"
    else
        warning "Startup ${ms}ms (slow - check 'nvim --startuptime /tmp/st.log')"
    fi
}

# :checkhealth is the authority on broken LSP servers, providers and treesitter
check_health() {
    info "Running :checkhealth (this takes a moment)..."

    local report="$TMPDIR_RUN/health.txt"
    nvim --headless '+checkhealth' "+w! $report" '+qa' >/dev/null 2>&1

    if [[ ! -s "$report" ]]; then
        warning "checkhealth produced no report"
        return
    fi

    # Neovim renders these as "- \u274c ERROR" / "- \u26a0\ufe0f WARNING", so match the word not the prefix
    local err_pattern='^-.*[[:space:]]ERROR[[:space:]]'
    local warn_pattern='^-.*[[:space:]]WARNING[[:space:]]'
    local err_count warn_count
    err_count="$(grep -cE "$err_pattern" "$report" || true)"
    warn_count="$(grep -cE "$warn_pattern" "$report" || true)"

    if [[ "$err_count" -eq 0 ]]; then
        success "checkhealth: no errors ($warn_count warnings)"
    else
        error "checkhealth: $err_count errors, $warn_count warnings"
        # Some healthchecks dump whole HTTP payloads into one line, so keep it readable
        grep -E "$err_pattern" "$report" | head -10 | cut -c1-160 | sed 's/^/    /'
    fi

    cp "$report" "${TMPDIR:-/tmp}/nvim-health.txt"
    info "Full report: ${TMPDIR:-/tmp}/nvim-health.txt"
}

main() {
    check_prereqs || { error "Cannot continue without nvim"; exit 1; }
    echo
    check_stow_link
    echo
    check_lua_syntax
    echo
    check_startup "default"
    echo
    check_startup "skitty"
    echo
    check_plugins
    echo
    check_lockfile
    echo
    check_startuptime

    if [[ $QUICK -eq 0 ]]; then
        echo
        check_health
    else
        echo
        info "Skipping :checkhealth (--quick)"
    fi

    echo
    echo "================================="
    if [[ $ERRORS -eq 0 ]]; then
        success "Verification passed ($WARNINGS warnings)"
        exit 0
    else
        error "Verification failed: $ERRORS errors, $WARNINGS warnings"
        exit 1
    fi
}

main
