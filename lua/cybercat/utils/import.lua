-- TypeScript/JavaScript LSP import management utility
-- Provides functions for managing imports via LSP code actions

local M = {}

-- Configuration
local DEFER_DELAY = 100 -- Delay between sequential actions (ms)
local DEFER_DELAY_LONG = 150 -- Longer delay for final fixAll action

local TS_LSP_NAMES = { "ts_ls", "tsserver", "angularls" }

-- LSP code action kinds
local ACTION_KINDS = {
  ADD_MISSING = "source.addMissingImports.ts",
  REMOVE_UNUSED = "source.removeUnusedImports.ts",
  ORGANIZE = "source.organizeImports.ts",
  FIX_ALL = "source.fixAll",
}

-- TypeScript-specific commands
local TS_COMMANDS = {
  ORGANIZE = "_typescript.organizeImports",
}

-- Helper: Check if TypeScript LSP is attached
local function is_ts_lsp_attached()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in ipairs(clients) do
    for _, lsp_name in ipairs(TS_LSP_NAMES) do
      if client.name == lsp_name then
        return true, client
      end
    end
  end
  return false, nil
end

-- Helper: Check LSP attachment and show warning if not attached
local function check_ts_lsp()
  local attached, client = is_ts_lsp_attached()
  if not attached then
    vim.notify("TypeScript LSP not attached", vim.log.levels.WARN)
    return false
  end
  return true, client
end

-- Helper: Execute code action by kind
local function execute_code_action(kind, callback)
  local params = vim.lsp.util.make_range_params()
  params.context = {
    only = { kind },
    diagnostics = {},
  }

  vim.lsp.buf_request(0, "textDocument/codeAction", params, function(err, actions)
    if err then
      vim.notify("LSP error: " .. vim.inspect(err), vim.log.levels.ERROR)
      if callback then
        callback(false, 0)
      end
      return
    end

    if not actions or vim.tbl_isempty(actions) then
      if callback then
        callback(false, 0)
      end
      return
    end

    local applied = 0
    for _, action in ipairs(actions) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
        applied = applied + 1
      elseif action.command then
        vim.lsp.buf.execute_command(action.command)
        applied = applied + 1
      end
    end

    if callback then
      callback(true, applied)
    end
  end)
end

-- Helper: Execute actions in sequence with delays
local function execute_action_sequence(actions, on_complete)
  local function execute_next(index)
    if index > #actions then
      if on_complete then
        on_complete()
      end
      return
    end

    local action = actions[index]
    local kind = action.kind
    local delay = action.delay or DEFER_DELAY

    execute_code_action(kind, function(success, count)
      if action.on_success and success then
        action.on_success(count)
      end

      vim.defer_fn(function()
        execute_next(index + 1)
      end, delay)
    end)
  end

  execute_next(1)
end

-- Add missing imports (TypeScript/JavaScript)
M.add_missing_imports = function()
  if not check_ts_lsp() then
    return
  end

  execute_code_action(ACTION_KINDS.ADD_MISSING, function(success, count)
    if success then
      vim.notify(string.format("Added %d import(s)", count or 0), vim.log.levels.INFO)
    else
      vim.notify("No missing imports found", vim.log.levels.INFO)
    end
  end)
end

-- Remove unused imports
M.remove_unused_imports = function()
  if not check_ts_lsp() then
    return
  end

  execute_code_action(ACTION_KINDS.REMOVE_UNUSED, function(success, count)
    if success then
      vim.notify("Removed unused imports", vim.log.levels.INFO)
    else
      vim.notify("No unused imports found", vim.log.levels.INFO)
    end
  end)
end

-- Organize imports (TypeScript/JavaScript)
M.organize_imports = function()
  if not check_ts_lsp() then
    return
  end

  -- Try TypeScript organize command first
  local success = pcall(vim.lsp.buf.execute_command, {
    command = TS_COMMANDS.ORGANIZE,
    arguments = { vim.api.nvim_buf_get_name(0) },
  })

  if success then
    vim.notify("Imports organized", vim.log.levels.INFO)
  else
    -- Fallback to code action
    execute_code_action(ACTION_KINDS.ORGANIZE, function(ok)
      if ok then
        vim.notify("Imports organized", vim.log.levels.INFO)
      else
        vim.notify("Failed to organize imports", vim.log.levels.WARN)
      end
    end)
  end
end

-- Fix all imports (add missing → remove unused → organize)
M.fix_all_imports = function()
  if not check_ts_lsp() then
    return
  end

  vim.notify("Fixing imports...", vim.log.levels.INFO)

  execute_action_sequence({
    { kind = ACTION_KINDS.ADD_MISSING },
    { kind = ACTION_KINDS.REMOVE_UNUSED },
    { kind = ACTION_KINDS.ORGANIZE },
  }, function()
    vim.notify("Imports fixed!", vim.log.levels.INFO)
  end)
end

-- Fix all code issues (imports + code fixes)
M.fix_all = function()
  if not check_ts_lsp() then
    return
  end

  vim.notify("Fixing all issues...", vim.log.levels.INFO)

  execute_action_sequence({
    { kind = ACTION_KINDS.ADD_MISSING },
    { kind = ACTION_KINDS.REMOVE_UNUSED },
    { kind = ACTION_KINDS.ORGANIZE },
    {
      kind = ACTION_KINDS.FIX_ALL,
      delay = DEFER_DELAY_LONG,
      on_success = function()
        vim.notify("All issues fixed!", vim.log.levels.INFO)
      end,
    },
  }, function()
    -- Final completion notification handled by last action
  end)
end

-- Debug: Show available code actions
M.debug_code_actions = function()
  local params = vim.lsp.util.make_range_params()
  params.context = {
    diagnostics = vim.lsp.diagnostic.get_line_diagnostics(),
  }

  vim.lsp.buf_request(0, "textDocument/codeAction", params, function(err, actions)
    if err then
      print("Error:", vim.inspect(err))
      return
    end

    if not actions or vim.tbl_isempty(actions) then
      print("No code actions available")
      return
    end

    print("Available code actions:")
    for i, action in ipairs(actions) do
      print(string.format("  %d. %s", i, action.title or action.kind))
      if action.kind then
        print(string.format("     Kind: %s", action.kind))
      end
    end
  end)
end

-- Show import statistics for current file
M.import_stats = function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local import_count = 0

  -- Count imports (supports various import syntax)
  for _, line in ipairs(lines) do
    if line:match("^import ") or line:match("^import{") or line:match("^import%s*{") then
      import_count = import_count + 1
    end
  end

  -- Get diagnostics for unused imports
  local diagnostics = vim.diagnostic.get(0)
  local unused_count = 0
  for _, diag in ipairs(diagnostics) do
    if diag.message:match("is declared but") or diag.message:match("never used") then
      unused_count = unused_count + 1
    end
  end

  vim.notify(string.format("Imports: %d total, %d unused", import_count, unused_count), vim.log.levels.INFO)
end

return M
