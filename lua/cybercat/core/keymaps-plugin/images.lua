-- Image pasting, renaming, and management
local keymap = vim.keymap

-- Configuration for image storage path
local IMAGE_STORAGE_PATH = "img/imgs"

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