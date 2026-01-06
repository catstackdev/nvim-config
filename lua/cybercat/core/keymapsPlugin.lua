local keymap = vim.keymap -- for conciseness

-- keymap.set("i", "kj", "<ESC>", { desc = "[P]Exit insert mode with kj" })

-- for Scroll
-- By default, CTRL-U and CTRL-D scroll by half a screen (50% of the window height)
-- Scroll by 35% of the window height and keep the cursor centered
local scroll_percentage = 0.35
-- Scroll by a percentage of the window height and keep the cursor centered
keymap.set("n", "<C-d>", function()
	local lines = math.floor(vim.api.nvim_win_get_height(0) * scroll_percentage)
	vim.cmd("normal! " .. lines .. "jzz")
end, { noremap = true, silent = true })
keymap.set("n", "<C-u>", function()
	local lines = math.floor(vim.api.nvim_win_get_height(0) * scroll_percentage)
	vim.cmd("normal! " .. lines .. "kzz")
end, { noremap = true, silent = true })

-- for noice
keymap.set({ "n", "v", "i" }, "<M-h>", function()
	-- require("noice").cmd("history")
	require("noice").cmd("all")
end, { desc = "[P]Noice History" })

-- Dismiss noice notifications
keymap.set({ "n", "v", "i" }, "<M-d>", function()
	require("noice").cmd("dismiss")
end, { desc = "Dismiss All" })

-- Copy the current line and all diagnostics on that line to system clipboard
--(LSP errors, warnings, hints, etc.)
vim.keymap.set("n", "yd", function()
	local pos = vim.api.nvim_win_get_cursor(0)
	local line_num = pos[1] - 1 -- 0-indexed
	local line_text = vim.api.nvim_buf_get_lines(0, line_num, line_num + 1, false)[1]
	local diagnostics = vim.diagnostic.get(0, { lnum = line_num })
	if #diagnostics == 0 then
		vim.notify("No diagnostic found on this line", vim.log.levels.WARN)
		return
	end
	local message_lines = {}
	for _, d in ipairs(diagnostics) do
		for msg_line in d.message:gmatch("[^\n]+") do
			table.insert(message_lines, msg_line)
		end
	end
	local formatted = {}
	table.insert(formatted, "Line:\n" .. line_text .. "\n")
	table.insert(formatted, "Diagnostic on that line:\n" .. table.concat(message_lines, "\n"))
	vim.fn.setreg("+", table.concat(formatted, "\n\n"))
	vim.notify("Line and diagnostic copied to clipboard", vim.log.levels.INFO)
end, { desc = "[P]Yank line and diagnostic to system clipboard" })

-- keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "[P]Move line down in visual mode" })
-- keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "[P]Move line up in visual mode" })
-- When you do joins with J it will keep your cursor at the beginning instead of at the end
-- keymap.set("n", "J", "mzJ`z")

-- When searching for stuff, search results show in the middle
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")

-- Toggle executable permission on current file, previously I had 2 keymaps, to
-- add or remove exec permissions, now it's a toggle using the same keymap
-- just do on opened file not on tree dir
keymap.set("n", "<leader>fx", function()
	local file = vim.fn.expand("%:p") -- full path of current buffer
	if file == "" or vim.fn.filereadable(file) == 0 then
		vim.notify("No file to toggle permissions", vim.log.levels.WARN)
		return
	end

	local stat = vim.loop.fs_stat(file)
	if not stat then
		vim.notify("Cannot get file status", vim.log.levels.ERROR)
		return
	end

	-- Check owner execute permission
	local is_executable = bit.band(stat.mode, 0x40) ~= 0 -- 0x40 = 0o100

	local cmd
	if is_executable then
		cmd = { "chmod", "-x", file }
	else
		cmd = { "chmod", "+x", file }
	end

	local ok = os.execute(table.concat(cmd, " "))
	if ok then
		vim.notify(
			is_executable and "Removed executable permission" or "Added executable permission",
			vim.log.levels.INFO
		)
	else
		vim.notify("Failed to toggle executable permission", vim.log.levels.ERROR)
	end
end, { desc = "Toggle executable permission" })

-- If this is a bash script, make it executable, and execute it in a tmux pane on the right
-- Using a tmux pane allows me to easily select text
-- Had to include quotes around "%" because there are some apple dirs that contain spaces, like iCloud
keymap.set("n", "<leader>cb", function()
	local file = vim.fn.expand("%:p") -- Get the current file name
	local first_line = vim.fn.getline(1) -- Get the first line of the file
	if string.match(first_line, "^#!/") then -- If first line contains shebang
		local escaped_file = vim.fn.shellescape(file) -- Properly escape the file name for shell commands
		-- Execute the script on a tmux pane on the right. On my mac I use zsh, so
		-- running this script with bash to not execute my zshrc file after
		-- vim.cmd("silent !tmux split-window -h -l 60 'bash -c \"" .. escaped_file .. "; exec bash\"'")
		-- `-l 60` specifies the size of the tmux pane, in this case 60 columns
		vim.cmd(
			"silent !tmux split-window -h -l 60 'bash -c \""
				.. escaped_file
				.. "; echo; echo Press any key to exit...; read -n 1; exit\"'"
		)
	else
		vim.cmd("echo 'Not a script. Shebang line not found.'")
	end
end, { desc = "[P]BASH, execute file" })

keymap.set({ "n", "i" }, "<M-a>", function()
	local pasted_image = require("img-clip").paste_image()
	if pasted_image then
		-- "Update" saves only if the buffer has been modified since the last save
		vim.cmd("silent! update")
		-- Get the current line
		local line = vim.api.nvim_get_current_line()
		-- Move cursor to end of line
		vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], #line })
		-- I reload the file, otherwise I cannot view the image after pasted
		vim.cmd("edit!")
	end
