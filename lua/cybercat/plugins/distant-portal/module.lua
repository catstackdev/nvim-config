-- SSH Distant Module Entry Point
-- Can be required as a standalone module or used within plugin config
--
-- Usage as module:
--   local distantSsh = require('cybercat.plugins.distant-portal')
--   distantSsh.setup({ ... })
--
-- Usage in plugin (current):
--   Loaded automatically by distant-portal.lua

local M = {}

-- Module components
M.config = require("cybercat.plugins.distant-portal.config")
M.ui = require("cybercat.plugins.distant-portal.ui")
M.statusline = require("cybercat.plugins.distant-portal.statusline")
M.autocmds = require("cybercat.plugins.distant-portal.autocmds")
M.commands = require("cybercat.plugins.distant-portal.commands")

-- Default configuration
local defaultConfig = {
  sshConfigPath = vim.fn.expand("~/.ssh/config"),
  excludePatterns = { "^github" },
  autoReconnect = {
    enabled = true,
    maxRetries = 3,
    retryDelay = 2000,
  },
  fileWatching = {
    enabled = true,
  },
}

-- Setup function (makes it plugin-like)
function M.setup(userConfig)
  userConfig = userConfig or {}
  
  -- Merge user config with defaults
  local finalConfig = vim.tbl_deep_extend("force", defaultConfig, userConfig)
  
  -- Configure modules
  M.config.setup(finalConfig)
  
  -- Setup autocmds
  M.autocmds.setup()
  
  -- Register commands
  M.commands.registerCommands()
  
  -- Setup telescope extension
  M.ui.setupTelescopeExtension()
  
  return M
end

-- Quick access functions
function M.connect()
  M.ui.showConnectionPicker()
end

function M.disconnect()
  M.ui.disconnect()
end

function M.reconnect()
  M.autocmds.reconnect()
end

function M.browseFiles()
  M.ui.browseRemoteFiles()
end

function M.search(pattern, path)
  M.ui.searchRemote(pattern, path)
end

function M.getStatus()
  return M.config.getConnectionStatus()
end

-- Export version for compatibility checks
M.version = "1.0.0"
M._compatible_distant = "0.20.x"

return M
