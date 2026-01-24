require("cybercat.core.keymaps-core") -- Core keymaps (leader, save/quit, LSP imports, window mgmt, plugins, git)
require("cybercat.core.options")
-- require("cybercat.core.options2")
require("cybercat.core.filetype")
require("cybercat.core.lowPower10s")
-- require("cybercat.cybercat-app.init")
require("cybercat.core.highlights")

require("cybercat.core.keymaps-plugin") -- Loads: navigation, files, images, imgur, markdown, spelling, headings

require("cybercat.core.command")
require("cybercat.core.autocmds")

-- Auto-start Claude socket for IDE integration
require("cybercat.core.claude-socket").setup()