end, { desc = "[P]Paste image from system clipboard" })

-- NOTE: Configuration for image storage path
-- Change this to customize where images are stored relative to the assets directory
-- If below you use "img/imgs", it will store in "assets/img/imgs"
-- Added option to choose image format and resolution lamw26wmal
local IMAGE_STORAGE_PATH = "img/imgs"

-- This function is used in 2 places in the paste images in assets dir section
-- finds the assets/img/imgs directory going one dir at a time and returns the full path
local function find_assets_dir()
	local dir = vim.fn.expand("%:p:h")
	while dir ~= "/" do
		local full_path = dir .. "/assets/" .. IMAGE_STORAGE_PATH
		if vim.fn.isdirectory(full_path) == 1 then
			return full_path
		end
		dir = vim.fn.fnamemodify(dir, ":h")
	end
	return nil
end

-- Since I need to store these images in a different directory, I pass the options to img-clip
local function handle_image_paste(img_dir)
	local function paste_image(dir_path, file_name, ext, cmd)
		return require("img-clip").paste_image({
			dir_path = dir_path,
			use_absolute_path = false,
			relative_to_current_file = false,
			file_name = file_name,
			extension = ext or "avif",
			process_cmd = cmd or "convert - -quality 75 avif:-",
		})
	end
	local temp_buf = vim.api.nvim_create_buf(false, true) -- Create an unlisted, scratch buffer
	vim.api.nvim_set_current_buf(temp_buf) -- Switch to the temporary buffer
	local temp_image_path = vim.fn.tempname() .. ".avif"
	local image_pasted =
		paste_image(vim.fn.fnamemodify(temp_image_path, ":h"), vim.fn.fnamemodify(temp_image_path, ":t:r"))
	vim.api.nvim_buf_delete(temp_buf, { force = true }) -- Delete the buffer
	vim.fn.delete(temp_image_path) -- Delete the temporary file
	vim.defer_fn(function()
		local options = image_pasted and { "no", "yes", "format", "search" } or { "search" }
		local prompt = image_pasted and "Is this a thumbnail image? "
			or "No image in clipboard. Select search to continue."
		-- -- I was getting a character in the textbox, don't want to debug right now
		-- vim.cmd("stopinsert")
		vim.ui.select(options, { prompt = prompt }, function(is_thumbnail)
			if is_thumbnail == "search" then
				local assets_dir = find_assets_dir()
				-- Get the parent directory of the current file
				local current_dir = vim.fn.expand("%:p:h")
				-- remove warning: Cannot assign `string|nil` to parameter `string`
				if not assets_dir then
					print("Assets directory not found, cannot proceed with search.")
					return
				end
				-- Get the parent directory of assets_dir (removing /img/imgs)
				local base_assets_dir = vim.fn.fnamemodify(assets_dir, ":h:h:h")
				-- Count how many levels we need to go up
				local levels = 0
				local temp_dir = current_dir
				while temp_dir ~= base_assets_dir and temp_dir ~= "/" do
					levels = levels + 1
					temp_dir = vim.fn.fnamemodify(temp_dir, ":h")
				end
				-- Build the relative path
				local relative_path = levels == 0 and "./assets/" .. IMAGE_STORAGE_PATH
					or string.rep("../", levels) .. "assets/" .. IMAGE_STORAGE_PATH
				vim.api.nvim_put({ "![Image](" .. relative_path .. '){: width="500" }' }, "c", true, true)
				-- Capital "O" to move to the line above
				vim.cmd("normal! O")
				-- This "o" is to leave a blank line above
				vim.cmd("normal! o")
				vim.api.nvim_put({ "<!-- prettier-ignore -->" }, "c", true, true)
				vim.cmd("normal! jo")
				vim.api.nvim_put({ "_textimage_", "" }, "c", true, true)
				-- find image path and add a / at the end of it
				vim.cmd("normal! kkf)i/")
				-- Move one to the right and enter insert mode
				vim.cmd("normal! la")
				-- -- This puts me in insert mode where the cursor is
				-- vim.api.nvim_feedkeys("i", "n", true)
				require("auto-save").on()
				return
			end
			if not is_thumbnail then
				print("Image pasting canceled.")
				require("auto-save").on()
				return
			end
			if is_thumbnail == "format" then
				local extension_options = { "avif", "webp", "png", "jpg" }
				vim.ui.select(extension_options, {
					prompt = "Select image format:",
					default = "avif",
				}, function(selected_ext)
					if not selected_ext then
						return
					end
					-- Define proceed_with_paste with proper parameter names
					local function proceed_with_paste(process_command)
						local prefix = vim.fn.strftime("%y%m%d-")
						local function prompt_for_name()
							vim.ui.input(
								{ prompt = "Enter image name (no spaces). Added prefix: " .. prefix },
								function(input_name)
									if not input_name or input_name:match("%s") then
										print("Invalid image name or canceled. Image not pasted.")
										require("auto-save").on()
										return
									end
									local full_image_name = prefix .. input_name
									local file_path = img_dir .. "/" .. full_image_name .. "." .. selected_ext
									if vim.fn.filereadable(file_path) == 1 then
										print("Image name already exists. Please enter a new name.")
										prompt_for_name()
									else
										if paste_image(img_dir, full_image_name, selected_ext, process_command) then
											vim.api.nvim_put({ '{: width="500" }' }, "c", true, true)
											vim.cmd("normal! O")
											vim.cmd("stopinsert")
											vim.cmd("normal! o")
											vim.api.nvim_put({ "<!-- prettier-ignore -->" }, "c", true, true)
											vim.cmd("normal! j$o")
											vim.cmd("stopinsert")
											vim.api.nvim_put({ "__" }, "c", true, true)
											vim.cmd("normal! h")
											vim.cmd("silent! update")
											vim.cmd("edit!")
											require("auto-save").on()
										else
											print("No image pasted. File not updated.")
											require("auto-save").on()
										end
									end
								end
							)
						end
						prompt_for_name()
					end
					-- Resolution prompt handling
					vim.ui.select({ "Yes", "No" }, {
						prompt = "Change image resolution?",
						default = "No",
					}, function(resize_choice)
						local process_cmd
						if resize_choice == "Yes" then
							vim.ui.input({
								prompt = "Enter max height (default 1080): ",
								default = "1080",
							}, function(height_input)
								local height = tonumber(height_input) or 1080
								process_cmd =
									string.format("convert - -resize x%d -quality 100 %s:-", height, selected_ext)
								proceed_with_paste(process_cmd)
							end)
						else
							process_cmd = "convert - -quality 75 " .. selected_ext .. ":-"
							proceed_with_paste(process_cmd)
						end
					end)
				end)
				return
			end
			local prefix = vim.fn.strftime("%y%m%d-") .. (is_thumbnail == "yes" and "thux-" or "")
			local function prompt_for_name()
				vim.ui.input({ prompt = "Enter image name (no spaces). Added prefix: " .. prefix }, function(input_name)
					if not input_name or input_name:match("%s") then
						print("Invalid image name or canceled. Image not pasted.")
						require("auto-save").on()
						return
					end
					local full_image_name = prefix .. input_name
					local file_path = img_dir .. "/" .. full_image_name .. ".avif"
					if vim.fn.filereadable(file_path) == 1 then
						print("Image name already exists. Please enter a new name.")
						prompt_for_name()
					else
						if paste_image(img_dir, full_image_name) then
							vim.api.nvim_put({ '{: width="500" }' }, "c", true, true)
							-- Create new line above and force normal mode
							vim.cmd("normal! O")
							vim.cmd("stopinsert") -- Explicitly exit insert mode
							-- Create blank line above and force normal mode
							vim.cmd("normal! o")
							vim.cmd("stopinsert")
							vim.api.nvim_put({ "<!-- prettier-ignore -->" }, "c", true, true)
							-- Move down and create new line (without staying in insert mode)
							vim.cmd("normal! j$o")
							vim.cmd("stopinsert")
							vim.api.nvim_put({ "__" }, "c", true, true)
							vim.cmd("normal! h") -- Position cursor between underscores
							vim.cmd("silent! update")
							vim.cmd("edit!")
							require("auto-save").on()
						else
							print("No image pasted. File not updated.")
							require("auto-save").on()
						end
					end
				end)
			end
			prompt_for_name()
		end)
	end, 100)
