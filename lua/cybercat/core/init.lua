-- ============================================================================
-- Core Initialization
-- ============================================================================
-- Loads all core modules in the correct order
-- ============================================================================

-- Load configuration (options, autocmds, commands)
require("cybercat.core.config")

-- Load keymaps
require("cybercat.core.keymaps")

-- Load UI (highlights, colors)
require("cybercat.core.ui.highlights")

-- Load filetype settings
require("cybercat.core.filetype")

-- Load low power mode (if needed)
require("cybercat.core.lowPower10s")

-- Auto-start Claude socket for IDE integration
require("cybercat.core.claude-socket").setup()
