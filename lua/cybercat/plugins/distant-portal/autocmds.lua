-- Autocmds for Distant
-- Handles auto-reconnect, file watching, and buffer management

local M = {}

local config = require("cybercat.plugins.distant-portal.config")

-- State for reconnection attempts
local reconnectState = {
  attempts = 0,
  timer = nil,
  lastServer = nil,
}

-- State for file watchers
local fileWatchers = {
  -- bufnr -> { path, watching }
}

-- Attempt to reconnect to last server
local function attemptReconnect()
  if not config.config.autoReconnect.enabled then
    return
  end

  local connectionStatus = config.getConnectionStatus()

  if connectionStatus.status == "connected" then
    reconnectState.attempts = 0
    return
  end

  if reconnectState.attempts >= config.config.autoReconnect.maxRetries then
    vim.notify(
      "Auto-reconnect failed after " .. reconnectState.attempts .. " attempts",
      vim.log.levels.ERROR
    )
    reconnectState.attempts = 0
    return
  end

  if not reconnectState.lastServer then
    return
  end

  reconnectState.attempts = reconnectState.attempts + 1

  vim.notify(
    "Auto-reconnecting to " .. reconnectState.lastServer .. " (attempt " .. reconnectState.attempts .. ")",
    vim.log.levels.INFO
  )

  -- Find server and attempt reconnection
  local server = config.findServerByAlias(reconnectState.lastServer)
  if server then
    local ui = require("cybercat.plugins.distant-portal.ui")
    ui.connectToServer(server)

    -- Schedule next retry if this fails
    if reconnectState.timer then
      reconnectState.timer:stop()
    end

    reconnectState.timer = vim.defer_fn(function()
      local status = config.getConnectionStatus()
      if status.status ~= "connected" then
        attemptReconnect()
      else
        reconnectState.attempts = 0
      end
    end, config.config.autoReconnect.retryDelay)
  end
end

-- Setup reconnection tracking
local function setupReconnectTracking()
  -- Store last connected server
  vim.api.nvim_create_autocmd("User", {
    pattern = "DistantConnected",
    callback = function()
      local status = config.getConnectionStatus()
      if status.server then
        reconnectState.lastServer = status.server
        reconnectState.attempts = 0
      end
    end,
    desc = "Track last connected distant server",
  })

  -- Detect disconnection
  vim.api.nvim_create_autocmd("User", {
    pattern = "DistantDisconnected",
    callback = function()
      if config.config.autoReconnect.enabled then
        vim.defer_fn(attemptReconnect, config.config.autoReconnect.retryDelay)
      end
    end,
    desc = "Auto-reconnect on disconnection",
  })
end

-- Check connection health on buffer read
local function setupBufferHealthCheck()
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePre" }, {
    callback = function(ev)
      if not config.isRemoteBuffer(ev.buf) then
        return
      end

      local status = config.getConnectionStatus()
      if status.status ~= "connected" then
        vim.notify(
          "Remote buffer but no active connection. Use <leader>dc to connect.",
          vim.log.levels.WARN
        )
      end
    end,
    desc = "Check distant connection health on buffer operations",
  })
end

-- Setup file watching for remote files
local function setupFileWatching()
  if not config.config.fileWatching or not config.config.fileWatching.enabled then
    return
  end

  -- Auto-watch on remote file open
  vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function(ev)
      if not config.isRemoteBuffer(ev.buf) then
        return
      end

      local path = config.getRemotePath(ev.buf)
      if not path then
        return
      end

      -- Start watching this file
      M.watchFile(ev.buf, path)
    end,
    desc = "Auto-watch remote files for changes",
  })

  -- Stop watching on buffer unload
  vim.api.nvim_create_autocmd("BufUnload", {
    callback = function(ev)
      if fileWatchers[ev.buf] then
        M.unwatchFile(ev.buf)
      end
    end,
    desc = "Stop watching remote files on buffer close",
  })
end

-- Watch a remote file for changes
function M.watchFile(bufnr, path)
  if fileWatchers[bufnr] then
    return -- Already watching
  end

  local connectionStatus = config.getConnectionStatus()
  if connectionStatus.status ~= "connected" then
    vim.notify("Cannot watch file: not connected", vim.log.levels.WARN)
    return
  end

  -- Execute DistantWatch command
  local cmd = "DistantWatch " .. vim.fn.shellescape(path)
  local ok, err = pcall(vim.cmd, cmd)

  if ok then
    fileWatchers[bufnr] = {
      path = path,
      watching = true,
    }
    vim.notify("Watching remote file: " .. path, vim.log.levels.INFO)
  else
    vim.notify("Failed to watch file: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Stop watching a remote file
function M.unwatchFile(bufnr)
  local watcher = fileWatchers[bufnr]
  if not watcher then
    return
  end

  local cmd = "DistantUnwatch " .. vim.fn.shellescape(watcher.path)
  local ok, err = pcall(vim.cmd, cmd)

  if ok then
    fileWatchers[bufnr] = nil
    vim.notify("Stopped watching: " .. watcher.path, vim.log.levels.INFO)
  else
    vim.notify("Failed to unwatch file: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Setup LSP for remote buffers
local function setupRemoteLSP()
  vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function(ev)
      if not config.isRemoteBuffer(ev.buf) then
        return
      end

      -- Trigger LSP attach for remote buffer
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          -- Get filetype and ensure LSP is attached
          local ft = vim.api.nvim_buf_get_option(ev.buf, "filetype")
          if ft ~= "" then
            vim.cmd("LspStart")
          end
        end
      end, 500) -- Small delay to let buffer fully load
    end,
    desc = "Attach LSP to remote buffers",
  })
end

-- Graceful cleanup on exit
local function setupGracefulExit()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      -- Stop all file watchers
      for bufnr, _ in pairs(fileWatchers) do
        M.unwatchFile(bufnr)
      end

      -- Stop reconnection timer
      if reconnectState.timer then
        reconnectState.timer:stop()
      end
    end,
    desc = "Cleanup distant resources on exit",
  })
end

-- Initialize all autocmds
function M.setup()
  setupReconnectTracking()
  setupBufferHealthCheck()
  setupFileWatching()
  setupRemoteLSP()
  setupGracefulExit()
end

-- Manual reconnect trigger
function M.reconnect()
  reconnectState.attempts = 0
  attemptReconnect()
end

return M
