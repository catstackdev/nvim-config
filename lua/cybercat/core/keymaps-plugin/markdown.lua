-- Markdown-specific keymaps and operations
local keymap = vim.keymap

-- ############################################################################
--                         Begin of markdown section
-- ############################################################################

-- Select text inside codeblocks lamw26wmal
-- Select everything between the opening ```<lang> and the closing ``` fences
-- vim.keymap.set("n", "vio", function()
-- 	-- Find opening fence above cursor
-- 	local cur = vim.fn.line(".")
-- 	local open = nil
-- 	for l = cur, 1, -1 do
-- 		if vim.fn.getline(l):match("^%s*```%S+") then
-- 			open = l
-- 			break
-- 		end
-- 	end
-- 	if not open then
-- 		print("No opening ```<lang> fence found")
-- 		return
-- 	end
-- 	-- Find closing fence below the opening one
-- 	local close = nil
-- 	for l = open + 1, vim.fn.line("$") do
-- 		if vim.fn.getline(l):match("^%s*```%s*$") then
-- 			close = l
-- 			break
-- 		end
-- 	end
-- 	if not close then
-- 		print("No closing ``` fence found")
-- 		return
-- 	end
-- 	if close - open <= 1 then
-- 		print("Code-block is empty")
-- 		return
-- 	end
-- 	-- Visual-select lines open+1 .. close-1
-- 	vim.cmd(("normal! %dGV%dG"):format(open + 1, close - 1))
-- end, { desc = "[P]Select inside fenced code-block" })

-- Keymap to auto-format and save all Markdown files in the CURRENT REPOSITORY,
-- lamw26wmal if the TOC is not updated, this will take care of it
vim.keymap.set("n", "<leader>mfA", function()
	-- Get the root directory of the git repository
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if not git_root or git_root == "" then
		print("Could not determine the root directory for the Git repository.")
		return
	end
	-- Find all Markdown files in the repository
	local find_command = string.format("find %s -type f -name '*.md'", vim.fn.shellescape(git_root))
	local handle = io.popen(find_command)
	if not handle then
		print("Failed to execute the find command.")
		return
	end
	local result = handle:read("*a")
	handle:close()
	if result == "" then
		print("No Markdown files found in the repository.")
		return
	end
	-- Format and save each Markdown file
	for file in result:gmatch("[^\r\n]+") do
		local bufnr = vim.fn.bufadd(file)
		vim.fn.bufload(bufnr)
		require("conform").format({ bufnr = bufnr })
		-- Save the buffer to write changes to disk
		vim.api.nvim_buf_call(bufnr, function()
			vim.cmd("write")
		end)
		print("Formatted and saved: " .. file)
	end
end, { desc = "[P]Format and save all Markdown files in the repo" })

