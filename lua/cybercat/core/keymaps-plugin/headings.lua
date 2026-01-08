-- Markdown heading navigation using treesitter
local keymap = vim.keymap

local function get_markdown_headings()
	local cursor_line = vim.fn.line(".")
	local parser = vim.treesitter.get_parser(0, "markdown")
	if not parser then
		vim.notify("Markdown parser not available", vim.log.levels.ERROR)
		return nil, nil, nil, nil, nil, nil
	end
	local tree = parser:parse()[1]
	local query = vim.treesitter.query.parse(
		"markdown",
		[[
    (atx_heading (atx_h1_marker) @h1)
    (atx_heading (atx_h2_marker) @h2)
    (atx_heading (atx_h3_marker) @h3)
    (atx_heading (atx_h4_marker) @h4)
    (atx_heading (atx_h5_marker) @h5)
    (atx_heading (atx_h6_marker) @h6)
  ]]
	)
	-- Collect and sort all headings
	local headings = {}
	for id, node in query:iter_captures(tree:root(), 0) do
		local start_line = node:start() + 1 -- Convert to 1-based
		table.insert(headings, { line = start_line, level = id })
	end
	table.sort(headings, function(a, b)
		return a.line < b.line
	end)
	-- Find current heading and track its index
	local current_heading, current_idx, next_heading, next_same_heading
	for idx, h in ipairs(headings) do
		if h.line <= cursor_line then
			current_heading = h
			current_idx = idx
		elseif not next_heading then
			next_heading = h -- First heading after cursor
		end
	end
	-- Find next same-level heading if current exists
	if current_heading then
		-- Look for next same-level after current index
		for i = current_idx + 1, #headings do
			local h = headings[i]
			if h.level == current_heading.level then
				next_same_heading = h
				break
			end
		end
	end
	-- Return all values (nil if not found)
	return current_heading and current_heading.line or nil,
		current_heading and current_heading.level or nil,
		next_heading and next_heading.line or nil,
		next_heading and next_heading.level or nil,
		next_same_heading and next_same_heading.line or nil,
		next_same_heading and next_same_heading.level or nil
end

-- Print details of current markdown heading, next heading and next same level heading
vim.keymap.set("n", "<leader>mT", function()
	local cl, clvl, nl, nlvl, nsl, nslvl = get_markdown_headings()
	local message_parts = {}
	if cl then
		table.insert(message_parts, string.format("Current: H%d (line %d)", clvl, cl))
	else
		table.insert(message_parts, "Not in a section")
	end
	if nl then
		table.insert(message_parts, string.format("Next: H%d (line %d)", nlvl, nl))
	end
	if nsl then
		table.insert(message_parts, string.format("Next H%d: line %d", nslvl, nsl))
	end
	vim.notify(table.concat(message_parts, " | "), vim.log.levels.INFO)
end, { desc = "Show current, next, and same-level Markdown headings" })