end

local function process_image()
	-- Any of these 2 work to toggle auto-save
	-- vim.cmd("ASToggle")
	require("auto-save").off()
	local img_dir = find_assets_dir()
	if not img_dir then
		vim.ui.select({ "yes", "no" }, {
			prompt = IMAGE_STORAGE_PATH .. " directory not found. Create it?",
			default = "yes",
		}, function(choice)
			if choice == "yes" then
				img_dir = vim.fn.getcwd() .. "/assets/" .. IMAGE_STORAGE_PATH
				vim.fn.mkdir(img_dir, "p")
				-- Start the image paste process after creating directory
				vim.defer_fn(function()
					handle_image_paste(img_dir)
				end, 100)
			else
				print("Operation cancelled - directory not created")
				require("auto-save").on()
				return
			end
		end)
		return
	end
	handle_image_paste(img_dir)
end

-- Keymap to paste images in the 'assets' directory
-- This pastes images for my blogpost, I need to keep them in a different directory
-- so I pass those options to img-clip
vim.keymap.set({ "n", "i" }, "<M-1>", process_image, { desc = "[P]Paste image 'assets' directory" })

-------------------------------------------------------------------------------

-- Rename image under cursor lamw25wmal
-- If the image is referenced multiple times in the file, it will also rename
-- all the other occurrences in the file
vim.keymap.set("n", "<leader>iR", function()
	local function get_image_path()
		-- Get the current line
		local line = vim.api.nvim_get_current_line()
		-- Pattern to match image path in Markdown
		local image_pattern = "%[.-%]%((.-)%)"
		-- Extract relative image path
		local _, _, image_path = string.find(line, image_pattern)
		return image_path
	end
	-- Get the image path
	local image_path = get_image_path()
	if not image_path then
		vim.api.nvim_echo({ { "No image found under the cursor", "WarningMsg" } }, false, {})
		return
	end
	-- Check if it's a URL
	if string.sub(image_path, 1, 4) == "http" then
		vim.api.nvim_echo({ { "URL images cannot be renamed.", "WarningMsg" } }, false, {})
		return
	end
	-- Get absolute paths
	local current_file_path = vim.fn.expand("%:p:h")
	local absolute_image_path = current_file_path .. "/" .. image_path
	-- Check if file exists
	if vim.fn.filereadable(absolute_image_path) == 0 then
		vim.api.nvim_echo(
			{ { "Image file does not exist:\n", "ErrorMsg" }, { absolute_image_path, "ErrorMsg" } },
			false,
			{}
		)
		return
	end
	-- Get directory and extension of current image
	local dir = vim.fn.fnamemodify(absolute_image_path, ":h")
	local ext = vim.fn.fnamemodify(absolute_image_path, ":e")
	local current_name = vim.fn.fnamemodify(absolute_image_path, ":t:r")
	-- Prompt for new name
	vim.ui.input({ prompt = "Enter new name (without extension): ", default = current_name }, function(new_name)
		if not new_name or new_name == "" then
			vim.api.nvim_echo({ { "Rename cancelled", "WarningMsg" } }, false, {})
			return
		end
		-- Construct new path
		local new_absolute_path = dir .. "/" .. new_name .. "." .. ext
		-- Check if new filename already exists
		if vim.fn.filereadable(new_absolute_path) == 1 then
			vim.api.nvim_echo({ { "File already exists: " .. new_absolute_path, "ErrorMsg" } }, false, {})
			return
		end
		-- Rename the file
		local success, err = os.rename(absolute_image_path, new_absolute_path)
		if success then
			-- Get the old and new filenames (without path)
			local old_filename = vim.fn.fnamemodify(absolute_image_path, ":t")
			local new_filename = vim.fn.fnamemodify(new_absolute_path, ":t")
			-- -- Debug prints
			-- print("Old filename:", old_filename)
			-- print("New filename:", new_filename)
			-- Get buffer content
			local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			-- print("Number of lines in buffer:", #lines)
			-- Replace the text in each line that contains the old filename
			for i = 0, #lines - 1 do
				local line = lines[i + 1]
				-- First find the image markdown pattern with explicit end
				local img_start, img_end = line:find("!%[.-%]%(.-%)")
				if img_start and img_end then
					-- Get just the exact markdown part without any extras
					local markdown_part = line:match("!%[.-%]%(.-%)")
					-- Replace old filename with new filename
					local escaped_old = old_filename:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
					local escaped_new = new_filename:gsub("[%%]", "%%%%")
					-- Replace in the exact markdown part
					local new_markdown = markdown_part:gsub(escaped_old, escaped_new)
					-- Replace that exact portion in the line
					vim.api.nvim_buf_set_text(
						0,
						i,
						img_start - 1,
						i,
						img_start + #markdown_part - 1, -- Use exact length of markdown part
						{ new_markdown }
					)
				end
			end
			-- "Update" saves only if the buffer has been modified since the last save
			vim.cmd("update")
			vim.api.nvim_echo({
				{ "Image renamed successfully", "Normal" },
			}, false, {})
		else
			vim.api.nvim_echo({
				{ "Failed to rename image:\n", "ErrorMsg" },
				{ tostring(err), "ErrorMsg" },
			}, false, {})
		end
	end)
end, { desc = "[P]Rename image under cursor" })

-- HACK: Upload images from Neovim to Imgur
-- https://youtu.be/Lzl_0SzbUBo
--
-- Upload images to my own imgur account (authenticated)
--
-- NOTE: This command is for macOS because that's the OS I use
-- if you use Linux, it will try, but if it fails you'll have to adapt the
-- `local upload_command` and make sure you have the dependencies needed
--
-- NOTE: Issue where image in clipboard was not "detected" has been fixed
--
-- This script uploads images to Imgur using an access token, and refreshes the token if it's expired.
-- It reads environment variables from a specified file and updates them as needed.
--
-- If you want to upload the images to your own imgur account, follow the
-- registration quickstart section in https://apidocs.imgur.com/
-- You can use postman's web version or the desktop app, the instructions tell
-- you even how to import imgur's api collection in postman lamw25wmal
--
-- For the new postman version go to the `Imgur API` folder, then click on the
-- `Authorization` tab, set the auth type to `oauth 2.0`, fill in the fields in
-- the `Configure new token` section, and click `Get New Access Token` at the
-- bottom, this will give you a lot of details including the refresh token
--
-- Configuration:
-- - Ensure your environment variables are stored in a file formatted as `VARIABLE="value"`.
-- NOTE: Here's a sample file to copy and paste:
-- IMGUR_ACCESS_TOKEN="xxxxxxx"
-- IMGUR_REFRESH_TOKEN="yyyyyyy"
-- IMGUR_CLIENT_ID="zzzzzz"
-- IMGUR_CLIENT_SECRET="wwwwww"
--
-- Path to your environment variables file
local env_file_path = vim.fn.expand("~/Library/Mobile Documents/com~apple~CloudDocs/github/imgur_credentials")
-- Configuration variables
-- update these names to match the names you have in the file above
local access_token_var = "IMGUR_ACCESS_TOKEN"
local refresh_token_var = "IMGUR_REFRESH_TOKEN"
local client_id_var = "IMGUR_CLIENT_ID"
local client_secret_var = "IMGUR_CLIENT_SECRET"
-- Keymap setup
vim.keymap.set({ "n", "i" }, "<M-i>", function()
	vim.notify("UPLOADING IMAGE TO IMGUR...", vim.log.levels.INFO)
	-- Slight delay to show the message
	vim.defer_fn(function()
		-- Function to read environment variables from the specified file
		local function load_env_variables()
			local env_vars = {}
			local file = io.open(env_file_path, "r")
			if file then
				for line in file:lines() do
					-- Updated pattern to match lines without 'export'
					for key, value in string.gmatch(line, '([%w_]+)="([^"]+)"') do
						env_vars[key] = value
					end
				end
				file:close()
			else
				vim.notify(
					"Failed to open " .. env_file_path .. " to load environment variables.",
					vim.log.levels.ERROR
				)
			end
			return env_vars
		end
		-- Load environment variables
		local env_vars = load_env_variables()
		-- Set environment variables in Neovim
		for key, value in pairs(env_vars) do
			vim.fn.setenv(key, value)
		end
		-- Retrieve the necessary variables
		local imgur_access_token = env_vars[access_token_var]
		local imgur_refresh_token = env_vars[refresh_token_var]
		local imgur_client_id = env_vars[client_id_var]
		local imgur_client_secret = env_vars[client_secret_var]
		if not imgur_access_token or imgur_access_token == "" then
			vim.notify(
				"Imgur Access Token not found. Please set " .. access_token_var .. " in your environment file.",
				vim.log.levels.ERROR
			)
			return
		end
		-- Predeclare the functions to handle mutual references
		local upload_to_imgur
		local refresh_access_token
		local upload_attempts = 0 -- Keep track of upload attempts to prevent infinite loops
		-- Function to refresh the access token if expired
		refresh_access_token = function(callback)
			vim.notify("Access token invalid or expired. Refreshing access token...", vim.log.levels.WARN)
			local refresh_command = string.format(
				[[curl --silent --request POST "https://api.imgur.com/oauth2/token" \
        --data "refresh_token=%s" \
        --data "client_id=%s" \
        --data "client_secret=%s" \
        --data "grant_type=refresh_token"]],
				imgur_refresh_token,
				imgur_client_id,
				imgur_client_secret
			)
			-- print("Refresh command: " .. refresh_command) -- Log the refresh command
			local new_access_token = nil
			local new_refresh_token = nil
			vim.fn.jobstart(refresh_command, {
				stdout_buffered = true,
				on_stdout = function(_, data)
					local json_data = table.concat(data, "\n")
					-- print("Refresh token response JSON: " .. json_data) -- Log the response JSON
					local response = vim.fn.json_decode(json_data)
					if response and response.access_token then
						new_access_token = response.access_token
						new_refresh_token = response.refresh_token
					-- print("New access token obtained: " .. new_access_token) -- Log the new access token
					-- print("New refresh token obtained: " .. new_refresh_token) -- Log the new refresh token
					else
						vim.notify(
							"Failed to refresh access token: "
								.. (response and response.error_description or "Unknown error"),
							vim.log.levels.ERROR
						)
					end
				end,
				on_exit = function()
					if new_access_token and new_refresh_token then
						-- Update environment variables in Neovim
						vim.fn.setenv(access_token_var, new_access_token)
						vim.fn.setenv(refresh_token_var, new_refresh_token)
						imgur_access_token = new_access_token
						imgur_refresh_token = new_refresh_token
						vim.notify("Access token refreshed successfully.", vim.log.levels.INFO)
						-- Write the new access token and refresh token to the environment file to persist them
						local file = io.open(env_file_path, "r+")
						if not file then
							vim.notify(
								"Error: Could not open " .. env_file_path .. " for writing.",
								vim.log.levels.ERROR
							)
							return
						end
						local content = file:read("*all")
						if content then
							-- Update Access Token
							local pattern_access = access_token_var .. '="[^"]*"'
							local replacement_access = access_token_var .. '="' .. new_access_token .. '"'
							content = content:gsub(pattern_access, replacement_access)
							-- Update Refresh Token
							local pattern_refresh = refresh_token_var .. '="[^"]*"'
							local replacement_refresh = refresh_token_var .. '="' .. new_refresh_token .. '"'
							content = content:gsub(pattern_refresh, replacement_refresh)
							file:seek("set", 0)
							file:write(content)
							file:close()
						else
							vim.notify("Failed to read " .. env_file_path .. " content.", vim.log.levels.ERROR)
							file:close()
						end
						-- Reload environment variables from the environment file
						env_vars = load_env_variables()
						for key, value in pairs(env_vars) do
							vim.fn.setenv(key, value)
						end
						-- Callback after refreshing the token
						if callback then
							callback()
						end
					else
						vim.notify("Failed to refresh access token.", vim.log.levels.ERROR)
					end
				end,
			})
		end
		-- Function to execute image upload command to Imgur
		upload_to_imgur = function()
			upload_attempts = upload_attempts + 1
			if upload_attempts > 2 then
				vim.notify("Maximum upload attempts reached. Please check your credentials.", vim.log.levels.ERROR)
				return
			end
			-- Detect the operating system
			local is_mac = vim.fn.has("macunix") == 1
			local is_linux = vim.fn.has("unix") == 1 and not is_mac
			local clipboard_command = ""
			if is_mac then
				-- macOS command to get image from clipboard
				clipboard_command =
					[[osascript -e 'get the clipboard as «class PNGf»' | sed 's/«data PNGf//; s/»//' | xxd -r -p]]
			elseif is_linux then
				-- Linux command to get image from clipboard using xclip
				clipboard_command = [[xclip -selection clipboard -t image/png -o]]
			-- Alternative for Wayland-based systems (uncomment if needed)
			-- clipboard_command = [[wl-paste --type image/png]]
			else
				vim.notify("Unsupported operating system for clipboard image upload.", vim.log.levels.ERROR)
				return
			end
			local upload_command = string.format(
				[[
          %s \
          | curl --silent --write-out "HTTPSTATUS:%%{http_code}" --request POST --form "image=@-" \
          --header "Authorization: Bearer %s" "https://api.imgur.com/3/image"
        ]],
				clipboard_command,
				imgur_access_token
			)
			-- print("Upload command: " .. upload_command) -- Log the upload command
			local url = nil
			local error_status = nil
			local error_message = nil
			local account_id = nil
			vim.fn.jobstart(upload_command, {
				stdout_buffered = true,
				on_stdout = function(_, data)
					local output = table.concat(data, "\n")
					local json_data, http_status = output:match("^(.*)HTTPSTATUS:(%d+)$")
					if not json_data or not http_status then
						-- print("Failed to parse response and HTTP status code.")
						error_status = nil
						error_message = "Unknown error"
						return
					end
					-- print("Upload response JSON: " .. json_data)
					-- print("HTTP status code: " .. http_status)
					local response = vim.fn.json_decode(json_data)
					error_status = tonumber(http_status)
					if error_status >= 200 and error_status < 300 and response and response.success then
						url = response.data.link
						account_id = response.data.account_id
					-- print("Upload successful. URL: " .. url)
					else
						-- Extract error message from different possible response formats
						if response.data and response.data.error then
							error_message = response.data.error
						elseif response.errors and response.errors[1] and response.errors[1].detail then
							error_message = response.errors[1].detail
						else
							error_message = "Unknown error"
						end
						-- print("Upload failed. Status: " .. tostring(error_status) .. ", Error: " .. error_message)
					end
				end,
				on_exit = function()
					if url and account_id ~= vim.NIL and account_id ~= nil then
						-- Format the URL as Markdown
						local markdown_url = string.format("![imgur](%s)", url)
						vim.notify("Image uploaded to Imgur.", vim.log.levels.INFO)
						-- Insert formatted Markdown link into buffer at cursor position
						local row, col = unpack(vim.api.nvim_win_get_cursor(0))
						vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { markdown_url })
					elseif error_status == 401 or error_status == 429 then
						vim.notify("Access token expired or invalid, refreshing...", vim.log.levels.WARN)
						refresh_access_token(function()
							upload_to_imgur()
						end)
					elseif error_status == 400 and error_message == "We don't support that file type!" then
						vim.notify("Failed to upload image: " .. error_message, vim.log.levels.ERROR)
					else
						vim.notify(
							"Failed to upload image to Imgur: " .. (error_message or "Unknown error"),
							vim.log.levels.ERROR
						)
					end
				end,
			})
		end
		-- Attempt to upload the image
		upload_to_imgur()
	end, 100)
end, { desc = "[P]Paste image to Imgur" })