local function process_embeds_in_buffer(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local embeds = {}
	local seen = {}
	local target_line = nil
	local current_section = nil
	local lines_to_remove = {}
	local protected_sections = {
		["YouTube video"] = true,
		["Other videos mentioned"] = true,
	}
	-- Collect embeds and find target section
	for i, line in ipairs(lines) do
		if line:match("^##%s+") then
			current_section = line:match("^##%s+(.-)%s*$")
		end
		if line:match("^## If you like my content, and want to support me") then
			target_line = i
		end
		if line:match("^{%% include embed/youtube.html id=") then
			if not protected_sections[current_section] then
				if not seen[line] then
					table.insert(embeds, line)
					seen[line] = true
				end
				table.insert(lines_to_remove, i)
			end
		end
	end
	if not target_line then
		return { error = "Target section 'If you like my content...' not found" }
	end
	-- Existing section handling
	local existing_section_start, existing_section_end = nil, nil
	for i = 1, #lines do
		if lines[i]:match("^## Other videos mentioned") then
			existing_section_start = i
			for j = i + 1, #lines do
				if lines[j]:match("^## ") then
					existing_section_end = j - 1
					break
				end
				existing_section_end = j
			end
			break
		end
	end
	-- Build new lines
	local new_lines = {}
	for i, line in ipairs(lines) do
		local in_removed = vim.tbl_contains(lines_to_remove, i)
		local in_existing_section = existing_section_start and i >= existing_section_start and i <= existing_section_end
		if not in_removed and not in_existing_section then
			table.insert(new_lines, line)
		end
	end
	-- Find new target position
	local new_target_pos = nil
	for i, line in ipairs(new_lines) do
		if line:match("^## If you like my content") then
			new_target_pos = i
			break
		end
	end
	if not new_target_pos then
		return { error = "Couldn't find target position after processing" }
	end
	-- Insert new section if embeds found
	if #embeds > 0 then
		local section_content = { "## Other videos mentioned", "" }
		for _, embed in ipairs(embeds) do
			table.insert(section_content, embed)
			table.insert(section_content, "")
		end
		table.insert(section_content, "")
		for i = #section_content, 1, -1 do
			table.insert(new_lines, new_target_pos, section_content[i])
		end
	end
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
	return {
		moved = #embeds,
		message = #embeds > 0 and ("Moved " .. #embeds .. " embeds to 'Other videos mentioned' section")
			or "No embeds to move",
	}
end

-- Move youtube embeds in my blogpost to their own section for the current
-- buffer lamw26wmal
-- http://youtube.com/post/Ugkx5K4nL8AtcH2Fjg6pyzQPamyqEugK-HNh?si=-pONtWziiB58yqmT
-- vim.keymap.set("n", "<leader>mfy", function()
-- 	local result = process_embeds_in_buffer(0)
-- 	if result.error then
-- 		print(result.error)
-- 	else
-- 		print(result.message)
-- 	end
-- end, { desc = "[P]Move YouTube embeds to dedicated section" })

-- Keymap youtube embeds for ALL the markdown files in the current repository
-- This will auto-format them, so don't worry about running and auto format for
-- all markdown files afterwards
-- vim.keymap.set("n", "<leader>mfY", function()
-- 	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
-- 	if not git_root or git_root == "" then
-- 		print("Could not determine Git repository root.")
-- 		return
-- 	end
-- 	local find_command = string.format("find %s -type f -name '*.md'", vim.fn.shellescape(git_root))
-- 	local handle = io.popen(find_command)
-- 	if not handle then
-- 		print("Failed to find Markdown files.")
-- 		return
-- 	end
-- 	local files = {}
-- 	for file in handle:lines() do
-- 		table.insert(files, file)
-- 	end
-- 	handle:close()
-- 	if #files == 0 then
-- 		print("No Markdown files found in repository.")
-- 		return
-- 	end
-- 	for _, file in ipairs(files) do
-- 		local bufnr = vim.fn.bufadd(file)
-- 		vim.fn.bufload(bufnr)
-- 		local result = process_embeds_in_buffer(bufnr)
-- 		vim.api.nvim_buf_call(bufnr, function()
-- 			vim.cmd("write")
-- 		end)
-- 		local status = result.error and ("Error: " .. result.error) or result.message
-- 		print(string.format("%s: %s", file, status))
-- 	end
-- end, { desc = "[P]Move YouTube embeds in all repo Markdown files" })

-- HACK: My complete Neovim markdown setup and workflow in 2024
-- https://youtu.be/c0cuvzK1SDo

-- Mappings for creating new groups that don't exist
-- When I press leader, I want to modify the name of the options shown
-- "m" is for "markdown" and "t" is for "todo"
-- https://github.com/folke/which-key.nvim?tab=readme-ov-file#%EF%B8%8F-mappings

-- Alternative solution proposed by @cashplease-s9m in my video
-- My complete Neovim markdown setup and workflow in 2025
-- https://youtu.be/1YEbKDlxfss
-- vim.keymap.set(
-- 	"v",
-- 	"<leader>mj",
-- 	":g/^\\s*$/d<CR>:nohlsearch<CR>",
-- 	{ desc = "[P]Delete newlines in selected text (join)" }
-- )

-- -- In visual mode, delete all newlines within selected text
-- -- I like keeping my bulletpoints one after the next, sometimes formatting gets
-- -- in the way and they mess up, so this allows me to select all of them and just
-- -- delete newlines in between lamw25wmal
-- vim.keymap.set("v", "<leader>mj", function()
--   -- Get the visual selection range
--   local start_row = vim.fn.line("v")
--   local end_row = vim.fn.line(".")
--   -- Ensure start_row is less than or equal to end_row
--   if start_row > end_row then
--     start_row, end_row = end_row, start_row
--   end
--   -- Loop through each line in the selection
--   local current_row = start_row
--   while current_row <= end_row do
--     local line = vim.api.nvim_buf_get_lines(0, current_row - 1, current_row, false)[1]
--     -- vim.notify("Checking line " .. current_row .. ": " .. (line or ""), vim.log.levels.INFO)
--     -- If the line is empty, delete it and adjust end_row
--     if line == "" then
--       vim.cmd(current_row .. "delete")
--       end_row = end_row - 1
--     else
--       current_row = current_row + 1
--     end
--   end
-- end, { desc = "[P]Delete newlines in selected text (join)" })

-- Toggle bullet point at the beginning of the current line in normal mode
-- If in a multiline paragraph, make sure the cursor is on the line at the top
-- "d" is for "dash" lamw25wmal
vim.keymap.set("n", "<leader>md", function()
	-- Get the current cursor position
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local current_buffer = vim.api.nvim_get_current_buf()
	local start_row = cursor_pos[1] - 1
	local col = cursor_pos[2]
	-- Get the current line
	local line = vim.api.nvim_buf_get_lines(current_buffer, start_row, start_row + 1, false)[1]
	-- Check if the line already starts with a bullet point
	if line:match("^%s*%-") then
		-- Remove the bullet point from the start of the line
		line = line:gsub("^%s*%-", "")
		vim.api.nvim_buf_set_lines(current_buffer, start_row, start_row + 1, false, { line })
		return
	end
	-- Search for newline to the left of the cursor position
	local left_text = line:sub(1, col)
	local bullet_start = left_text:reverse():find("\n")
	if bullet_start then
		bullet_start = col - bullet_start
	end
	-- Search for newline to the right of the cursor position and in following lines
	local right_text = line:sub(col + 1)
	local bullet_end = right_text:find("\n")
	local end_row = start_row
	while not bullet_end and end_row < vim.api.nvim_buf_line_count(current_buffer) - 1 do
		end_row = end_row + 1
		local next_line = vim.api.nvim_buf_get_lines(current_buffer, end_row, end_row + 1, false)[1]
		if next_line == "" then
			break
		end
		right_text = right_text .. "\n" .. next_line
		bullet_end = right_text:find("\n")
	end
	if bullet_end then
		bullet_end = col + bullet_end
	end
	-- Extract lines
	local text_lines = vim.api.nvim_buf_get_lines(current_buffer, start_row, end_row + 1, false)
	local text = table.concat(text_lines, "\n")
	-- Add bullet point at the start of the text
	local new_text = "- " .. text
	local new_lines = vim.split(new_text, "\n")
	-- Set new lines in buffer
	vim.api.nvim_buf_set_lines(current_buffer, start_row, end_row + 1, false, new_lines)
end, { desc = "[P]Toggle bullet point (dash)" })

-- HACK: Manage Markdown tasks in Neovim similar to Obsidian | Telescope to List Completed and Pending Tasks
-- https://youtu.be/59hvZl077hM
--
-- If there is no `untoggled` or `done` label on an item, mark it as done
-- and move it to the "## completed tasks" markdown heading in the same file, if
-- the heading does not exist, it will be created, if it exists, items will be
-- appended to it at the top lamw25wmal
--
-- If an item is moved to that heading, it will be added the `done` label
vim.keymap.set("n", "<M-x>", function()
	-- Customizable variables
	-- NOTE: Customize the completion label
	local label_done = "done:"
	-- NOTE: Customize the timestamp format
	local timestamp = os.date("%y%m%d-%H%M")
	-- local timestamp = os.date("%y%m%d")
	-- NOTE: Customize the heading and its level
	local tasks_heading = "## Completed tasks"
	-- Save the view to preserve folds
	vim.cmd("mkview")
	local api = vim.api
	-- Retrieve buffer & lines
	local buf = api.nvim_get_current_buf()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local start_line = cursor_pos[1] - 1
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local total_lines = #lines
	-- If cursor is beyond last line, do nothing
	if start_line >= total_lines then
		vim.cmd("loadview")
		return
	end
	------------------------------------------------------------------------------
	-- (A) Move upwards to find the bullet line (if user is somewhere in the chunk)
	------------------------------------------------------------------------------
	while start_line > 0 do
		local line_text = lines[start_line + 1]
		-- Stop if we find a blank line or a bullet line
		if line_text == "" or line_text:match("^%s*%-") then
			break
		end
		start_line = start_line - 1
	end
	-- Now we might be on a blank line or a bullet line
	if lines[start_line + 1] == "" and start_line < (total_lines - 1) then
		start_line = start_line + 1
	end
	------------------------------------------------------------------------------
	-- (B) Validate that it's actually a task bullet, i.e. '- [ ]' or '- [x]'
	------------------------------------------------------------------------------
	local bullet_line = lines[start_line + 1]
	if not bullet_line:match("^%s*%- %[[x ]%]") then
		-- Not a task bullet => show a message and return
		print("Not a task bullet: no action taken.")
		vim.cmd("loadview")
		return
	end
	------------------------------------------------------------------------------
	-- 1. Identify the chunk boundaries
	------------------------------------------------------------------------------
	local chunk_start = start_line
	local chunk_end = start_line
	while chunk_end + 1 < total_lines do
		local next_line = lines[chunk_end + 2]
		if next_line == "" or next_line:match("^%s*%-") then
			break
		end
		chunk_end = chunk_end + 1
	end
	-- Collect the chunk lines
	local chunk = {}
	for i = chunk_start, chunk_end do
		table.insert(chunk, lines[i + 1])
	end
	------------------------------------------------------------------------------
	-- 2. Check if chunk has [done: ...] or [untoggled], then transform them
	------------------------------------------------------------------------------
	local has_done_index = nil
	local has_untoggled_index = nil
	for i, line in ipairs(chunk) do
		-- Replace `[done: ...]` -> `` `done: ...` ``
		chunk[i] = line:gsub("%[done:([^%]]+)%]", "`" .. label_done .. "%1`")
		-- Replace `[untoggled]` -> `` `untoggled` ``
		chunk[i] = chunk[i]:gsub("%[untoggled%]", "`untoggled`")
		if chunk[i]:match("`" .. label_done .. ".-`") then
			has_done_index = i
			break
		end
	end
	if not has_done_index then
		for i, line in ipairs(chunk) do
			if line:match("`untoggled`") then
				has_untoggled_index = i
				break
			end
		end
	end
	------------------------------------------------------------------------------
	-- 3. Helpers to toggle bullet
	------------------------------------------------------------------------------
	-- Convert '- [ ]' to '- [x]'
	local function bulletToX(line)
		return line:gsub("^(%s*%- )%[%s*%]", "%1[x]")
	end
	-- Convert '- [x]' to '- [ ]'
	local function bulletToBlank(line)
		return line:gsub("^(%s*%- )%[x%]", "%1[ ]")
	end
	------------------------------------------------------------------------------
	-- 4. Insert or remove label *after* the bracket
	------------------------------------------------------------------------------
	local function insertLabelAfterBracket(line, label)
		local prefix = line:match("^(%s*%- %[[x ]%])")
		if not prefix then
			return line
		end
		local rest = line:sub(#prefix + 1)
		return prefix .. " " .. label .. rest
	end
	local function removeLabel(line)
		-- If there's a label (like `` `done: ...` `` or `` `untoggled` ``) right after
		-- '- [x]' or '- [ ]', remove it
		return line:gsub("^(%s*%- %[[x ]%])%s+`.-`", "%1")
	end
	------------------------------------------------------------------------------
	-- 5. Update the buffer with new chunk lines (in place)
	------------------------------------------------------------------------------
	local function updateBufferWithChunk(new_chunk)
		for idx = chunk_start, chunk_end do
			lines[idx + 1] = new_chunk[idx - chunk_start + 1]
		end
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end
	------------------------------------------------------------------------------
	-- 6. Main toggle logic
	------------------------------------------------------------------------------
	if has_done_index then
		chunk[has_done_index] = removeLabel(chunk[has_done_index]):gsub("`" .. label_done .. ".-`", "`untoggled`")
		chunk[1] = bulletToBlank(chunk[1])
		chunk[1] = removeLabel(chunk[1])
		chunk[1] = insertLabelAfterBracket(chunk[1], "`untoggled`")
		updateBufferWithChunk(chunk)
		vim.notify("Untoggled", vim.log.levels.INFO)
	elseif has_untoggled_index then
		chunk[has_untoggled_index] =
			removeLabel(chunk[has_untoggled_index]):gsub("`untoggled`", "`" .. label_done .. " " .. timestamp .. "`")
		chunk[1] = bulletToX(chunk[1])
		chunk[1] = removeLabel(chunk[1])
		chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. label_done .. " " .. timestamp .. "`")
		updateBufferWithChunk(chunk)
		vim.notify("Completed", vim.log.levels.INFO)
	else
		-- Save original window view before modifications
		local win = api.nvim_get_current_win()
		local view = api.nvim_win_call(win, function()
			return vim.fn.winsaveview()
		end)
		chunk[1] = bulletToX(chunk[1])
		chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. label_done .. " " .. timestamp .. "`")
		-- Remove chunk from the original lines
		for i = chunk_end, chunk_start, -1 do
			table.remove(lines, i + 1)
		end
		-- Append chunk under 'tasks_heading'
		local heading_index = nil
		for i, line in ipairs(lines) do
			if line:match("^" .. tasks_heading) then
				heading_index = i
				break
			end
		end
		if heading_index then
			for _, cLine in ipairs(chunk) do
				table.insert(lines, heading_index + 1, cLine)
				heading_index = heading_index + 1
			end
			-- Remove any blank line right after newly inserted chunk
			local after_last_item = heading_index + 1
			if lines[after_last_item] == "" then
				table.remove(lines, after_last_item)
			end
		else
			table.insert(lines, tasks_heading)
			for _, cLine in ipairs(chunk) do
				table.insert(lines, cLine)
			end
			local after_last_item = #lines + 1
			if lines[after_last_item] == "" then
				table.remove(lines, after_last_item)
			end
		end
		-- Update buffer content
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.notify("Completed", vim.log.levels.INFO)
		-- Restore window view to preserve scroll position
		api.nvim_win_call(win, function()
			vim.fn.winrestview(view)
		end)
	end
	-- Write changes and restore view to preserve folds
	-- "Update" saves only if the buffer has been modified since the last save
	vim.cmd("silent update")
	vim.cmd("loadview")
end, { desc = "[P]Toggle task and move it to 'done'" })

