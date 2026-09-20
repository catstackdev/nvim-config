-- Custom Command Wrappers for Distant
-- Provides enhanced commands with better defaults and error handling

local M = {}

local config = require("cybercat.plugins.distant-portal.config")
local ui = require("cybercat.plugins.distant-portal.ui")
local autocmds = require("cybercat.plugins.distant-portal.autocmds")

-- Helper: Check if connected
local function ensureConnected()
  if not config.verifyConnection() then
    vim.notify("Not connected to a server. Use :DistantConnectSSH or <leader>dc", vim.log.levels.WARN)
    return false
  end
  return true
end

-- Command: DistantConnectSSH [host]
-- Quick connect to SSH server by alias
function M.connectSSH(args)
  local alias = args.args

  if not alias or alias == "" then
    -- Show picker if no alias provided
    ui.showConnectionPicker()
    return
  end

  -- Find server by alias
  local server = config.findServerByAlias(alias)

  if not server then
    vim.notify("Server '" .. alias .. "' not found in SSH config", vim.log.levels.ERROR)
    return
  end

  ui.connectToServer(server)
end

-- Command: DistantReconnect
-- Manually trigger reconnection
function M.reconnect()
  autocmds.reconnect()
end

-- Command: DistantSessions
-- Show active sessions
function M.showSessions()
  ui.showActiveSessions()
end

-- Command: DistantEditSSHConfig
-- Open SSH config in split
function M.editSSHConfig()
  vim.cmd("split " .. config.config.sshConfigPath)
end