-- -- Upload images to imgur, this uploads the images UN-authentiated, it means
-- -- it uploads them anonymously, not tied to your account
-- -- used this as a start
-- -- https://github.com/evanpurkhiser/image-paste.nvim/blob/main/lua/image-paste.lua
-- -- Configuration:
-- -- Path to your environment variables file
-- local env_file_path = vim.fn.expand("~/Library/Mobile Documents/com~apple~CloudDocs/github/imgur_credentials")
-- vim.keymap.set({ "n", "v", "i" }, "<C-f>", function()
--   print("UPLOADING IMAGE TO IMGUR...")
--   -- Slight delay to show the message
--   vim.defer_fn(function()
--     -- Function to read environment variables from the specified file
--     local function load_env_variables()
--       local env_vars = {}
--       local file = io.open(env_file_path, "r")
--       if file then
--         for line in file:lines() do
--           for key, value in string.gmatch(line, 'export%s+([%w_]+)="([^"]+)"') do
--             env_vars[key] = value
--           end
--         end
--         file:close()
--       else
--         print("Failed to open " .. env_file_path .. " to load environment variables.")
--       end
--       return env_vars
--     end
--     -- Load environment variables
--     local env_vars = load_env_variables()
--     -- Retrieve the Imgur Client ID from the loaded environment variables
--     local imgur_client_id = env_vars["IMGUR_CLIENT_ID"]
--     if not imgur_client_id or imgur_client_id == "" then
--       print("Imgur Client ID not found. Please set IMGUR_CLIENT_ID in your environment file.")
--       return
--     end
--     -- Function to execute image upload command to Imgur
--     local function upload_to_imgur()
--       local upload_command = string.format(
--         [[
--         osascript -e "get the clipboard as «class PNGf»" | sed "s/«data PNGf//; s/»//" | xxd -r -p \
--         | curl --silent --fail --request POST --form "image=@-" \
--           --header "Authorization: Client-ID %s" "https://api.imgur.com/3/upload" \
--         | jq --raw-output .data.link
--       ]],
--         imgur_client_id
--       )
--       local url = nil
--       vim.fn.jobstart(upload_command, {
--         stdout_buffered = true,
--         on_stdout = function(_, data)
--           url = vim.fn.join(data):gsub("^%s*(.-)%s*$", "%1")
--         end,
--         on_exit = function(_, exit_code)
--           if exit_code == 0 and url ~= "" then
--             -- Format the URL as Markdown
--             local markdown_url = string.format("![imgur](%s)", url)
--             print("Image uploaded to Imgur: " .. markdown_url)
--             -- Insert formatted Markdown link into buffer at cursor position
--             local row, col = unpack(vim.api.nvim_win_get_cursor(0))
--             vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { markdown_url })
--           else
--             print("Failed to upload image to Imgur.")
--           end
--         end,
--       })
--     end
--     -- Call the upload function
--     upload_to_imgur()
--   end, 100)
-- end, { desc = "[P]Paste image to Imgur" })

