-- Command builders for HTTP/Hurl testing
-- Constructs hurl, curl, and other HTTP testing commands

local env = require("cybercat.utils.http.env")

local M = {}

--- Build hurl command with options
--- @param file string Path to .hurl file
--- @param opts table|nil Options: { test = bool, verbose = bool, to_entry = number, env_file = string }
--- @return string command Complete hurl command
function M.build_hurl_command(file, opts)
	opts = opts or {}
	
	local cmd = "hurl"
	
	-- Add test mode
	if opts.test then
		cmd = cmd .. " --test"
	end
	
	-- Add verbose mode
	if opts.verbose then
		cmd = cmd .. " --verbose"
	elseif opts.very_verbose then
		cmd = cmd .. " --very-verbose"
	end
	
	-- Add to-entry (run up to specific entry)
	if opts.to_entry and opts.to_entry > 0 then
		cmd = cmd .. " --to-entry " .. opts.to_entry
	end
	
	-- Add environment/variables file
	local env_file = opts.env_file or env.find_env_file()
	if env_file and env_file ~= "" then
		cmd = cmd .. " --variables-file " .. env_file
	end
	
	-- Add custom variables
	if opts.variables then
		for key, value in pairs(opts.variables) do
			cmd = cmd .. string.format(" --variable %s=%s", key, value)
		end
	end
	
	-- Add the file
	cmd = cmd .. " " .. file
	
	return cmd
end

--- Build curl command for a specific HTTP request
--- @param url string Request URL
--- @param opts table|nil Options: { method = string, headers = table, body = string }
--- @return string command Complete curl command
function M.build_curl_command(url, opts)
	opts = opts or {}
	
	local cmd = "curl"
	
	-- Add method
	if opts.method and opts.method ~= "GET" then
		cmd = cmd .. " -X " .. opts.method
	end
	
	-- Add headers
	if opts.headers then
		for key, value in pairs(opts.headers) do
			cmd = cmd .. string.format(" -H '%s: %s'", key, value)
		end
	end
	
	-- Add body
	if opts.body then
		cmd = cmd .. " -d '" .. opts.body .. "'"
	end
	
	-- Add URL
	cmd = cmd .. " '" .. url .. "'"
	
	return cmd
end

--- Find entry number at cursor position in hurl file
--- Counts ### markers before cursor to determine which request entry we're in
--- @return number entry_num Entry number (1-indexed)
function M.find_entry_at_cursor()
	local line = vim.fn.line(".")
	local entry_num = 1
	
	for i = 1, line do
		local line_text = vim.fn.getline(i)
		if string.match(line_text, "^###%s") then
			if i <= line then
				entry_num = entry_num + 1
			end
		end
	end
	
	-- Adjust because we start counting from 1, but hurl uses 0-based?
	entry_num = entry_num - 1
	if entry_num < 1 then
		entry_num = 1
	end
	
	return entry_num
end

--- Get current file path
--- @return string file Expanded file path
function M.get_current_file()
	return vim.fn.expand("%")
end

--- Build command to run hurl file
--- @param opts table|nil Options for build_hurl_command
--- @return string command
function M.run_hurl_file(opts)
	local file = M.get_current_file()
	return M.build_hurl_command(file, opts)
end

--- Build command to run hurl at cursor
--- @param opts table|nil Options for build_hurl_command
--- @return string command
function M.run_hurl_at_cursor(opts)
	opts = opts or {}
	local file = M.get_current_file()
	local entry_num = M.find_entry_at_cursor()
	
	opts.to_entry = entry_num
	
	return M.build_hurl_command(file, opts)
end

--- Build command to test hurl file
--- @param verbose boolean|nil Whether to use verbose mode
--- @return string command
function M.test_hurl_file(verbose)
	local file = M.get_current_file()
	return M.build_hurl_command(file, { 
		test = true, 
		very_verbose = verbose 
	})
end

return M
