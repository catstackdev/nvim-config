-- Core keymaps loader
-- Split from keymaps.lua (172 lines) into organized modules

-- Set leader key FIRST before any other keymaps
vim.g.mapleader = " "

-- Load core keymap modules
require("cybercat.core.keymaps-core.basic")          -- Insert mode, search, numbers
require("cybercat.core.keymaps-core.file-ops")       -- Save, quit operations
require("cybercat.core.keymaps-core.windows")        -- Window/tab management
require("cybercat.core.keymaps-core.plugins")        -- Lazy, Mason, LSP info
require("cybercat.core.keymaps-core.lsp-imports")    -- LSP import management
require("cybercat.core.keymaps-core.git")            -- Git operations