-- ############################################################################

-- HACK: Upload images from Neovim to Imgur
-- https://youtu.be/Lzl_0SzbUBo
--
-- Open image under cursor in the Preview app (macOS)
vim.keymap.set("n", "<leader>io", function()
	local function get_image_path()
		-- Get the current line
		local line = vim.api.nvim_get_current_line()
		-- Pattern to match image path in Markdown
		local image_pattern = "%[.-%]%((.-)%)"
		-- Extract relative image path
		local _, _, image_path = string.find(line, image_pattern)
		return image_path
	end
	-- Get the image path
	local image_path = get_image_path()
	if image_path then
		-- Check if the image path starts with "http" or "https"
		if string.sub(image_path, 1, 4) == "http" then
			print("URL image, use 'gx' to open it in the default browser.")
		else
			-- Construct absolute image path
			local current_file_path = vim.fn.expand("%:p:h")
			local absolute_image_path = current_file_path .. "/" .. image_path
			-- Construct command to open image in Preview
			local command = "open -a Preview " .. vim.fn.shellescape(absolute_image_path)
			-- Execute the command
			local success = os.execute(command)
			if success then
				print("Opened image in Preview: " .. absolute_image_path)
			else
				print("Failed to open image in Preview: " .. absolute_image_path)
			end
		end
	else
		print("No image found under the cursor")
	end
end, { desc = "[P](macOS) Open image under cursor in Preview" })

