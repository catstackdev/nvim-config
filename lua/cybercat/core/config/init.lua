-- ============================================================================
-- Core Configuration Loader
-- ============================================================================
-- Loads all core configuration files in the correct order
-- ============================================================================

-- Load options first (sets up leader key and basic settings)
require("cybercat.core.config.options")

-- Load autocommands
require("cybercat.core.config.autocmds")

-- Load custom commands
require("cybercat.core.config.commands")
