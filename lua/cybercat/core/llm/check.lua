local M = {}

function M.verify(callback)
	local retries = 0
	local max_retries = 3

	local function attempt()
		local handle = io.popen("curl -s -m 2 -o /dev/null -w '%{http_code}' http://localhost:11434 2>&1")
		local result = handle:read("*a")
		handle:close()

		if result:match("200") then
			callback(true)
		elseif retries < max_retries then
			retries = retries + 1
			vim.defer_fn(attempt, 1000) -- Retry after 1 second
		else
			callback(false)
		end
	end

	attempt()
end

function M.is_available()
	local handle = io.popen("which ollama 2>/dev/null")
	local result = handle:read("*a")
	handle:close()
	return result ~= ""
end

return M