-- ############################################################################

-- HACK: Upload images from Neovim to Imgur
-- https://youtu.be/Lzl_0SzbUBo
--
-- Open image under cursor in Finder (macOS)
--
-- THIS ONLY WORKS IF YOU'RE NNNNNOOOOOOTTTTT USING ABSOLUTE PATHS,
-- BUT INSTEAD YOURE USING RELATIVE PATHS
--
-- If using absolute paths, use the default `gx` to open the image instead
vim.keymap.set("n", "<leader>if", function()
	local function get_image_path()
		-- Get the current line
		local line = vim.api.nvim_get_current_line()
		-- Pattern to match image path in Markdown
		local image_pattern = "%[.-%]%((.-)%)"
		-- Extract relative image path
		local _, _, image_path = string.find(line, image_pattern)
		return image_path
	end
	-- Get the image path
	local image_path = get_image_path()
	if image_path then
		-- Check if the image path starts with "http" or "https"
		if string.sub(image_path, 1, 4) == "http" then
			print("URL image, use 'gx' to open it in the default browser.")
		else
			-- Construct absolute image path
			local current_file_path = vim.fn.expand("%:p:h")
			local absolute_image_path = current_file_path .. "/" .. image_path
			-- Open the containing folder in Finder and select the image file
			local command = "open -R " .. vim.fn.shellescape(absolute_image_path)
			local success = vim.fn.system(command)
			if success == 0 then
				print("Opened image in Finder: " .. absolute_image_path)
			else
				print("Failed to open image in Finder: " .. absolute_image_path)
			end
		end
	else
		print("No image found under the cursor")
	end
end, { desc = "[P](macOS) Open image under cursor in Finder" })

