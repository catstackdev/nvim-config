-- Telescope UI Pickers for SSH Distant
-- Provides interactive UI for connection management and file operations

local M = {}

local config = require("cybercat.plugins.distant-portal.config")

-- Check if telescope is available
local function hasTelescope()
  local ok, _ = pcall(require, "telescope")
  return ok
end

-- SSH Connection Picker
-- Shows all servers from SSH config with connection actions
function M.showConnectionPicker()
  if not hasTelescope() then
    vim.notify("Telescope is required for connection picker", vim.log.levels.ERROR)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local servers = config.getServers(true) -- Force refresh

  if #servers == 0 then
    vim.notify("No SSH servers found in " .. config.config.sshConfigPath, vim.log.levels.WARN)
    return
  end

  pickers
    .new({}, {
      prompt_title = "SSH Servers (Launch Distant) | <CR>=Launch <C-e>=Edit Config",
      finder = finders.new_table({
        results = servers,
        entry_maker = function(server)
          local displayName = config.getServerDisplayName(server)
          local connectionString = config.buildConnectionString(server)

          return {
            value = server,
            display = displayName,
            ordinal = displayName,
            connectionString = connectionString,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        -- Default action: Launch distant server on remote via SSH
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection then
            M.connectToServer(selection.value) -- Uses DistantLaunch by default
          end
        end)

        -- <C-e>: Edit SSH config
        map("i", "<C-e>", function()
          actions.close(prompt_bufnr)
          vim.cmd("edit " .. config.config.sshConfigPath)
        end)

        return true
      end,
    })
    :find()
end

-- Connect to server via DistantLaunch (launches distant server on remote)
function M.connectToServer(server, useLaunch)
  local connectionString = config.buildConnectionString(server)

  if not connectionString then
    vim.notify("Invalid server configuration", vim.log.levels.ERROR)
    return
  end

  config.setActiveConnection(server.alias, "connecting")
  
  -- For SSH connections, use Launch by default (it spawns distant server)
  -- For distant:// connections, use Connect (connects to existing server)
  local useConnect = useLaunch == false or connectionString:match("^distant://")
  local action = useConnect and "Connecting to" or "Launching distant server on"
  
  vim.notify(action .. " " .. server.alias .. "...", vim.log.levels.INFO)

  -- Build SSH-specific options
  local options = {}
  
  if server.identityFile then
    table.insert(options, "ssh.identity_file=" .. server.identityFile)
  end
  
  -- Use SSH backend (more reliable than default)
  table.insert(options, "ssh.backend=ssh")
  
  -- Use SSH config settings (reads ~/.ssh/config for all settings)
  table.insert(options, "ssh.config=true")

  -- Build connection command - use Launch for SSH, Connect for distant://
  local cmd = useConnect and "DistantConnect " or "DistantLaunch "
  cmd = cmd .. connectionString
  
  if #options > 0 then
    cmd = cmd .. ' options="' .. table.concat(options, ",") .. '"'
  end

  -- Execute connection command
  local ok, err = pcall(vim.cmd, cmd)

  if ok then
    -- Wait a bit for connection to establish, then verify
    vim.defer_fn(function()
      local isConnected = config.verifyConnection()
      
      if isConnected then
        config.setActiveConnection(server.alias, "connected")
        vim.notify("✓ Connected to " .. server.alias, vim.log.levels.INFO)
        
        -- Trigger user event for autocmds
        vim.api.nvim_exec_autocmds("User", { pattern = "DistantConnected" })
      else
        config.setActiveConnection(server.alias, "error")
        vim.notify("⚠ Command succeeded but no session found. Checking...", vim.log.levels.WARN)
        -- Show what command was run for debugging
        vim.notify("Ran: " .. cmd, vim.log.levels.INFO)
      end
    end, 3000) -- 3 second delay for server to launch and connect
  else
    config.setConnectionError(tostring(err))
    vim.notify("Failed to " .. (useConnect and "connect" or "launch") .. ": " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Launch distant server on remote host
function M.launchDistantServer(server)
  local connectionString = config.buildConnectionString(server)

  if not connectionString then
    vim.notify("Invalid server configuration", vim.log.levels.ERROR)
    return
  end

  config.setActiveConnection(server.alias, "connecting")
  vim.notify("Launching distant server on " .. server.alias .. "...", vim.log.levels.INFO)

  -- Build SSH-specific options
  local options = {}
  
  if server.identityFile then
    table.insert(options, "ssh.identity_file=" .. server.identityFile)
  end
  
  -- Use SSH backend
  table.insert(options, "ssh.backend=ssh")
  
  -- Batch mode to avoid interactive prompts
  table.insert(options, "ssh.batch_mode=true")
  
  -- Use SSH config settings
  table.insert(options, "ssh.config=~/.ssh/config")

  -- Build launch command
  local cmd = "DistantLaunch " .. connectionString
  
  if #options > 0 then
    cmd = cmd .. ' options="' .. table.concat(options, ",") .. '"'
  end

  -- Execute launch command
  local ok, err = pcall(vim.cmd, cmd)

  if ok then
    config.setActiveConnection(server.alias, "connected")
    vim.notify("Distant server launched on " .. server.alias, vim.log.levels.INFO)
  else
    config.setConnectionError(tostring(err))
    vim.notify("Failed to launch: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Remote file browser (uses built-in telescope-distant extension)
function M.browseRemoteFiles(path)
  if not hasTelescope() then
    vim.notify("Telescope is required for file browser", vim.log.levels.ERROR)
    return
  end

  -- Verify actual connection
  if not config.verifyConnection() then
    vim.notify("No active connection. Connect to a server first with <leader>dc", vim.log.levels.WARN)
    return
  end

  -- Use telescope-distant extension
  local ok, err = pcall(function()
    require("telescope").extensions.distant.files({
      cwd = path,
    })
  end)

  if not ok then
    vim.notify("Failed to open file browser: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Remote search picker
function M.searchRemote(pattern, searchPath)
  if not hasTelescope() then
    vim.notify("Telescope is required for remote search", vim.log.levels.ERROR)
    return
  end

  -- Verify actual connection
  if not config.verifyConnection() then
    vim.notify("No active connection. Connect to a server first with <leader>dc", vim.log.levels.WARN)
    return
  end

  -- Prompt for search pattern if not provided
  if not pattern then
    vim.ui.input({ prompt = "Search pattern: " }, function(input)
      if input and input ~= "" then
        M.searchRemote(input, searchPath)
      end
    end)
    return
  end

  -- Build search command
  local cmd = "DistantSearch " .. vim.fn.shellescape(pattern)

  if searchPath then
    cmd = cmd .. " path=" .. vim.fn.shellescape(searchPath)
  end

  -- Execute search (results go to quickfix)
  local ok, err = pcall(vim.cmd, cmd)

  if ok then
    vim.notify("Search completed for: " .. pattern, vim.log.levels.INFO)
    vim.cmd("copen") -- Open quickfix list
  else
    vim.notify("Search failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Active sessions picker
function M.showActiveSessions()
  if not hasTelescope() then
    vim.notify("Telescope is required for session picker", vim.log.levels.ERROR)
    return
  end

  -- Get session info from distant
  local ok, distant = pcall(require, "distant")
  if not ok then
    vim.notify("Distant plugin not available", vim.log.levels.ERROR)
    return
  end

  -- Execute DistantSessionInfo to get session details
  vim.cmd("DistantSessionInfo")
end

-- Disconnect from current server
function M.disconnect()
  local connectionStatus = config.getConnectionStatus()

  if connectionStatus.status ~= "connected" then
    vim.notify("No active connection to disconnect", vim.log.levels.WARN)
    return
  end

  -- Execute disconnect (close session)
  local ok, err = pcall(vim.cmd, "DistantSessionKill")

  if ok then
    local serverName = connectionStatus.server or "server"
    config.clearActiveConnection()
    vim.notify("Disconnected from " .. serverName, vim.log.levels.INFO)
  else
    vim.notify("Failed to disconnect: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Open remote shell
function M.openRemoteShell(shellCmd)
  -- Verify actual connection
  if not config.verifyConnection() then
    vim.notify("No active connection. Connect to a server first with <leader>dc", vim.log.levels.WARN)
    return
  end

  local cmd = "DistantShell"
  if shellCmd then
    cmd = cmd .. " " .. shellCmd
  end

  local ok, err = pcall(vim.cmd, cmd)

  if not ok then
    vim.notify("Failed to open shell: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- Setup telescope extension commands
function M.setupTelescopeExtension()
  if not hasTelescope() then
    return
  end

  local telescope = require("telescope")

  -- Register custom pickers as telescope extension
  telescope.register_extension({
    exports = {
      ssh_servers = M.showConnectionPicker,
      remote_search = M.searchRemote,
    },
  })
end

return M