-- -- Toggle bullet point at the beginning of the current line in normal mode
-- vim.keymap.set("n", "<leader>ml", function()
--   -- Notify that the function is being executed
--   vim.notify("Executing bullet point toggle function", vim.log.levels.INFO)
--   -- Get the current cursor position
--   local cursor_pos = vim.api.nvim_win_get_cursor(0)
--   vim.notify("Cursor position: row " .. cursor_pos[1] .. ", col " .. cursor_pos[2], vim.log.levels.INFO)
--   local current_buffer = vim.api.nvim_get_current_buf()
--   local row = cursor_pos[1] - 1
--   -- Get the current line
--   local line = vim.api.nvim_buf_get_lines(current_buffer, row, row + 1, false)[1]
--   vim.notify("Current line: " .. line, vim.log.levels.INFO)
--   if line:match("^%s*%-") then
--     -- If the line already starts with a bullet point, remove it
--     vim.notify("Bullet point detected, removing it", vim.log.levels.INFO)
--     line = line:gsub("^%s*%-", "", 1)
--     vim.api.nvim_buf_set_lines(current_buffer, row, row + 1, false, { line })
--   else
--     -- Otherwise, delete the line, add a bullet point, and paste the text
--     vim.notify("No bullet point detected, adding it", vim.log.levels.INFO)
--     line = "- " .. line
--     vim.api.nvim_buf_set_lines(current_buffer, row, row + 1, false, { line })
--   end
-- end, { desc = "Toggle bullet point at the beginning of the current line" })



