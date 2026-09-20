-- SSH Config Parser & Connection Manager
-- Parses ~/.ssh/config and manages distant connections

local M = {}

-- State management
M.state = {
  servers = {},
  activeConnection = nil,
  connectionStatus = "disconnected", -- disconnected, connecting, connected, error
  lastError = nil,
  cache = {
    timestamp = 0,
    ttl = 300, -- 5 minutes cache TTL
  },
}

-- Default configuration
M.config = {
  sshConfigPath = vim.fn.expand("~/.ssh/config"),
  excludePatterns = { "^github" }, -- Exclude hosts matching these patterns
  autoReconnect = {
    enabled = true,
    maxRetries = 3,
    retryDelay = 2000,
  },
}

-- Parse SSH config file
-- Returns array of server definitions
local function parseSshConfig(configPath)
  local servers = {}
  local currentHost = nil

  local file = io.open(configPath, "r")
  if not file then
    vim.notify("Failed to open SSH config: " .. configPath, vim.log.levels.WARN)
    return servers
  end

  for line in file:lines() do
    -- Trim whitespace
    line = line:gsub("^%s+", ""):gsub("%s+$", "")

    -- Skip comments and empty lines
    if line:match("^#") or line == "" then
      goto continue
    end

    -- Parse Host directive
    local host = line:match("^Host%s+(.+)$")
    if host then
      -- Check if host should be excluded
      local shouldExclude = false
      for _, pattern in ipairs(M.config.excludePatterns) do
        if host:match(pattern) then
          shouldExclude = true
          break
        end
      end

      if not shouldExclude then
        currentHost = {
          alias = host,
          hostname = nil,
          user = nil,
          identityFile = nil,
          port = 22,
        }
        table.insert(servers, currentHost)
      else
        currentHost = nil
      end
      goto continue
    end

    -- Parse host properties (only if currentHost is set)
    if currentHost then
      local hostname = line:match("^HostName%s+(.+)$")
      if hostname then
        -- Remove inline comments
        currentHost.hostname = hostname:gsub("%s*#.*$", ""):gsub("%s+$", "")
        goto continue
      end

      local user = line:match("^User%s+(.+)$")
      if user then
        -- Remove inline comments
        currentHost.user = user:gsub("%s*#.*$", ""):gsub("%s+$", "")
        goto continue
      end

      local identityFile = line:match("^IdentityFile%s+(.+)$")
      if identityFile then
        -- Remove inline comments and expand path
        identityFile = identityFile:gsub("%s*#.*$", ""):gsub("%s+$", "")
        currentHost.identityFile = vim.fn.expand(identityFile)
        goto continue
      end

      local port = line:match("^Port%s+(%d+)$")
      if port then
        currentHost.port = tonumber(port)
        goto continue
      end
    end

    ::continue::
  end

  file:close()

  -- Filter out incomplete entries (must have at least hostname)
  local validServers = {}
  for _, server in ipairs(servers) do
    if server.hostname then
      table.insert(validServers, server)
    end
  end

  return validServers
end

-- Get servers list (with caching)
function M.getServers(forceRefresh)
  local currentTime = os.time()

  -- Check cache validity
  if
    not forceRefresh
    and #M.state.servers > 0
    and (currentTime - M.state.cache.timestamp) < M.state.cache.ttl
  then
    return M.state.servers
  end

  -- Parse config
  M.state.servers = parseSshConfig(M.config.sshConfigPath)
  M.state.cache.timestamp = currentTime

  return M.state.servers
end

-- Build connection string from server config
function M.buildConnectionString(server)
  if not server or not server.hostname then
    return nil
  end

  local connectionString = "ssh://"

  if server.user then
    connectionString = connectionString .. server.user .. "@"
  end

  connectionString = connectionString .. server.hostname

  if server.port and server.port ~= 22 then
    connectionString = connectionString .. ":" .. tostring(server.port)
  end

  return connectionString
end

-- Find server by alias
function M.findServerByAlias(alias)
  local servers = M.getServers()
  for _, server in ipairs(servers) do
    if server.alias == alias then
      return server
    end
  end
  return nil
end

-- Set active connection
function M.setActiveConnection(serverAlias, status)
  M.state.activeConnection = serverAlias
  M.state.connectionStatus = status or "connected"
end

-- Clear active connection
function M.clearActiveConnection()
  M.state.activeConnection = nil
  M.state.connectionStatus = "disconnected"
  M.state.lastError = nil
end

-- Get connection status
function M.getConnectionStatus()
  return {
    server = M.state.activeConnection,
    status = M.state.connectionStatus,
    error = M.state.lastError,
  }
end

-- Set connection error
function M.setConnectionError(error)
  M.state.connectionStatus = "error"
  M.state.lastError = error
end

-- Update configuration
function M.setup(userConfig)
  M.config = vim.tbl_deep_extend("force", M.config, userConfig or {})
end

-- Get server display name
function M.getServerDisplayName(server)
  if not server then
    return "Unknown"
  end

  local display = server.alias or server.hostname

  if server.user then
    display = display .. " (" .. server.user .. "@" .. server.hostname .. ")"
  end

  return display
end

-- Verify active connection with distant CLI
function M.verifyConnection()
  local handle = io.popen("distant manager list 2>&1")
  if not handle then
    return false
  end
  
  local result = handle:read("*a")
  handle:close()
  
  -- Check if there are any connections (table has data rows beyond header)
  local lines = vim.split(result, "\n")
  local dataLines = 0
  for _, line in ipairs(lines) do
    if line:match("^|") and not line:match("selected") and not line:match("^+-") then
      dataLines = dataLines + 1
    end
  end
  
  return dataLines > 0
end

-- Check if buffer is remote (distant://)
function M.isRemoteBuffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  return bufname:match("^distant://") ~= nil
end

-- Get remote path from buffer
function M.getRemotePath(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local path = bufname:match("^distant://(.+)$")
  return path
end

return M
