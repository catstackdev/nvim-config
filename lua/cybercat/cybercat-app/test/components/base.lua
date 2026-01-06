local M = {}
M.__index = M

-- Constructor
function M:new(opts)
	local instance = setmetatable({}, self)
	instance:init(opts or {})
	return instance
end

-- Initializer
function M:init(opts)
	self.opts = vim.deepcopy(opts)
	self.mounted = false
	self._events = {}
end

-- Default implementations
function M:mount()
	-- Can be overridden by child components
end

function M:unmount()
	-- Can be overridden by child components
end

-- Visibility control
function M:show()
	if not self.mounted then
		local ok, err = pcall(function()
			self:mount()
			self.mounted = true
		end)
		if not ok then
			vim.notify("Failed to show component: " .. err, vim.log.levels.ERROR)
			return nil
		end
	end
	return self
end

function M:hide()
	if self.mounted then
		local ok, err = pcall(function()
			self:unmount()
			self.mounted = false
		end)
		if not ok then
			vim.notify("Failed to hide component: " .. err, vim.log.levels.ERROR)
			return nil
		end
	end
	return self
end

function M:toggle()
	return self.mounted and self:hide() or self:show()
end

return M
