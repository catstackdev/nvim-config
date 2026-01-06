local M = {
	_ui = nil,
	_jobs = {},
	config = {
		model = "deepseek-coder:6.7b",
		temperature = 0.3,
		endpoint = "http://localhost:11434/api/generate",
		timeout = 30000, -- 30 seconds
	},
}

function M.inject_ui(ui)
	M._ui = ui
end

function M.init()
	-- Initialize connection pool or other resources
end

function M.query(prompt, opts)
	opts = opts or {}
	local buf_id = opts.buf_id

	if not prompt or #prompt == 0 then
		return
	end

	local json_body = vim.json.encode({
		model = opts.model or M.config.model,
		prompt = prompt,
		stream = true, -- Now using streaming
		options = {
			temperature = opts.temperature or M.config.temperature,
		},
	})

	-- Create a dedicated buffer for streaming if none provided
	if not buf_id and M._ui then
		buf_id = M._ui.create_stream_buffer()
	end

	local job_id = vim.fn.jobstart({
		"curl",
		"-s",
		"-N",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"-d",
		json_body,
		M.config.endpoint,
	}, {
		stdout_buffered = false,
		on_stdout = function(_, data, _)
			if not data then
				return
			end
			for _, chunk in ipairs(data) do
				local ok, decoded = pcall(vim.json.decode, chunk)
				if ok and decoded and decoded.response then
					M._handle_stream_chunk(buf_id, decoded.response, decoded.done)
				end
			end
		end,
		on_stderr = function(_, err, _)
			M._handle_error(buf_id, table.concat(err, " "))
		end,
		on_exit = function(_, exit_code, _)
			if exit_code ~= 0 then
				M._handle_error(buf_id, "API exited with code " .. exit_code)
			end
		end,
	})

	if job_id > 0 then
		M._jobs[job_id] = {
			buf_id = buf_id,
			start_time = vim.loop.now(),
		}

		-- Timeout handling
		vim.defer_fn(function()
			if M._jobs[job_id] then
				vim.fn.jobstop(job_id)
				M._handle_error(buf_id, "API request timed out")
				M._jobs[job_id] = nil
			end
		end, M.config.timeout)
	else
		M._handle_error(buf_id, "Failed to start API request")
	end
end

function M._handle_stream_chunk(buf_id, chunk, done)
	if M._ui then
		M._ui.append_stream(buf_id, chunk, done)
	end
end

function M._handle_error(buf_id, err)
	if M._ui then
		M._ui.append_error(buf_id, err)
	end
end

function M.cancel_all()
	for job_id, _ in pairs(M._jobs) do
		vim.fn.jobstop(job_id)
	end
	M._jobs = {}
end

return M