-- -- Create next heading similar to the way its done in emacs lamw26wmal
-- -- When inside tmux
-- -- C-CR does not work because Neovim recognizes both CR and C-CR as the same "\r",
-- -- you can see this with:
-- -- :lua print(vim.inspect(vim.fn.getcharstr()))
-- --
-- -- If I run this outside tmux, for C-CR, in Ghostty I get
-- -- "<80><fc>\4\r"
-- -- So to fix this, I'm sending the keys in my tmux.conf file
vim.keymap.set({ "n", "i" }, "<C-CR>", function()
	-- Capture all needed return values
	local _, level, next_line, next_level, next_same_line = get_markdown_headings()
	if not level then
		vim.notify("No heading context found", vim.log.levels.WARN)
		return
	end
	local heading_prefix = string.rep("#", level) .. " "
	local insert_line = next_same_line and next_same_line or vim.fn.line("$") + 1
	-- If there’s a higher-level heading coming next, insert above it
	if next_line and next_level and (next_level < level) then
		insert_line = next_line
	end
	-- Insert heading line and an empty line after it
	vim.api.nvim_buf_set_lines(0, insert_line - 1, insert_line - 1, false, { heading_prefix, "" })
	-- Move cursor to the end of heading marker
	vim.api.nvim_win_set_cursor(0, { insert_line, #heading_prefix })
	-- Enter insert mode and type a space
	vim.api.nvim_feedkeys("i ", "n", false)
end, { desc = "[P]Insert heading emacs style" })

-- -- When inside tmux
-- -- C-CR does not work because Neovim recognizes both CR and C-CR as the same "\r",
-- -- you can see this with:
-- -- :lua print(vim.inspect(vim.fn.getcharstr()))
-- --
-- -- If I run this outside tmux, for C-CR, in Ghostty I get
-- -- "<80><fc>\4\r"
-- -- So to fix this, I'm sending the keys in my tmux.conf file
-- vim.keymap.set({ "n", "i" }, "<C-CR>", function()
--   vim.notify("Ctrl+Enter detected", vim.log.levels.INFO)
-- end, { desc = "Ctrl+Enter CSIu mapping" })

-------------------------------------------------------------------------------
--                           Folding section
-------------------------------------------------------------------------------

-- Checks each line to see if it matches a markdown heading (#, ##, etc.):
-- It’s called implicitly by Neovim’s folding engine by vim.opt_local.foldexpr
function _G.markdown_foldexpr()
	local lnum = vim.v.lnum
	local line = vim.fn.getline(lnum)
	local heading = line:match("^(#+)%s")
	if heading then
		local level = #heading
		if level == 1 then
			-- Special handling for H1
			if lnum == 1 then
				return ">1"
			else
				local frontmatter_end = vim.b.frontmatter_end
				if frontmatter_end and (lnum == frontmatter_end + 1) then
					return ">1"
				end
			end
		elseif level >= 2 and level <= 6 then
			-- Regular handling for H2-H6
			return ">" .. level
		end
	end
	return "="
end

local function set_markdown_folding()
	vim.opt_local.foldmethod = "expr"
	vim.opt_local.foldexpr = "v:lua.markdown_foldexpr()"
	vim.opt_local.foldlevel = 99

	-- Detect frontmatter closing line
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local found_first = false
	local frontmatter_end = nil
	for i, line in ipairs(lines) do
		if line == "---" then
			if not found_first then
				found_first = true
			else
				frontmatter_end = i
				break
			end
		end
	end
	vim.b.frontmatter_end = frontmatter_end
end

-- Use autocommand to apply only to markdown files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = set_markdown_folding,
})

-- Function to fold all headings of a specific level
local function fold_headings_of_level(level)
	-- Move to the top of the file without adding to jumplist
	vim.cmd("keepjumps normal! gg")
	-- Get the total number of lines
	local total_lines = vim.fn.line("$")
	for line = 1, total_lines do
		-- Get the content of the current line
		local line_content = vim.fn.getline(line)
		-- "^" -> Ensures the match is at the start of the line
		-- string.rep("#", level) -> Creates a string with 'level' number of "#" characters
		-- "%s" -> Matches any whitespace character after the "#" characters
		-- So this will match `## `, `### `, `#### ` for example, which are markdown headings
		if line_content:match("^" .. string.rep("#", level) .. "%s") then
			-- Move the cursor to the current line without adding to jumplist
			vim.cmd(string.format("keepjumps call cursor(%d, 1)", line))
			-- Check if the current line has a fold level > 0
			local current_foldlevel = vim.fn.foldlevel(line)
			if current_foldlevel > 0 then
				-- Fold the heading if it matches the level
				if vim.fn.foldclosed(line) == -1 then
					vim.cmd("normal! za")
				end
				-- else
				--   vim.notify("No fold at line " .. line, vim.log.levels.WARN)
			end
		end
	end
end

local function fold_markdown_headings(levels)
	-- I save the view to know where to jump back after folding
	local saved_view = vim.fn.winsaveview()
	for _, level in ipairs(levels) do
		fold_headings_of_level(level)
	end
	vim.cmd("nohlsearch")
	-- Restore the view to jump to where I was
	vim.fn.winrestview(saved_view)
end

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Keymap for folding markdown headings of level 1 or above
vim.keymap.set("n", "zj", function()
	-- "Update" saves only if the buffer has been modified since the last save
	vim.cmd("silent update")
	-- vim.keymap.set("n", "<leader>mfj", function()
	-- Reloads the file to refresh folds, otheriise you have to re-open neovim
	vim.cmd("edit!")
	-- Unfold everything first or I had issues
	vim.cmd("normal! zR")
	fold_markdown_headings({ 6, 5, 4, 3, 2, 1 })
	vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold all headings level 1 or above" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Keymap for folding markdown headings of level 2 or above
-- I know, it reads like "madafaka" but "k" for me means "2"
vim.keymap.set("n", "zk", function()
	-- "Update" saves only if the buffer has been modified since the last save
	vim.cmd("silent update")
	-- vim.keymap.set("n", "<leader>mfk", function()
	-- Reloads the file to refresh folds, otherwise you have to re-open neovim
	vim.cmd("edit!")
	-- Unfold everything first or I had issues
	vim.cmd("normal! zR")
	fold_markdown_headings({ 6, 5, 4, 3, 2 })
	vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold all headings level 2 or above" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Keymap for folding markdown headings of level 3 or above
vim.keymap.set("n", "zl", function()
	-- "Update" saves only if the buffer has been modified since the last save
	vim.cmd("silent update")
	-- vim.keymap.set("n", "<leader>mfl", function()
	-- Reloads the file to refresh folds, otherwise you have to re-open neovim
	vim.cmd("edit!")
	-- Unfold everything first or I had issues
	vim.cmd("normal! zR")
	fold_markdown_headings({ 6, 5, 4, 3 })
	vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold all headings level 3 or above" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Keymap for folding markdown headings of level 4 or above
vim.keymap.set("n", "z;", function()
	-- "Update" saves only if the buffer has been modified since the last save
	vim.cmd("silent update")
	-- vim.keymap.set("n", "<leader>mf;", function()
	-- Reloads the file to refresh folds, otherwise you have to re-open neovim
	vim.cmd("edit!")
	-- Unfold everything first or I had issues
	vim.cmd("normal! zR")
	fold_markdown_headings({ 6, 5, 4 })
	vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold all headings level 4 or above" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Use <CR> to fold when in normal mode
-- To see help about folds use `:help fold`
vim.keymap.set("n", "<CR>", function()
	-- Get the current line number
	local line = vim.fn.line(".")
	-- Get the fold level of the current line
	local foldlevel = vim.fn.foldlevel(line)
	if foldlevel == 0 then
		vim.notify("No fold found", vim.log.levels.INFO)
	else
		vim.cmd("normal! za")
		vim.cmd("normal! zz") -- center the cursor line on screen
	end
end, { desc = "[P]Toggle fold" })

-- HACK: Fold markdown headings in Neovim with a keymap
-- https://youtu.be/EYczZLNEnIY
--
-- Keymap for unfolding markdown headings of level 2 or above
-- Changed all the markdown folding and unfolding keymaps from <leader>mfj to
-- zj, zk, zl, z; and zu respectively lamw25wmal
vim.keymap.set("n", "zu", function()
	-- "Update" saves only if the buffer has been modified since the last save
	vim.cmd("silent update")
	-- vim.keymap.set("n", "<leader>mfu", function()
	-- Reloads the file to reflect the changes
	vim.cmd("edit!")
	vim.cmd("normal! zR") -- Unfold all headings
	vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Unfold all headings level 2 or above" })

--
-- gk jummps to the markdown heading above and then folds it
-- zi by default toggles folding, but I don't need it lamw25wmal
vim.keymap.set("n", "zi", function()
	-- "Update" saves only if the buffer has been modified since the last save
	vim.cmd("silent update")
	-- Difference between normal and normal!
	-- - `normal` executes the command and respects any mappings that might be defined.
	-- - `normal!` executes the command in a "raw" mode, ignoring any mappings.
	vim.cmd("normal gk")
	-- This is to fold the line under the cursor
	vim.cmd("normal! za")
	vim.cmd("normal! zz") -- center the cursor line on screen
end, { desc = "[P]Fold the heading cursor currently on" })

-------------------------------------------------------------------------------
--                         End Folding section
-------------------------------------------------------------------------------

-- Detect todos and toggle between ":" and ";", or show a message if not found
-- This is to "mark them as done"
-- vim.keymap.set("n", "<leader>td", function()
-- 	-- Get the current line
-- 	local current_line = vim.fn.getline(".")
-- 	-- Get the current line number
-- 	local line_number = vim.fn.line(".")
-- 	if string.find(current_line, "TODO:") then
-- 		-- Replace the first occurrence of ":" with ";"
-- 		local new_line = current_line:gsub("TODO:", "TODO;")
-- 		-- Set the modified line
-- 		vim.fn.setline(line_number, new_line)
-- 	elseif string.find(current_line, "TODO;") then
-- 		-- Replace the first occurrence of ";" with ":"
-- 		local new_line = current_line:gsub("TODO;", "TODO:")
-- 		-- Set the modified line
-- 		vim.fn.setline(line_number, new_line)
-- 	else
-- 		vim.cmd("echo 'todo item not detected'")
-- 	end
-- end, { desc = "[P]TODO toggle item done or not" })

--
-- Generate/update a Markdown TOC
-- To generate the TOC I use the markdown-toc plugin
-- https://github.com/jonschlinkert/markdown-toc
-- And the markdown-toc plugin installed as a LazyExtra
-- Function to update the Markdown TOC with customizable headings
local function update_markdown_toc(heading2, heading3)
	local path = vim.fn.expand("%") -- Expands the current file name to a full path
	local bufnr = 0 -- The current buffer number, 0 references the current active buffer
	-- Save the current view
	-- If I don't do this, my folds are lost when I run this keymap
	vim.cmd("mkview")
	-- Retrieves all lines from the current buffer
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local toc_exists = false -- Flag to check if TOC marker exists
	local frontmatter_end = 0 -- To store the end line number of frontmatter
	-- Check for frontmatter and TOC marker
	for i, line in ipairs(lines) do
		if i == 1 and line:match("^---$") then
			-- Frontmatter start detected, now find the end
			for j = i + 1, #lines do
				if lines[j]:match("^---$") then
					frontmatter_end = j
					break
				end
			end
		end
		-- Checks for the TOC marker
		if line:match("^%s*<!%-%-%s*toc%s*%-%->%s*$") then
			toc_exists = true
			break
		end
	end
	-- Inserts H2 and H3 headings and <!-- toc --> at the appropriate position
	if not toc_exists then
		local insertion_line = 1 -- Default insertion point after first line
		if frontmatter_end > 0 then
			-- Find H1 after frontmatter
			for i = frontmatter_end + 1, #lines do
				if lines[i]:match("^#%s+") then
					insertion_line = i + 1
					break
				end
			end
		else
			-- Find H1 from the beginning
			for i, line in ipairs(lines) do
				if line:match("^#%s+") then
					insertion_line = i + 1
					break
				end
			end
		end
		-- Insert the specified headings and <!-- toc --> without blank lines
		-- Insert the TOC inside a H2 and H3 heading right below the main H1 at the top lamw25wmal
		vim.api.nvim_buf_set_lines(bufnr, insertion_line, insertion_line, false, { heading2, heading3, "<!-- toc -->" })
	end
	-- Silently save the file, in case TOC is being created for the first time
	vim.cmd("silent write")
	-- Silently run markdown-toc to update the TOC without displaying command output
	-- vim.fn.system("markdown-toc -i " .. path)
	-- I want my bulletpoints to be created only as "-" so passing that option as
	-- an argument according to the docs
	-- https://github.com/jonschlinkert/markdown-toc?tab=readme-ov-file#optionsbullets
	vim.fn.system('markdown-toc --bullets "-" -i ' .. path)
	vim.cmd("edit!") -- Reloads the file to reflect the changes made by markdown-toc
	vim.cmd("silent write") -- Silently save the file
	vim.notify("TOC updated and file saved", vim.log.levels.INFO)
	-- -- In case a cleanup is needed, leaving this old code here as a reference
	-- -- I used this code before I implemented the frontmatter check
	-- -- Moves the cursor to the top of the file
	-- vim.api.nvim_win_set_cursor(bufnr, { 1, 0 })
	-- -- Deletes leading blank lines from the top of the file
	-- while true do
	--   -- Retrieves the first line of the buffer
	--   local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
	--   -- Checks if the line is empty
	--   if line == "" then
	--     -- Deletes the line if it's empty
	--     vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, {})
	--   else
	--     -- Breaks the loop if the line is not empty, indicating content or TOC marker
	--     break
	--   end
	-- end
	-- Restore the saved view (including folds)
	vim.cmd("loadview")
end

-- HACK: Create table of contents in neovim with markdown-toc
-- https://youtu.be/BVyrXsZ_ViA
--
-- Keymap for English TOC
-- keymap.set("n", "<leader>mtt", function()
-- 	update_markdown_toc("## Contents", "### Table of contents")
-- end, { desc = "[P]Insert/update Markdown TOC (English)" })

-- HACK: Create table of contents in neovim with markdown-toc
-- https://youtu.be/BVyrXsZ_ViA
--
-- Keymap for Spanish TOC lamw25wmal
-- keymap.set("n", "<leader>mts", function()
-- 	update_markdown_toc("## Contenido", "### Tabla de contenido")
-- end, { desc = "[P]Insert/update Markdown TOC (Spanish)" })

-- Save the cursor position globally to access it across different mappings
_G.saved_positions = {}

-- Mapping to jump to the first line of the TOC
vim.keymap.set("n", "<leader>mm", function()
	-- Save the current cursor position
	_G.saved_positions["toc_return"] = vim.api.nvim_win_get_cursor(0)
	-- Perform a silent search for the <!-- toc --> marker and move the cursor two lines below it
	vim.cmd("silent! /<!-- toc -->\\n\\n\\zs.*")
	-- Clear the search highlight without showing the "search hit BOTTOM, continuing at TOP" message
	vim.cmd("nohlsearch")
	-- Retrieve the current cursor position (after moving to the TOC)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local row = cursor_pos[1]
	-- local col = cursor_pos[2]
	-- Move the cursor to column 15 (starts counting at 0)
	-- I like just going down on the TOC and press gd to go to a section
	vim.api.nvim_win_set_cursor(0, { row, 14 })
end, { desc = "[P]Jump to the first line of the TOC" })

-- Mapping to return to the previously saved cursor position
vim.keymap.set("n", "<leader>mn", function()
	local pos = _G.saved_positions["toc_return"]
	if pos then
		vim.api.nvim_win_set_cursor(0, pos)
	end
end, { desc = "[P]Return to position before jumping" })

-- -- Search UP for a markdown header
-- -- If you have comments inside a codeblock, they can start with `# ` but make
-- -- sure that the line either below or above of the comment is not empty
-- -- Headings are considered the ones that have both an empty line above and also below
-- -- My markdown headings are autoformatted, so I always make sure about that
-- vim.keymap.set("n", "gk", function()
--   local foundHeader = false
--   -- Function to check if the given line number is blank
--   local function isBlankLine(lineNum)
--     return vim.fn.getline(lineNum):match("^%s*$") ~= nil
--   end
--   -- Function to search up for a markdown header
--   local function searchBackwardForHeader()
--     vim.cmd("silent! ?^\\s*#\\+\\s.*$")
--     local currentLineNum = vim.fn.line(".")
--     local aboveIsBlank = isBlankLine(currentLineNum - 1)
--     local belowIsBlank = isBlankLine(currentLineNum + 1)
--     -- Check if both above and below lines are blank, indicating a markdown header
--     if aboveIsBlank and belowIsBlank then
--       foundHeader = true
--     end
--     return currentLineNum
--   end
--   -- Initial search
--   local lastLineNum = searchBackwardForHeader()
--   -- Continue searching if the initial search did not find a header
--   while not foundHeader and vim.fn.line(".") > 1 do
--     local currentLineNum = searchBackwardForHeader()
--     -- Break the loop if the search doesn't change line number to prevent infinite loop
--     if currentLineNum == lastLineNum then
--       break
--     else
--       lastLineNum = currentLineNum
--     end
--   end
--   -- Clear search highlighting after operation
--   vim.cmd("nohlsearch")
-- end, { desc = "[P]Go to previous markdown header" })
--
-- -- Search DOWN for a markdown header
-- -- If you have comments inside a codeblock, they can start with `# ` but make
-- -- sure that the line either below or above of the comment is not empty
-- -- Headings are considered the ones that have both an empty line above and also below
-- -- My markdown headings are autoformatted, so I always make sure about that
-- vim.keymap.set("n", "gj", function()
--   local foundHeader = false
--   -- Function to check if the given line number is blank
--   local function isBlankLine(lineNum)
--     return vim.fn.getline(lineNum):match("^%s*$") ~= nil
--   end
--   -- Function to search down for a markdown header
--   local function searchForwardForHeader()
--     vim.cmd("silent! /^\\s*#\\+\\s.*$")
--     local currentLineNum = vim.fn.line(".")
--     local aboveIsBlank = isBlankLine(currentLineNum - 1)
--     local belowIsBlank = isBlankLine(currentLineNum + 1)
--     -- Check if both above and below lines are blank, indicating a markdown header
--     if aboveIsBlank and belowIsBlank then
--       foundHeader = true
--     end
--     return currentLineNum
--   end
--   -- Initial search
--   local lastLineNum = searchForwardForHeader()
--   -- Continue searching if the initial search did not find a header
--   while not foundHeader and vim.fn.line(".") < vim.fn.line("$") do
--     local currentLineNum = searchForwardForHeader()
--     -- Break the loop if the search doesn't change line number to prevent infinite loop
--     if currentLineNum == lastLineNum then
--       break
--     else
--       lastLineNum = currentLineNum
--     end
--   end
--   -- Clear search highlighting after operation
--   vim.cmd("nohlsearch")
-- end, { desc = "[P]Go to next markdown header" })

-- HACK: Jump between markdown headings in lazyvim
-- https://youtu.be/9S7Zli9hzTE
--
-- Search UP for a markdown header
-- Make sure to follow proper markdown convention, and you have a single H1
-- heading at the very top of the file
-- This will only search for H2 headings and above
-- hardtime.nvim causes issues with this key, you have to unrestrict it in the
-- plugin config
vim.keymap.set({ "n", "v" }, "gk", function()
	-- `?` - Start a search backwards from the current cursor position.
	-- `^` - Match the beginning of a line.
	-- `##` - Match 2 ## symbols
	-- `\\+` - Match one or more occurrences of prev element (#)
	-- `\\s` - Match exactly one whitespace character following the hashes
	-- `.*` - Match any characters (except newline) following the space
	-- `$` - Match extends to end of line
	vim.cmd("silent! ?^##\\+\\s.*$")
	-- Clear the search highlight
	vim.cmd("nohlsearch")
end, { desc = "[P]Go to previous markdown header" })

-- HACK: Jump between markdown headings in lazyvim
-- https://youtu.be/9S7Zli9hzTE
--
-- Search DOWN for a markdown header
-- Make sure to follow proper markdown convention, and you have a single H1
-- heading at the very top of the file
-- This will only search for H2 headings and above
-- hardtime.nvim causes issues with this key, you have to unrestrict it in the
-- plugin config
vim.keymap.set({ "n", "v" }, "gj", function()
	-- `/` - Start a search forwards from the current cursor position.
	-- `^` - Match the beginning of a line.
	-- `##` - Match 2 ## symbols
	-- `\\+` - Match one or more occurrences of prev element (#)
	-- `\\s` - Match exactly one whitespace character following the hashes
	-- `.*` - Match any characters (except newline) following the space
	-- `$` - Match extends to end of line
	vim.cmd("silent! /^##\\+\\s.*$")
	-- Clear the search highlight
	vim.cmd("nohlsearch")
end, { desc = "[P]Go to next markdown header" })

-- Function to delete the current file with confirmation
local function delete_current_file()
	local current_file = vim.fn.expand("%:p")
	if current_file and current_file ~= "" then
		-- Check if trash utility is installed
		if vim.fn.executable("trash") == 0 then
			vim.api.nvim_echo({
				{ "- Trash utility not installed. Make sure to install it first\n", "ErrorMsg" },
				{ "- In macOS run `brew install trash`\n", nil },
			}, false, {})
			return
		end
		-- Prompt for confirmation before deleting the file
		vim.ui.input({
			prompt = "Type 'del' to delete the file '" .. current_file .. "': ",
		}, function(input)
			if input == "del" then
				-- Delete the file using trash app
				local success, _ = pcall(function()
					vim.fn.system({ "trash", vim.fn.fnameescape(current_file) })
				end)
				if success then
					vim.api.nvim_echo({
						{ "File deleted from disk:\n", "Normal" },
						{ current_file, "Normal" },
					}, false, {})
					-- Close the buffer after deleting the file
					vim.cmd("bd!")
				else
					vim.api.nvim_echo({
						{ "Failed to delete file:\n", "ErrorMsg" },
						{ current_file, "ErrorMsg" },
					}, false, {})
				end
			else
				vim.api.nvim_echo({
					{ "File deletion canceled.", "Normal" },
				}, false, {})
			end
		end)
	else
		vim.api.nvim_echo({
			{ "No file to delete", "WarningMsg" },
		}, false, {})
	end
end

-- Keymap to delete the current file
vim.keymap.set("n", "<leader>fD", function()
	delete_current_file()
end, { desc = "[P]Delete current file" })

-- These create the a markdown heading based on the level specified, and also
-- dynamically add the date below in the [[2024-03-01-Friday]] format
local function insert_heading_and_date(level)
	local date = os.date("%Y-%m-%d-%A")
	local heading = string.rep("#", level) .. " " -- Generate heading based on the level
	local dateLine = "[[" .. date .. "]]" -- Formatted date line
	local row, _ = unpack(vim.api.nvim_win_get_cursor(0)) -- Get the current row number
	-- Insert both lines: heading and dateLine
	vim.api.nvim_buf_set_lines(0, row, row, false, { heading, dateLine })
	-- Move the cursor to the end of the heading
	vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
	-- Enter insert mode at the end of the current line
	vim.cmd("startinsert!")
	return dateLine
	-- vim.api.nvim_win_set_cursor(0, { row, #heading })
end

-- parse date line and generate file path components for the daily note
local function parse_date_line(date_line)
	local home = os.getenv("HOME")
	local year, month, day, weekday = date_line:match("%[%[(%d+)%-(%d+)%-(%d+)%-(%w+)%]%]")
	if not (year and month and day and weekday) then
		print("No valid date found in the line")
		return nil
	end
	local month_abbr = os.date("%b", os.time({ year = year, month = month, day = day }))
	-- .~/dotfiles/cybercat/.config/cybercat/notes/
	local note_dir = string.format("%s/.config/cybercat/notes//%s/%s-%s", home, year, month, month_abbr)
	local note_name = string.format("%s-%s-%s-%s.md", year, month, day, weekday)
	return note_dir, note_name
end

-- get the full path of the daily note
local function get_daily_note_path(date_line)
	local note_dir, note_name = parse_date_line(date_line)
	if not note_dir or not note_name then
		return nil
	end
	return note_dir .. "/" .. note_name
end

-- Updated create_daily_note function using helper functions
-- Create or find a daily note based on a date line format and open it in Neovim
-- This is used in obsidian markdown files that have the "Link to non-existent
-- document" warning
local function create_daily_note(date_line)
	local full_path = get_daily_note_path(date_line)
	if not full_path then
		return
	end
	local note_dir = full_path:match("(.*/)") -- Extract directory path from full path
	-- Ensure the directory exists
	vim.fn.mkdir(note_dir, "p")
	-- Check if the file exists and create it if it doesn't
	if vim.fn.filereadable(full_path) == 0 then
		local file = io.open(full_path, "w")
		if file then
			file:write(
				"# Contents\n\n<!-- toc -->\n\n- [Daily note](#daily-note)\n\n<!-- tocstop -->\n\n## Daily note\n"
			)
			file:close()
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))
			vim.cmd("bd!")
			vim.api.nvim_echo({
				{ "CREATED DAILY NOTE\n", "WarningMsg" },
				{ full_path, "WarningMsg" },
			}, false, {})
		else
			print("Failed to create file: " .. full_path)
		end
	else
		print("Daily note already exists: " .. full_path)
	end
end

-- Function to switch to the daily note or create it if it does not exist
local function switch_to_daily_note(date_line)
	local full_path = get_daily_note_path(date_line)
	if not full_path then
		return
	end
	create_daily_note(date_line)
	vim.cmd("edit " .. vim.fn.fnameescape(full_path))
end

-- HACK: Open your daily note in Neovim with a single keymap
-- https://youtu.be/W3hgsMoUcqo
--
-- Keymap to switch to the daily note or create it if it does not exist
vim.keymap.set("n", "<leader>fd", function()
	local current_line = vim.api.nvim_get_current_line()
	local date_line = current_line:match("%[%[%d+%-%d+%-%d+%-%w+%]%]") or ("[[" .. os.date("%Y-%m-%d-%A") .. "]]")
	switch_to_daily_note(date_line)
end, { desc = "[P]Go to or create daily note" })

-- These create the the markdown heading
-- H1
vim.keymap.set("n", "<leader>jj", function()
	local date_line = insert_heading_and_date(1)
	-- If you just want to add the heading, comment the line below
	create_daily_note(date_line)
end, { desc = "[P]H1 heading and date" })

-- H2
vim.keymap.set("n", "<leader>kk", function()
	local date_line = insert_heading_and_date(2)
	-- If you just want to add the heading, comment the line below
	create_daily_note(date_line)
end, { desc = "[P]H2 heading and date" })

-- H3
vim.keymap.set("n", "<leader>ll", function()
	local date_line = insert_heading_and_date(3)
	-- If you just want to add the heading, comment the line below
	create_daily_note(date_line)
end, { desc = "[P]H3 heading and date" })

-- H4
vim.keymap.set("n", "<leader>;;", function()
	local date_line = insert_heading_and_date(4)
	-- If you just want to add the heading, comment the line below
	create_daily_note(date_line)
end, { desc = "[P]H4 heading and date" })

-- H5
vim.keymap.set("n", "<leader>uu", function()
	local date_line = insert_heading_and_date(5)
	-- If you just want to add the heading, comment the line below
	create_daily_note(date_line)
end, { desc = "[P]H5 heading and date" })

-- H6
vim.keymap.set("n", "<leader>ii", function()
	local date_line = insert_heading_and_date(6)
	-- If you just want to add the heading, comment the line below
	create_daily_note(date_line)
end, { desc = "[P]H6 heading and date" })

-- Create or find a daily note
vim.keymap.set("n", "<leader>fC", function()
	-- Use the current line for date extraction
	local current_line = vim.api.nvim_get_current_line()
	create_daily_note(current_line)
end, { desc = "[P]Create daily note" })

-- Extract the Y-M-D parts from the current filename
local function current_file_date()
	local fname = vim.fn.expand("%:t")
	local y, m, d = fname:match("^(%d+)%-(%d+)%-(%d+)%-%w+%.md$")
	return y, m, d
end

-- Create N consecutive daily notes, starting tomorrow
local function create_next_n_days(n)
	local y, m, d = current_file_date()
	if not (y and m and d) then
		vim.api.nvim_echo({ { "Current file is not a valid daily note filename", "ErrorMsg" } }, false, {})
		return
	end
	local base_ts = os.time({ year = y, month = m, day = d })
	for i = 1, n do
		local t = os.date("*t", base_ts + 86400 * i)
		local link = string.format(
			"[[%04d-%02d-%02d-%s]]",
			t.year,
			t.month,
			t.day,
			os.date("%A", os.time({ year = t.year, month = t.month, day = t.day }))
		)
		create_daily_note(link)
	end
end

-- Create a daily note for the next day based on the current filename lamw26wmal
keymap.set("n", "<leader>fA", function()
	create_next_n_days(1)
end, { desc = "[P]Create next day's daily note from current file" })

-- Create the next 7 daily notes (one week) lamw26wmal
keymap.set("n", "<leader>fW", function()
	create_next_n_days(7)
end, { desc = "[P]Create next week's daily notes from current file" })

-- - I have several `.md` documents that do not follow markdown guidelines
-- - There are some old ones that have more than one H1 heading in them, so when I
--   open one of those old documents, I want to add one more `#` to each heading
--
--  This doesn't ask for confirmation and just increase all the headings
vim.keymap.set("n", "<leader>mhI", function()
	-- Save the current cursor position
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	-- I'm using [[ ]] to escape the special characters in a command
	vim.cmd([[:g/\(^$\n\s*#\+\s.*\n^$\)/ .+1 s/^#\+\s/#&/]])
	-- Restore the cursor position
	vim.api.nvim_win_set_cursor(0, cursor_pos)
	-- Clear search highlight
	vim.cmd("nohlsearch")
end, { desc = "[P]Increase headings without confirmation" })

vim.keymap.set("n", "<leader>mhD", function()
	-- Save the current cursor position
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	-- I'm using [[ ]] to escape the special characters in a command
	vim.cmd([[:g/^\s*#\{2,}\s/ s/^#\(#\+\s.*\)/\1/]])
	-- Restore the cursor position
	vim.api.nvim_win_set_cursor(0, cursor_pos)
	-- Clear search highlight
	vim.cmd("nohlsearch")
end, { desc = "[P]Decrease headings without confirmation" })

-- Increase markdown headings for text selected in visual mode
vim.keymap.set("v", "<leader>mhI", function()
	-- Save cursor position
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	-- Get visual selection bounds and ensure correct order
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	local buf = vim.api.nvim_get_current_buf()
	-- Process each line in the selection
	for lnum = start_line, end_line do
		local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
		if line and line:match("^##+%s") then -- Match headings level 2+
			local new_line = "#" .. line
			vim.api.nvim_buf_set_lines(buf, lnum - 1, lnum, false, { new_line })
		end
	end
	-- Restore cursor and clear highlights
	vim.api.nvim_win_set_cursor(0, cursor_pos)
	vim.cmd("nohlsearch")
end, { desc = "Increase headings in visual selection" })

-- Decrease markdown headings for text selected in visual mode
vim.keymap.set("v", "<leader>mhD", function()
	-- Save cursor position
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	-- Get visual selection bounds and ensure correct order
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	local buf = vim.api.nvim_get_current_buf()
	-- Process each line in the selection
	for lnum = start_line, end_line do
		local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
		if line and line:match("^##+%s") then -- Match headings level 2+
			-- Split into hashes and content, then remove one #
			local hashes, content = line:match("^(#+)(%s.+)$")
			if hashes and #hashes >= 2 then
				local new_hashes = hashes:sub(1, #hashes - 1)
				local new_line = new_hashes .. content
				vim.api.nvim_buf_set_lines(buf, lnum - 1, lnum, false, { new_line })
			end
		end
	end
	-- Restore cursor and clear highlights
	vim.api.nvim_win_set_cursor(0, cursor_pos)
	vim.cmd("nohlsearch")
end, { desc = "Decrease headings in visual selection" })

-- -- This goes 1 heading at a time and asks for **confirmation**
-- -- - keep pressing `n` to NOT increase, but you can see it detects headings
-- --  - `y` (yes): Replace this instance and continue to the next match.
-- --  - `n` (no): Do not replace this instance and continue to the next match.
-- --  - `a` (all): Replace all remaining instances without further prompting.
-- --  - `q` (quit): Quit without making any further replacements.
-- --  - `l` (last): Replace this instance and then quit
-- --  - `^E` (`Ctrl+E`): Scroll the text window down one line
-- --  - `^Y` (`Ctrl+Y`): Scroll the text window up one line
-- vim.keymap.set("n", "<leader>mhi", function()
--   -- Save the current cursor position
--   local cursor_pos = vim.api.nvim_win_get_cursor(0)
--   -- I'm using [[ ]] to escape the special characters in a command
--   vim.cmd([[:g/\(^$\n\s*#\+\s.*\n^$\)/ .+1 s/^#\+\s/#&/c]])
--   -- Restore the cursor position
--   vim.api.nvim_win_set_cursor(0, cursor_pos)
--   -- Clear search highlight
--   vim.cmd("nohlsearch")
-- end, { desc = "[P]Increase headings with confirmation" })

-- -- These are similar, but instead of adding an # they remove it
-- vim.keymap.set("n", "<leader>mhd", function()
--   -- Save the current cursor position
--   local cursor_pos = vim.api.nvim_win_get_cursor(0)
--   -- I'm using [[ ]] to escape the special characters in a command
--   vim.cmd([[:g/^\s*#\{2,}\s/ s/^#\(#\+\s.*\)/\1/c]])
--   -- Restore the cursor position
--   vim.api.nvim_win_set_cursor(0, cursor_pos)
--   -- Clear search highlight
--   vim.cmd("nohlsearch")
-- end, { desc = "[P]Decrease headings with confirmation" })

-- -- NOTE: Ignore this, it works out of the box, see
-- -- https://www.reddit.com/r/neovim/comments/1jozord/comment/mkvmp7s/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
-- -- To open markdown links, the cursor usually has to be in this position for gx
-- -- to work [link text](https://test<cursor>site.com)
-- -- I want to open links if I run gx in the `link text` section too lamw26wmal
-- --
-- -- Switched this keymap to an autocmd as links in non markdown files were not
-- -- being called correctly
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "markdown",
--   callback = function()
--     vim.keymap.set("n", "gx", function()
--       local line = vim.fn.getline(".")
--       local cursor_col = vim.fn.col(".")
--       local pos = 1
--       while pos <= #line do
--         local open_bracket = line:find("%[", pos)
--         if not open_bracket then
--           break
--         end
--         local close_bracket = line:find("%]", open_bracket + 1)
--         if not close_bracket then
--           break
--         end
--         local open_paren = line:find("%(", close_bracket + 1)
--         if not open_paren then
--           break
--         end
--         local close_paren = line:find("%)", open_paren + 1)
--         if not close_paren then
--           break
--         end
--         if
--           (cursor_col >= open_bracket and cursor_col <= close_bracket)
--           or (cursor_col >= open_paren and cursor_col <= close_paren)
--         then
--           local url = line:sub(open_paren + 1, close_paren - 1)
--           vim.ui.open(url)
--           return
--         end
--         pos = close_paren + 1
--       end
--       -- fallback to default gx behavior
--       vim.cmd("normal! gx")
--     end, { buffer = true, desc = "[P]Better URL opener for markdown" })
--   end,
-- })

-- ############################################################################
--                       End of markdown section
-- ############################################################################

-- keymap.set("n", "<leader>mD", function()
-- 	vim.cmd("delmarks!")
-- 	print("All marks deleted.")
-- end, { desc = "[P]Delete all marks" })

-- Function to open current file in Finder or ForkLift
local function open_in_file_manager()
	local file_path = vim.fn.expand("%:p")
	if file_path ~= "" then
		-- -- Open in Finder or in ForkLift
		-- local command = "open -R " .. vim.fn.shellescape(file_path)
		local command = "open -a ForkLift " .. vim.fn.shellescape(file_path)
		vim.fn.system(command)
		print("Opened file in ForkLift: " .. file_path)
	else
		print("No file is currently open")
	end
end

-- vim.keymap.set({ "n", "v", "i" }, "<M-f>", open_in_file_manager, { desc = "[P]Open current file in file explorer" })
keymap.set("n", "<leader>fO", open_in_file_manager, { desc = "[P]Open current file in file explorer" })

-- Open current file in Neovide

-- Function to get the GitHub URL of the current file
-- local function get_github_url_of_current_file()
-- 	local file_path = vim.fn.expand("%:p")
-- 	if file_path == "" then
-- 		vim.notify("No file is currently open", vim.log.levels.WARN)
-- 		return nil
-- 	end
--
-- 	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
-- 	if not git_root or git_root == "" then
-- 		vim.notify("Could not determine the root directory for the GitHub repository", vim.log.levels.WARN)
-- 		return nil
-- 	end
--
-- 	local origin_url = vim.fn.systemlist("git config --get remote.origin.url")[1]
-- 	if not origin_url or origin_url == "" then
-- 		vim.notify("Could not determine the origin URL for the GitHub repository", vim.log.levels.WARN)
-- 		return nil
-- 	end
--
-- 	local branch_name = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]
-- 	if not branch_name or branch_name == "" then
-- 		vim.notify("Could not determine the current branch name", vim.log.levels.WARN)
-- 		return nil
-- 	end
--
-- 	local repo_url = origin_url:gsub("git@github.com[^:]*:", "https://github.com/"):gsub("%.git$", "")
-- 	local relative_path = file_path:sub(#git_root + 2)
-- 	return repo_url .. "/blob/" .. branch_name .. "/" .. relative_path
-- end

-- Open current file's GitHub repo link lamw25wmal
-- vim.keymap.set("n", "<leader>fG", function()
-- 	local github_url = get_github_url_of_current_file()
-- 	if github_url then
-- 		local command = "open " .. vim.fn.shellescape(github_url)
-- 		vim.fn.system(command)
-- 		print("Opened GitHub link: " .. github_url)
-- 	end
-- end, { desc = "[P]Open current file's GitHub repo link" })

-- Keymap to copy current file's GitHub URL to clipboard
-- vim.keymap.set({ "n", "v", "i" }, "<M-C>", function()
-- 	local github_url = get_github_url_of_current_file()
-- 	if github_url then
-- 		vim.fn.setreg("+", github_url)
-- 		vim.notify(github_url, vim.log.levels.INFO)
-- 		vim.notify("GitHub URL copied to clipboard", vim.log.levels.INFO)
-- 	end
-- end, { desc = "[P]Copy GitHub URL of file to clipboard" })

-- Function to copy file path to clipboard
local function copy_filepath_to_clipboard()
	local filePath = vim.fn.expand("%:~") -- Gets the file path relative to the home directory
	vim.fn.setreg("+", filePath) -- Copy the file path to the clipboard register
	vim.notify(filePath, vim.log.levels.INFO)
	vim.notify("Path copied to clipboard: ", vim.log.levels.INFO)
end
vim.keymap.set("n", "<leader>fp", copy_filepath_to_clipboard, { desc = "[P]Copy file path to clipboard" })
-- I couldn't use <M-p> because its used for previous reference
-- vim.keymap.set({ "n", "v", "i" }, "<M-c>", copy_filepath_to_clipboard, { desc = "[P]Copy file path to clipboard" })

-- Keymap to create a GitHub repository
-- It uses the github CLI, which in macOS is installed with:
-- brew install gh
-- keymap.set("n", "<leader>gC", function()
-- 	-- Check if GitHub CLI is installed
-- 	local gh_installed = vim.fn.system("command -v gh")
-- 	if gh_installed == "" then
-- 		print("GitHub CLI is not installed. Please install it using 'brew install gh'.")
-- 		return
-- 	end
-- 	-- Get the current working directory and extract the repository name
-- 	local cwd = vim.fn.getcwd()
-- 	local repo_name = vim.fn.fnamemodify(cwd, ":t")
-- 	if repo_name == "" then
-- 		print("Failed to extract repository name from the current directory.")
-- 		return
-- 	end
-- 	-- Display the message and ask for confirmation
-- 	vim.ui.select({ "yes", "no" }, {
-- 		prompt = 'The name of the repo will be: "' .. repo_name .. '". Continue?',
-- 		default = "no",
-- 	}, function(choice)
-- 		if choice ~= "yes" then
-- 			print("Operation canceled.")
-- 			return
-- 		end
-- 		-- Check if the repository already exists on GitHub
-- 		local check_repo_command =
-- 			string.format("gh repo view %s/%s", vim.fn.system("gh api user --jq '.login'"):gsub("%s+", ""), repo_name)
-- 		local check_repo_result = vim.fn.systemlist(check_repo_command)
-- 		if not string.find(table.concat(check_repo_result), "Could not resolve to a Repository") then
-- 			print("Repository '" .. repo_name .. "' already exists on GitHub.")
-- 			return
-- 		end
-- 		-- Prompt for repository type
-- 		vim.ui.select({ "private", "public" }, {
-- 			prompt = "Select the repository type:",
-- 			default = "private",
-- 		}, function(repo_type)
-- 			if not repo_type then
-- 				print("Operation canceled.")
-- 				return
-- 			end
-- 			-- Set the repository type flag
-- 			local repo_type_flag = repo_type == "private" and "--private" or "--public"
-- 			-- Initialize the git repository and create the GitHub repository
-- 			local init_command = string.format("cd %s && git init", vim.fn.shellescape(cwd))
-- 			vim.fn.system(init_command)
-- 			local create_command = string.format(
-- 				"cd %s && gh repo create %s %s --source=.",
-- 				vim.fn.shellescape(cwd),
-- 				repo_name,
-- 				repo_type_flag
-- 			)
-- 			local create_result = vim.fn.system(create_command)
-- 			-- Print the result of the repository creation command
-- 			if string.find(create_result, "https://github.com") then
-- 				print("Repository '" .. repo_name .. "' created successfully.")
-- 			else
-- 				print("Failed to create the repository: " .. create_result)
-- 			end
-- 		end)
-- 	end)
-- end, { desc = "[P]Create GitHub repository" })

-- Reload zsh configuration by sourcing ~/.zshrc in a separate shell
-- vim.keymap.set("n", "<leader>fz", function()
-- 	-- Define the command to source zshrc
-- 	local command = "source ~/.zshrc"
-- 	-- Execute the command in a new Zsh shell
-- 	local full_command = "zsh -c '" .. command .. "'"
-- 	-- Run the command and capture the output
-- 	local output = vim.fn.system(full_command)
-- 	-- Check the exit status of the command
-- 	local exit_code = vim.v.shell_error
-- 	if exit_code == 0 then
-- 		vim.api.nvim_echo({ { "Successfully sourced ~/.zshrc", "NormalMsg" } }, false, {})
-- 	else
-- 		vim.api.nvim_echo({
-- 			{ "Failed to source ~/.zshrc:", "ErrorMsg" },
-- 			{ output, "ErrorMsg" },
-- 		}, false, {})
-- 	end
-- end, { desc = "[P]source ~/.zshrc" })

-- Execute my 400-autoPushGithub.sh script
-- vim.keymap.set("n", "<leader>gP", function()
-- 	local script_path = "~/github/dotfiles-latest/scripts/macos/mac/400-autoPushGithub.sh --nowait"
-- 	-- Expand the home directory in the path
-- 	script_path = vim.fn.expand(script_path)
-- 	-- Execute the script and capture the output
-- 	local output = vim.fn.system(script_path)
-- 	-- Check the exit status
-- 	local exit_code = vim.v.shell_error
-- 	if exit_code == 0 then
-- 		vim.api.nvim_echo({ { "Git push successful", "NormalMsg" } }, false, {})
-- 	else
-- 		vim.api.nvim_echo({
-- 			{ "Git push failed:", "ErrorMsg" },
-- 			{ output, "ErrorMsg" },
-- 		}, false, {})
-- 	end
-- end, { desc = "[P] execute 400-autoPushGithub.sh" })
