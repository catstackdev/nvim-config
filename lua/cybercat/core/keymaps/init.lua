-- Core keymaps loader
-- Split from keymaps.lua (172 lines) into organized modules

-- Set leader key FIRST before any other keymaps
vim.g.mapleader = " "

-- Load core keymap modules
require("cybercat.core.keymaps.basic")          -- Insert mode, search, numbers
require("cybercat.core.keymaps.file-ops")       -- Save, quit operations
require("cybercat.core.keymaps.windows")        -- Window/tab management
require("cybercat.core.keymaps.plugins")        -- Lazy, Mason, LSP info
require("cybercat.core.keymaps.lsp-imports")    -- LSP import management
require("cybercat.core.keymaps.git")            -- Git operations
require("cybercat.core.keymaps.files")          -- File permissions, bash execution
