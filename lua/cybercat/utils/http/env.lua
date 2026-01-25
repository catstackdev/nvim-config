-- Environment file handling utilities for HTTP/Hurl testing
-- Finds and loads environment variable files

local M = {}

--- Find environment file for HTTP/Hurl testing
--- Searches in order: hurl.env, test/api/hurl.env, .env
--- @param search_paths table|nil Optional custom search paths
--- @return string|nil env_file Path to env file or nil if not found
function M.find_env_file(search_paths)
	local default_paths = {
		"hurl.env",
		"test/api/hurl.env",
		"api-tests/.env.local",
		".env",
		".env.local",
	}
	
	local paths = search_paths or default_paths
	
	for _, path in ipairs(paths) do
		local env_file = vim.fn.findfile(path, ".;")
		if env_file ~= "" then
			return env_file
		end
	end
	
	return nil
end

--- Get base URL from environment file or return default
--- @param env_file string|nil Path to env file
--- @param default string|nil Default URL (defaults to http://localhost:8000)
--- @return string base_url
function M.get_base_url(env_file, default)
	local default_url = default or "http://localhost:8000"
	
	if not env_file or env_file == "" then
		return default_url
	end
	
	local file = io.open(env_file, "r")
	if not file then
		return default_url
	end
	
	for line in file:lines() do
		local key, value = line:match("^(%w+)=(.+)$")
		if key == "baseUrl" or key == "base_url" then
			file:close()
			return value
		end
	end
	
	file:close()
	return default_url
end

--- Create default environment file if it doesn't exist
--- @param filepath string Path where to create the file
--- @param base_url string|nil Base URL to use (defaults to localhost:8000)
function M.create_default_env_file(filepath, base_url)
	local url = base_url or "http://localhost:8000"
	local content = string.format([[# API Testing Environment Variables
baseUrl=%s

# Add more variables as needed:
# apiKey=your-api-key
# authToken=Bearer your-token
]], url)
	
	local file = io.open(filepath, "w")
	if file then
		file:write(content)
		file:close()
		vim.notify("Created environment file: " .. filepath, vim.log.levels.INFO)
		return true
	else
		vim.notify("Failed to create environment file: " .. filepath, vim.log.levels.ERROR)
		return false
	end
end

--- Parse environment file and return variables as table
--- @param env_file string Path to env file
--- @return table variables Key-value pairs of environment variables
function M.parse_env_file(env_file)
	local variables = {}
	
	if not env_file or env_file == "" then
		return variables
	end
	
	local file = io.open(env_file, "r")
	if not file then
		return variables
	end
	
	for line in file:lines() do
		-- Skip comments and empty lines
		if not line:match("^%s*#") and not line:match("^%s*$") then
			local key, value = line:match("^(%w+)=(.+)$")
			if key and value then
				variables[key] = value
			end
		end
	end
	
	file:close()
	return variables
end

return M
