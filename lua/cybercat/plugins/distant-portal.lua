-- Distant Portal v2.0.0 - Bug-free modular implementation
-- Remote development with SSH config integration, auto-reconnect, and enhanced UI
--
-- New architecture from personal-library/.config/distant-portal/
--
-- Features:
--   - SSH config parser with caching (~/.ssh/config)
--   - Telescope connection picker
--   - Auto-reconnect on connection loss (fixed)
--   - Remote file watching (fixed)
--   - LSP support on remote buffers
--   - TreeSitter support (fixed)
--   - Statusline integration
--   - Comprehensive commands and keymaps
--
-- Bug fixes from old version:
--   ✅ Connection verification (now parses distant manager list correctly)
--   ✅ Session kill (uses DistantClientStop instead of buggy DistantSessionKill)
--   ✅ File watching (uses correct DistantMetadata with watch=true)
--   ✅ State management (centralized in core/state.lua)
--   ✅ TreeSitter integration (proper buffer detection)
--
-- See: personal-library/.config/distant-portal/README.md

return {
  "chipsenkbeil/distant.nvim",
  branch = "v0.3",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    -- Load distant-portal using explicit loader
    -- Note: personal-library is in dotfiles, not ~/.config
    local dp_path = vim.fn.expand("~/dotfiles/personal-library/.config/distant-portal")
    
    -- Load the loader module directly
    local loader = dofile(dp_path .. "/loader.lua")
    
    -- Load and setup with configuration
    loader.load_and_setup({
      -- Portal configuration
      portal_config = {
        ssh_config_path = vim.fn.expand("~/.ssh/config"),
        exclude_patterns = { "^github", "^gitlab", "^bitbucket" },
        auto_reconnect = {
          enabled = true,
          max_retries = 3,
          retry_delay = 2000, -- 2 seconds
        },
        file_watching = {
          enabled = true,
          auto_reload = true,
        },
        connection = {
          timeout = 30000,
          interval = 500,
          use_ssh_config = true,
          batch_mode = true,
        },
        ui = {
          telescope_theme = "dropdown",
          show_notifications = true,
        },
        statusline = {
          enabled = true,
          show_when_disconnected = false,
        },
      },
      
      -- Keymaps (customize or set to false to disable)
      keymaps = {
        -- Connection management
        connect = "<leader>dc",
        disconnect = "<leader>dd",
        reconnect = "<leader>dr",
        status = "<leader>di",
        
        -- File operations
        browse = "<leader>df",
        open = "<leader>do",
        
        -- Search
        search = "<leader>ds",
        
        -- Shell
        shell = "<leader>dh",
        
        -- File watching
        watch = "<leader>dw",
        unwatch = "<leader>dW",
        
        -- Configuration
        edit_ssh = "<leader>dE",
      },
    })
    
    -- Additional custom keymaps for backward compatibility
    local keymap = vim.keymap
    
    keymap.set("n", "<leader>dl", function()
      vim.ui.input({ prompt = "Launch destination (e.g., ssh://example.com): " }, function(input)
        if input and input ~= "" then
          vim.cmd("DistantLaunch " .. input)
        end
      end)
    end, { desc = "Distant: Launch custom destination" })
    
    keymap.set("n", "<leader>dI", "<cmd>DistantSystemInfo<CR>", { desc = "Distant: Remote system info" })
    
    keymap.set("n", "<leader>dS", function()
      vim.ui.input({ prompt = "Search path: " }, function(path)
        if path and path ~= "" then
          -- Load init module using loader
          loader.setup_path()
          local init = require("init")
          init.search(nil, path)
        end
      end)
    end, { desc = "Distant: Search in specific path" })
    
    keymap.set("n", "<leader>dp", function()
      vim.ui.input({ prompt = "Command to spawn: " }, function(input)
        if input and input ~= "" then
          vim.cmd("DistantSpawn " .. input)
        end
      end)
    end, { desc = "Distant: Spawn remote command" })
    
    keymap.set("n", "<leader>dv", "<cmd>DistantClientVersion<CR>", { desc = "Distant: Client version" })
  end,
  
  -- Lazy-load on commands
  cmd = {
    "DistantConnect",
    "DistantDisconnect",
    "DistantReconnect",
    "DistantStatus",
    "DistantBrowse",
    "DistantSearch",
    "DistantShell",
    "DistantOpen",
    "DistantWatch",
    "DistantUnwatch",
    "DistantEditSSH",
    "DistantInfo",
    -- Built-in distant.nvim commands
    "DistantLaunch",
    "DistantSessionInfo",
    "DistantSystemInfo",
    "DistantSpawn",
    "DistantClientVersion",
  },
  
  -- Lazy-load on keymaps
  keys = {
    { "<leader>dc", desc = "Distant: Connect" },
    { "<leader>dl", desc = "Distant: Launch" },
    { "<leader>dd", desc = "Distant: Disconnect" },
    { "<leader>dr", desc = "Distant: Reconnect" },
    { "<leader>di", desc = "Distant: Status" },
    { "<leader>df", desc = "Distant: Browse files" },
    { "<leader>do", desc = "Distant: Open file" },
    { "<leader>ds", desc = "Distant: Search" },
    { "<leader>dh", desc = "Distant: Shell" },
    { "<leader>dw", desc = "Distant: Watch file" },
    { "<leader>dW", desc = "Distant: Unwatch file" },
    { "<leader>dE", desc = "Distant: Edit SSH config" },
  },
}
