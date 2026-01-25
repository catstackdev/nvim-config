local M = {}

function M.clear_bg(groups)
	for _, group in ipairs(groups) do
		vim.cmd("hi " .. group .. " guibg=NONE ctermbg=NONE")
	end
end

function M.setup_transparency_autocmd(pattern, groups)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = pattern,
		callback = function()
			M.clear_bg(groups)
		end,
	})
end

function M.setup_event_autocmd(events, groups)
	for _, event in ipairs(events) do
		vim.api.nvim_create_autocmd(event, {
			callback = function()
				M.clear_bg(groups)
			end,
		})
	end
end

function M.get_nvimtree_groups()
	return {
		"NvimTreeNormal",
		"NvimTreeNormalNC",
		"NvimTreeVertSplit",
		"NvimTreeEndOfBuffer",
		"NvimTreeFolderName",
		"NvimTreeOpenedFolderName",
		"NvimTreeFolderIcon",
		"NvimTreeGitDeleted",
		"NvimTreeGitModified",
		"NvimTreeGitNew",
	}
end

function M.get_neotree_groups()
	return {
		"NeoTreeNormal",
		"NeoTreeNormalNC",
		"NeoTreeFloatBorder",
		"NeoTreeFloatTitle",
		"NeoTreeGitAdded",
		"NeoTreeGitDeleted",
		"NeoTreeGitModified",
		"NeoTreeRootName",
		"NeoTreeIndentMarker",
		"NeoTreeDirectoryName",
		"NeoTreeFileName",
	}
end

function M.get_minifiles_groups()
	return {
		"Normal",
		"NormalNC",
		"FloatBorder",
		"WinSeparator",
	}
end

function M.get_mason_groups()
	return {
		"MasonNormal",
		"MasonNormalFloat",
		"MasonBorder",
	}
end

function M.get_lazy_groups()
	return {
		"NormalFloat",
		"FloatBorder",
		"WinSeparator",
		"Normal",
		"NormalNC",
		"FloatBorder",
		"WinSeparator",
	}
end

function M.get_telescope_groups()
	return {
		"NormalFloat",
		"FloatBorder",
		"TelescopeNormal",
		"TelescopePromptNormal",
		"TelescopeResultsNormal",
		"TelescopePreviewNormal",
		"TelescopeBorder",
	}
end

function M.get_whichkey_groups()
	return {
		"NormalFloat",
		"FloatBorder",
		"WhichKeyNormal",
		"WhichKeyBorder",
		"WhichKeyFloat",
	}
end

return M
