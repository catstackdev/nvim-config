-- Imgur image uploading functionality
local keymap = vim.keymap

-- Path to imgur credentials
local env_file_path = vim.fn.expand("~/Library/Mobile Documents/com~apple~CloudDocs/github/imgur_credentials")
local access_token_var = "IMGUR_ACCESS_TOKEN"
local refresh_token_var = "IMGUR_REFRESH_TOKEN"
local client_id_var = "IMGUR_CLIENT_ID"
local client_secret_var = "IMGUR_CLIENT_SECRET"

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