-- Command: DistantOpenFile [path]
-- Open remote file with better defaults
function M.openFile(args)
  if not ensureConnected() then
    return
  end

  local path = args.args

  if not path or path == "" then
    vim.ui.input({ prompt = "Remote path: " }, function(input)
      if input and input ~= "" then
        M.openFile({ args = input })
      end
    end)
    return
  end

  local cmd = "DistantOpen " .. vim.fn.shellescape(path)
  local ok, err = pcall(vim.cmd, cmd)

  if not ok then
    vim.notify("Failed to open file: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Command: DistantCopyFile <src> <dst>
-- Copy remote file with validation
function M.copyFile(args)
  if not ensureConnected() then
    return
  end

  local parts = vim.split(args.args, "%s+")
  if #parts < 2 then
    vim.notify("Usage: DistantCopyFile <src> <dst>", vim.log.levels.ERROR)
    return
  end

  local src = parts[1]
  local dst = parts[2]

  local cmd = "DistantCopy " .. vim.fn.shellescape(src) .. " " .. vim.fn.shellescape(dst)
  local ok, err = pcall(vim.cmd, cmd)

  if ok then
    vim.notify("Copied " .. src .. " to " .. dst, vim.log.levels.INFO)
  else
    vim.notify("Failed to copy: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Command: DistantRemoveFile <path>
-- Remove remote file with confirmation
function M.removeFile(args)
  if not ensureConnected() then
    return
  end

  local path = args.args

  if not path or path == "" then
    vim.notify("Usage: DistantRemoveFile <path>", vim.log.levels.ERROR)
    return
  end

  -- Confirm deletion
  vim.ui.select({ "Yes", "No" }, {
    prompt = "Delete remote file '" .. path .. "'?",
  }, function(choice)
    if choice == "Yes" then
      local cmd = "DistantRemove " .. vim.fn.shellescape(path)
      local ok, err = pcall(vim.cmd, cmd)

      if ok then
        vim.notify("Removed " .. path, vim.log.levels.INFO)
      else
        vim.notify("Failed to remove: " .. tostring(err), vim.log.levels.ERROR)
      end
    end
  end)
end

-- Command: DistantMakeDir <path>
-- Create remote directory with -p flag
function M.makeDir(args)
  if not ensureConnected() then
    return
  end

  local path = args.args

  if not path or path == "" then
    vim.ui.input({ prompt = "Directory path: " }, function(input)
      if input and input ~= "" then
        M.makeDir({ args = input })
      end
    end)
    return
  end

  local cmd = "DistantMkdir " .. vim.fn.shellescape(path) .. " all=true"
  local ok, err = pcall(vim.cmd, cmd)

  if ok then
    vim.notify("Created directory " .. path, vim.log.levels.INFO)
  else
    vim.notify("Failed to create directory: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Command: DistantRenameFile <src> <dst>
-- Rename remote file
function M.renameFile(args)
  if not ensureConnected() then
    return
  end

  local parts = vim.split(args.args, "%s+")
  if #parts < 2 then
    vim.notify("Usage: DistantRenameFile <src> <dst>", vim.log.levels.ERROR)
    return
  end

  local src = parts[1]
  local dst = parts[2]

  local cmd = "DistantRename " .. vim.fn.shellescape(src) .. " " .. vim.fn.shellescape(dst)
  local ok, err = pcall(vim.cmd, cmd)

  if ok then
    vim.notify("Renamed " .. src .. " to " .. dst, vim.log.levels.INFO)
  else
    vim.notify("Failed to rename: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Command: DistantSearchFiles [pattern]
-- Search remote files with prompt
function M.searchFiles(args)
  if not ensureConnected() then
    return
  end

  local pattern = args.args

  if not pattern or pattern == "" then
    ui.searchRemote() -- Will prompt for pattern
  else
    ui.searchRemote(pattern)
  end
end

-- Command: DistantWatchFile [path]
-- Watch current or specified file
function M.watchFile(args)
  if not ensureConnected() then
    return
  end

  local path = args.args

  if not path or path == "" then
    -- Watch current buffer
    local bufnr = vim.api.nvim_get_current_buf()
    if config.isRemoteBuffer(bufnr) then
      local remotePath = config.getRemotePath(bufnr)
      autocmds.watchFile(bufnr, remotePath)
    else
      vim.notify("Current buffer is not a remote file", vim.log.levels.WARN)
    end
  else
    -- Watch specified path (create dummy buffer entry)
    autocmds.watchFile(-1, path)
  end
end

-- Command: DistantUnwatchFile
-- Stop watching current file
function M.unwatchFile()
  local bufnr = vim.api.nvim_get_current_buf()
  autocmds.unwatchFile(bufnr)
end

-- Command: DistantDisconnect
-- Disconnect from current server
function M.disconnect()
  ui.disconnect()
end

-- Register all custom commands
function M.registerCommands()
  -- Connection commands
  vim.api.nvim_create_user_command("DistantConnectSSH", M.connectSSH, {
    nargs = "?",
    desc = "Connect to SSH server by alias (or show picker)",
  })

  vim.api.nvim_create_user_command("DistantReconnect", M.reconnect, {
    desc = "Manually reconnect to last server",
  })

  vim.api.nvim_create_user_command("DistantSessions", M.showSessions, {
    desc = "Show active distant sessions",
  })

  vim.api.nvim_create_user_command("DistantEditSSHConfig", M.editSSHConfig, {
    desc = "Edit SSH config file",
  })

  vim.api.nvim_create_user_command("DistantDisconnect", M.disconnect, {
    desc = "Disconnect from current server",
  })

  -- File operation commands
  vim.api.nvim_create_user_command("DistantOpenFile", M.openFile, {
    nargs = "?",
    desc = "Open remote file (prompts if no path given)",
  })

  vim.api.nvim_create_user_command("DistantCopyFile", M.copyFile, {
    nargs = "+",
    desc = "Copy remote file: <src> <dst>",
  })

  vim.api.nvim_create_user_command("DistantRemoveFile", M.removeFile, {
    nargs = 1,
    desc = "Remove remote file (with confirmation)",
  })

  vim.api.nvim_create_user_command("DistantMakeDir", M.makeDir, {
    nargs = "?",
    desc = "Create remote directory (with parent dirs)",
  })

  vim.api.nvim_create_user_command("DistantRenameFile", M.renameFile, {
    nargs = "+",
    desc = "Rename remote file: <src> <dst>",
  })

  -- Search and watch commands
  vim.api.nvim_create_user_command("DistantSearchFiles", M.searchFiles, {
    nargs = "?",
    desc = "Search remote files (prompts for pattern)",
  })

  vim.api.nvim_create_user_command("DistantWatchFile", M.watchFile, {
    nargs = "?",
    desc = "Watch remote file for changes",
  })

  vim.api.nvim_create_user_command("DistantUnwatchFile", M.unwatchFile, {
    desc = "Stop watching current remote file",
  })
end

return M
