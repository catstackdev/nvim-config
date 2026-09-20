-- Lualine Statusline Component for Distant
-- Shows connection status in the statusline

local M = {}

local config = require("cybercat.plugins.distant-portal.config")

-- Status icons
local icons = {
  disconnected = "⚫",
  connecting = "⏳",
  connected = "🔌",
  error = "⚠️",
}

-- Status colors (for lualine)
local colors = {
  disconnected = { fg = "#888888" },
  connecting = { fg = "#FFDA7B" },
  connected = { fg = "#3EFFDC" },
  error = { fg = "#FF4A4A" },
}

-- Get status text
local function getStatusText()
  local status = config.getConnectionStatus()

  if status.status == "disconnected" then
    return ""
  end

  local icon = icons[status.status] or icons.disconnected
  local serverName = status.server or "unknown"

  if status.status == "connected" then
    return icon .. " " .. serverName
  elseif status.status == "connecting" then
    return icon .. " " .. serverName
  elseif status.status == "error" then
    return icon .. " " .. serverName
  end

  return ""
end

-- Get status color
local function getStatusColor()
  local status = config.getConnectionStatus()
  return colors[status.status] or colors.disconnected
end

-- Lualine component function
function M.component()
  return {
    getStatusText,
    color = getStatusColor,
    cond = function()
      local status = config.getConnectionStatus()
      return status.status ~= "disconnected"
    end,
  }
end

-- Simple text component (for non-lualine statuslines)
function M.simpleComponent()
  return getStatusText()
end

-- Check if connection is active
function M.isConnected()
  local status = config.getConnectionStatus()
  return status.status == "connected"
end

return M