-- ############################################################################

-- HACK: Upload images from Neovim to Imgur
-- https://youtu.be/Lzl_0SzbUBo
--
-- Delete image file under cursor using trash app (macOS)
vim.keymap.set("n", "<leader>id", function()
	local function get_image_path()
		local line = vim.api.nvim_get_current_line()
		local image_pattern = "%[.-%]%((.-)%)"
		local _, _, image_path = string.find(line, image_pattern)
		return image_path
	end
	local image_path = get_image_path()
	if not image_path then
		vim.api.nvim_echo({ { "No image found under the cursor", "WarningMsg" } }, false, {})
		return
	end
	if string.sub(image_path, 1, 4) == "http" then
		vim.api.nvim_echo({ { "URL image cannot be deleted from disk.", "WarningMsg" } }, false, {})
		return
	end
	local current_file_path = vim.fn.expand("%:p:h")
	local absolute_image_path = current_file_path .. "/" .. image_path
	-- Check if file exists
	if vim.fn.filereadable(absolute_image_path) == 0 then
		vim.api.nvim_echo(
			{ { "Image file does not exist:\n", "ErrorMsg" }, { absolute_image_path, "ErrorMsg" } },
			false,
			{}
		)
		return
	end
	if vim.fn.executable("trash") == 0 then
		vim.api.nvim_echo({
			{ "- Trash utility not installed. Make sure to install it first\n", "ErrorMsg" },
			{ "- In macOS run `brew install trash`\n", nil },
		}, false, {})
		return
	end
	-- Cannot see the popup as the cursor is on top of the image name, so saving
	-- its position, will move it to the top and then move it back
	local current_pos = vim.api.nvim_win_get_cursor(0) -- Save cursor position
	vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- Move to top
	vim.ui.select({ "yes", "no" }, { prompt = "Delete image file? " }, function(choice)
		vim.api.nvim_win_set_cursor(0, current_pos) -- Move back to image line
		if choice == "yes" then
			local success, _ = pcall(function()
				vim.fn.system({ "trash", vim.fn.fnameescape(absolute_image_path) })
			end)
			-- Verify if file still exists after deletion attempt
			if success and vim.fn.filereadable(absolute_image_path) == 1 then
				-- Try with rm if trash deletion failed
				-- Keep in mind that if deleting with `rm` the images won't go to the
				-- macos trash app, they'll be gone
				-- This is useful in case trying to delete imaes mounted in a network
				-- drive, like for my blogpost lamw25wmal
				--
				-- Cannot see the popup as the cursor is on top of the image name, so saving
				-- its position, will move it to the top and then move it back
				current_pos = vim.api.nvim_win_get_cursor(0) -- Save cursor position
				vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- Move to top
				vim.ui.select(
					{ "yes", "no" },
					{ prompt = "Trash deletion failed. Try with rm command? " },
					function(rm_choice)
						vim.api.nvim_win_set_cursor(0, current_pos) -- Move back to image line
						if rm_choice == "yes" then
							local rm_success, _ = pcall(function()
								vim.fn.system({ "rm", vim.fn.fnameescape(absolute_image_path) })
							end)
							if rm_success and vim.fn.filereadable(absolute_image_path) == 0 then
								vim.api.nvim_echo({
									{ "Image file deleted from disk using rm:\n", "Normal" },
									{ absolute_image_path, "Normal" },
								}, false, {})
								-- require("image").clear()
								vim.cmd("edit!")
								vim.cmd("normal! dd")
							else
								vim.api.nvim_echo({
									{ "Failed to delete image file with rm:\n", "ErrorMsg" },
									{ absolute_image_path, "ErrorMsg" },
								}, false, {})
							end
						end
					end
				)
			elseif success and vim.fn.filereadable(absolute_image_path) == 0 then
				vim.api.nvim_echo({
					{ "Image file deleted from disk:\n", "Normal" },
					{ absolute_image_path, "Normal" },
				}, false, {})
				-- require("image").clear()
				vim.cmd("edit!")
				vim.cmd("normal! dd")
			else
				vim.api.nvim_echo({
					{ "Failed to delete image file:\n", "ErrorMsg" },
					{ absolute_image_path, "ErrorMsg" },
				}, false, {})
			end
		else
			vim.api.nvim_echo({ { "Image deletion canceled.", "Normal" } }, false, {})
		end
	end)
end, { desc = "[P](macOS) Delete image file under cursor" })

-- ############################################################################

