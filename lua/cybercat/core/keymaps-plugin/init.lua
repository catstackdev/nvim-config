-- Load all keymap modules
-- This file replaces the monolithic keymapsPlugin.lua (3169 lines split into organized modules)

require("cybercat.core.keymaps-plugin.navigation")  -- Scrolling, search, diagnostics
require("cybercat.core.keymaps-plugin.files")       -- File permissions, bash execution
require("cybercat.core.keymaps-plugin.images")      -- Image pasting, renaming, deletion
require("cybercat.core.keymaps-plugin.imgur")       -- Imgur uploading
require("cybercat.core.keymaps-plugin.markdown")    -- Markdown formatting, tasks, text manipulation
require("cybercat.core.keymaps-plugin.spelling")    -- Spell checking keymaps
require("cybercat.core.keymaps-plugin.headings")    -- Markdown heading navigation