-- Remap 'gss' to 'gsa`' in visual mode
-- This surrounds with inline code, that I use a lot lamw25wmal
vim.keymap.set("v", "gss", function()
	-- Use nvim_replace_termcodes to handle special characters like backticks
	local keys = vim.api.nvim_replace_termcodes("gsa`", true, false, true)
	-- Feed the keys in visual mode ('x' for visual mode)
	vim.api.nvim_feedkeys(keys, "x", false)
	-- I tried these 3, but they didn't work, I assume because of the backtick character
	-- vim.cmd("normal! gsa`")
	-- vim.cmd([[normal! gsa`]])
	-- vim.cmd("normal! gsa\\`")
end, { desc = "[P] Surround selection with backticks (inline code)" })

-- This surrounds CURRENT WORD with inline code in NORMAL MODE lamw25wmal
vim.keymap.set("n", "gss", function()
	-- Use nvim_replace_termcodes to handle special characters like backticks
	local keys = vim.api.nvim_replace_termcodes("gsaiw`", true, false, true)
	-- Feed the keys in visual mode ('x' for visual mode)
	vim.api.nvim_feedkeys(keys, "x", false)
	-- I tried these 3, but they didn't work, I assume because of the backtick character
	-- vim.cmd("normal! gsa`")
	-- vim.cmd([[normal! gsa`]])
	-- vim.cmd("normal! gsa\\`")
end, { desc = "[P] Surround selection with backticks (inline code)" })

-- In visual mode, check if the selected text is already striked through and show a message if it is
-- If not, surround it
vim.keymap.set("v", "<leader>mx", function()
	-- Get the selected text range
	local start_row, start_col = unpack(vim.fn.getpos("'<"), 2, 3)
	local end_row, end_col = unpack(vim.fn.getpos("'>"), 2, 3)
	-- Get the selected lines
	local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
	local selected_text = table.concat(lines, "\n"):sub(start_col, #lines == 1 and end_col or -1)
	if selected_text:match("^%~%~.*%~%~$") then
		vim.notify("Text already has strikethrough", vim.log.levels.INFO)
	else
		vim.cmd("normal 2gsa~")
	end
end, { desc = "[P]Strike through current selection" })

-- In visual mode, check if the selected text is already bold and show a message if it is
-- If not, surround it with double asterisks for bold
vim.keymap.set("v", "<leader>mb", function()
	-- Get the selected text range
	local start_row, start_col = unpack(vim.fn.getpos("'<"), 2, 3)
	local end_row, end_col = unpack(vim.fn.getpos("'>"), 2, 3)
	-- Get the selected lines
	local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
	local selected_text = table.concat(lines, "\n"):sub(start_col, #lines == 1 and end_col or -1)
	if selected_text:match("^%*%*.*%*%*$") then
		vim.notify("Text already bold", vim.log.levels.INFO)
	else
		vim.cmd("normal 2gsa*")
	end
end, { desc = "[P]BOLD current selection" })

-- -- Multiline unbold attempt
-- -- In normal mode, bold the current word under the cursor
-- -- If already bold, it will unbold the word under the cursor
-- -- If you're in a multiline bold, it will unbold it only if you're on the
-- -- first line
vim.keymap.set("n", "<leader>mb", function()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local current_buffer = vim.api.nvim_get_current_buf()
	local start_row = cursor_pos[1] - 1
	local col = cursor_pos[2]
	-- Get the current line
	local line = vim.api.nvim_buf_get_lines(current_buffer, start_row, start_row + 1, false)[1]
	-- Check if the cursor is on an asterisk
	if line:sub(col + 1, col + 1):match("%*") then
		vim.notify("Cursor is on an asterisk, run inside the bold text", vim.log.levels.WARN)
		return
	end
	-- Search for '**' to the left of the cursor position
	local left_text = line:sub(1, col)
	local bold_start = left_text:reverse():find("%*%*")
	if bold_start then
		bold_start = col - bold_start
	end
	-- Search for '**' to the right of the cursor position and in following lines
	local right_text = line:sub(col + 1)
	local bold_end = right_text:find("%*%*")
	local end_row = start_row
	while not bold_end and end_row < vim.api.nvim_buf_line_count(current_buffer) - 1 do
		end_row = end_row + 1
		local next_line = vim.api.nvim_buf_get_lines(current_buffer, end_row, end_row + 1, false)[1]
		if next_line == "" then
			break
		end
		right_text = right_text .. "\n" .. next_line
		bold_end = right_text:find("%*%*")
	end
	if bold_end then
		bold_end = col + bold_end
	end
	-- Remove '**' markers if found, otherwise bold the word
	if bold_start and bold_end then
		-- Extract lines
		local text_lines = vim.api.nvim_buf_get_lines(current_buffer, start_row, end_row + 1, false)
		local text = table.concat(text_lines, "\n")
		-- Calculate positions to correctly remove '**'
		-- vim.notify("bold_start: " .. bold_start .. ", bold_end: " .. bold_end)
		local new_text = text:sub(1, bold_start - 1) .. text:sub(bold_start + 2, bold_end - 1) .. text:sub(bold_end + 2)
		local new_lines = vim.split(new_text, "\n")
		-- Set new lines in buffer
		vim.api.nvim_buf_set_lines(current_buffer, start_row, end_row + 1, false, new_lines)
	-- vim.notify("Unbolded text", vim.log.levels.INFO)
	else
		-- Bold the word at the cursor position if no bold markers are found
		local before = line:sub(1, col)
		local after = line:sub(col + 1)
		local inside_surround = before:match("%*%*[^%*]*$") and after:match("^[^%*]*%*%*")
		if inside_surround then
			vim.cmd("normal gsd*.")
		else
			vim.cmd("normal viw")
			vim.cmd("normal 2gsa*")
		end
		vim.notify("Bolded current word", vim.log.levels.INFO)
	end
end, { desc = "[P]BOLD toggle bold markers" })

-- -- Single word/line bold
-- -- In normal mode, bold the current word under the cursor
-- -- If already bold, it will unbold the word under the cursor
-- -- This does NOT unbold multilines
-- vim.keymap.set("n", "<leader>mb", function()
--   local cursor_pos = vim.api.nvim_win_get_cursor(0)
--   -- local row = cursor_pos[1] -- Removed the unused variable
--   local col = cursor_pos[2]
--   local line = vim.api.nvim_get_current_line()
--   -- Check if the cursor is on an asterisk
--   if line:sub(col + 1, col + 1):match("%*") then
--     vim.notify("Cursor is on an asterisk, run inside the bold text", vim.log.levels.WARN)
--     return
--   end
--   -- Check if the cursor is inside surrounded text
--   local before = line:sub(1, col)
--   local after = line:sub(col + 1)
--   local inside_surround = before:match("%*%*[^%*]*$") and after:match("^[^%*]*%*%*")
--   if inside_surround then
--     vim.cmd("normal gsd*.")
--   else
--     vim.cmd("normal viw")
--     vim.cmd("normal 2gsa*")
--   end
-- end, { desc = "[P]BOLD toggle on current word or selection" })

-- -- Crate task or checkbox lamw25wmal
-- -- These are marked with <leader>x using bullets.vim
keymap.set("n", "<leader>ml", function()
	vim.cmd("normal! i- [ ]  ")
	vim.cmd("startinsert")
end, { desc = "[P]Toggle checkbox" })

-- Crate task or checkbox lamw26wmal
-- These are marked with <leader>x using bullets.vim
-- I used <C-l> before, but that is used for pane navigation
vim.keymap.set({ "n", "i" }, "<M-l>", function()
	-- Get the current line/row/column
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local row, _ = cursor_pos[1], cursor_pos[2]
	local line = vim.api.nvim_get_current_line()
	-- 1) If line is empty => replace it with "- [ ] " and set cursor after the brackets
	if line:match("^%s*$") then
		local final_line = "- [ ] "
		vim.api.nvim_set_current_line(final_line)
		-- "- [ ] " is 6 characters, so cursor col = 6 places you *after* that space
		vim.api.nvim_win_set_cursor(0, { row, 6 })
		return
	end
	-- 2) Check if line already has a bullet with possible indentation: e.g. "  - Something"
	--    We'll capture "  -" (including trailing spaces) as `bullet` plus the rest as `text`.
	local bullet, text = line:match("^([%s]*[-*]%s+)(.*)$")
	if bullet then
		-- Convert bullet => bullet .. "[ ] " .. text
		local final_line = bullet .. "[ ] " .. text
		vim.api.nvim_set_current_line(final_line)
		-- Place the cursor right after "[ ] "
		-- bullet length + "[ ] " is bullet_len + 4 characters,
		-- but bullet has trailing spaces, so #bullet includes those.
		local bullet_len = #bullet
		-- We want to land after the brackets (four characters: `[ ] `),
		-- so col = bullet_len + 4 (0-based).
		vim.api.nvim_win_set_cursor(0, { row, bullet_len + 4 })
		return
	end
	-- 3) If there's text, but no bullet => prepend "- [ ] "
	--    and place cursor after the brackets
	local final_line = "- [ ] " .. line
	vim.api.nvim_set_current_line(final_line)
	-- "- [ ] " is 6 characters
	vim.api.nvim_win_set_cursor(0, { row, 6 })
end, { desc = "Convert bullet to a task or insert new task bullet" })

-- -- This was not as reliable, and is now retired
-- -- replaced with a luasnip snippet `;linkc`
-- -- In visual mode, surround the selected text with markdown link syntax
-- vim.keymap.set("v", "<leader>mll", function()
--   -- Copy what's currently in my clipboard to the register "a lamw25wmal
--   vim.cmd("let @a = getreg('+')")
--   -- delete selected text
--   vim.cmd("normal d")
--   -- Insert the following in insert mode
--   vim.cmd("startinsert")
--   vim.api.nvim_put({ "[]() " }, "c", true, true)
--   -- Move to the left, paste, and then move to the right
--   vim.cmd("normal F[pf(")
--   -- Copy what's on the "a register back to the clipboard
--   vim.cmd("call setreg('+', @a)")
--   -- Paste what's on the clipboard
--   vim.cmd("normal p")
--   -- Leave me in normal mode or command mode
--   vim.cmd("stopinsert")
--   -- Leave me in insert mode to start typing
--   -- vim.cmd("startinsert")
-- end, { desc = "[P]Convert to link" })
--
-- -- This was not as reliable, and is now retired
-- -- replaced with a luasnip snippet `;linkcex`
-- -- In visual mode, surround the selected text with markdown link syntax
-- vim.keymap.set("v", "<leader>mlt", function()
--   -- Copy what's currently in my clipboard to the register "a lamw25wmal
--   vim.cmd("let @a = getreg('+')")
--   -- delete selected text
--   vim.cmd("normal d")
--   -- Insert the following in insert mode
--   vim.cmd("startinsert")
--   vim.api.nvim_put({ '[](){:target="_blank"} ' }, "c", true, true)
--   vim.cmd("normal F[pf(")
--   -- Copy what's on the "a register back to the clipboard
--   vim.cmd("call setreg('+', @a)")
--   -- Paste what's on the clipboard
--   vim.cmd("normal p")
--   -- Leave me in normal mode or command mode
--   vim.cmd("stopinsert")
--   -- Leave me in insert mode to start typing
--   -- vim.cmd("startinsert")
-- end, { desc = "[P]Convert to link (new tab)" })

-- Paste a github link and add it in this format
-- [folke/noice.nvim](https://github.com/folke/noice.nvim)
vim.keymap.set({ "n", "v", "i" }, "<M-;>", function()
	-- Insert the text in the desired format
	vim.cmd("normal! a[]() ")
	vim.cmd("normal! F(pv2F/lyF[p")
	-- Leave me in normal mode or command mode
	vim.cmd("stopinsert")
end, { desc = "[P]Paste Github link" })

-- Paste a github link and add it in this format
-- [folke/noice.nvim](https://github.com/folke/noice.nvim){:target="\_blank"}
vim.keymap.set({ "n", "v", "i" }, "<M-:>", function()
	-- Insert the text in the desired format
	vim.cmd('normal! a[](){:target="_blank"} ')
	vim.cmd("normal! F(pv2F/lyF[p")
	-- Leave me in normal mode or command mode
	vim.cmd("stopinsert")
end, { desc = "[P]Paste Github link" })