-- -- HACK: Upload images from Neovim to Imgur
-- -- https://youtu.be/Lzl_0SzbUBo
-- --
-- -- Refresh the images in the current buffer
-- -- Useful if you delete an actual image file and want to see the changes
-- -- without having to re-open neovim
-- vim.keymap.set("n", "<leader>ir", function()
--   -- First I clear the images
--   -- require("image").clear()
--   -- I'm using [[ ]] to escape the special characters in a command
--   -- vim.cmd([[lua require("image").clear()]])
--   -- Reloads the file to reflect the changes
--   vim.cmd("edit!")
--   print("Images refreshed")
-- end, { desc = "[P]Refresh images" })

-- ############################################################################

-- -- HACK: Upload images from Neovim to Imgur
-- -- https://youtu.be/Lzl_0SzbUBo
-- --
-- -- Set up a keymap to clear all images in the current buffer
-- vim.keymap.set("n", "<leader>ic", function()
--   -- This is the command that clears the images
--   -- require("image").clear()
--   -- I'm using [[ ]] to escape the special characters in a command
--   -- vim.cmd([[lua require("image").clear()]])
--   print("Images cleared")
-- end, { desc = "[P]Clear images" })

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

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Keymap to switch spelling language to English lamw25wmal
-- To save the language settings configured on each buffer, you need to add
-- "localoptions" to vim.opt.sessionoptions in the `lua/config/options.lua` file
-- vim.keymap.set("n", "<leader>msle", function()
-- 	vim.opt.spelllang = "en"
-- 	vim.cmd("echo 'Spell language set to English'")
-- end, { desc = "[P]Spelling language English" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Keymap to switch spelling language to Spanish lamw25wmal
-- vim.keymap.set("n", "<leader>msls", function()
-- 	vim.opt.spelllang = "es"
-- 	vim.cmd("echo 'Spell language set to Spanish'")
-- end, { desc = "[P]Spelling language Spanish" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Keymap to switch spelling language to both spanish and english lamw25wmal
-- vim.keymap.set("n", "<leader>mslb", function()
-- 	vim.opt.spelllang = "en,es"
-- 	vim.cmd("echo 'Spell language set to Spanish and English'")
-- end, { desc = "[P]Spelling language Spanish and English" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Show spelling suggestions / spell suggestions
-- NOTE: I changed this to accept the first spelling suggestion
vim.keymap.set("n", "<leader>mss", function()
	-- Simulate pressing "z=" with "m" option using feedkeys
	-- vim.api.nvim_replace_termcodes ensures "z=" is correctly interpreted
	-- 'm' is the {mode}, which in this case is 'Remap keys'. This is default.
	-- If {mode} is absent, keys are remapped.
	--
	-- I tried this keymap as usually with
	vim.cmd("normal! 1z=")
	-- But didn't work, only with nvim_feedkeys
	-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("z=", true, false, true), "m", true)
end, { desc = "[P]Spelling suggestions" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- markdown good, accept spell suggestion
-- Add word under the cursor as a good word
vim.keymap.set("n", "<leader>msg", function()
	vim.cmd("normal! zg")
	-- I do a write so that harper is updated
	vim.cmd("silent write")
end, { desc = "[P]Spelling add word to spellfile" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Undo zw, remove the word from the entry in 'spellfile'.
vim.keymap.set("n", "<leader>msu", function()
	vim.cmd("normal! zug")
end, { desc = "[P]Spelling undo, remove word from list" })

-- HACK: neovim spell multiple languages
-- https://youtu.be/uLFAMYFmpkE
--
-- Repeat the replacement done by |z=| for all matches with the replaced word
-- in the current window.
vim.keymap.set("n", "<leader>msr", function()
	-- vim.cmd(":spellr")
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":spellr\n", true, false, true), "m", true)
end, { desc = "[P]Spelling repeat" })

-- Surround the http:// url that the cursor is currently in with ``
vim.keymap.set("n", "gsu", function()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- Adjust for 0-index in Lua
	-- This makes the `s` optional so it matches both http and https
	local pattern = "https?://[^ ,;'\"<>%s)]*"
	-- Find the starting and ending positions of the URL
	local s, e = string.find(line, pattern)
	while s and e do
		if s <= col and e >= col then
			-- When the cursor is within the URL
			local url = string.sub(line, s, e)
			-- Update the line with backticks around the URL
			local new_line = string.sub(line, 1, s - 1) .. "`" .. url .. "`" .. string.sub(line, e + 1)
			vim.api.nvim_set_current_line(new_line)
			vim.cmd("silent write")
			return
		end
		-- Find the next URL in the line
		s, e = string.find(line, pattern, e + 1)
		-- Save the file to update trouble list
	end
	print("No URL found under cursor")
end, { desc = "[P]Add surrounding to URL" })

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

-- -- The following are related to indentation with tab, may not work perfectly
-- -- but get the job done
-- -- To indent in insert mode use C-T and C-D and in normal mode >> and <<
-- --
-- -- I disabled these as they interfere when jumpting to different sections of
-- -- my snippets, and probably other stuff, not a good idea
-- -- Maybe look for a different key, but not tab
-- --
-- -- Increase indent with tab in normal mode
-- vim.keymap.set("n", "<Tab>", function()
--   vim.cmd("normal >>")
-- end, { desc = "[P]Increase Indent" })
--
-- -- Decrease indent with tab in normal mode
-- vim.keymap.set("n", "<S-Tab>", function()
--   vim.cmd("normal <<")
-- end, { desc = "[P]Decrease Indent" })
--
-- -- Increase indent with tab in insert mode
-- vim.keymap.set("i", "<Tab>", function()
--   vim.api.nvim_input("<C-T>")
-- end, { desc = "[P]Increase Indent" })
--
-- -- Decrease indent with tab in insert mode
-- vim.keymap.set("i", "<S-Tab>", function()
--   vim.api.nvim_input("<C-D>")
-- end, { desc = "[P]Decrease Indent" })

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
