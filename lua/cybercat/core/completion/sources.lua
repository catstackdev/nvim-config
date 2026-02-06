local M = {}

function M.get_default_sources()
	return {
		{ name = "copilot", group_index = 1, keyword_length = 0 },
		{ name = "codeium", group_index = 1, keyword_length = 0 },
		{ name = "supermaven", group_index = 1, keyword_length = 0 },
		{ name = "nvim_lsp", group_index = 2 },
		{ name = "nvim_lsp_signature_help", group_index = 2 },
		{ name = "lsp_sources", group_index = 2 },
		{ name = "luasnip", group_index = 3 },
		{ name = "tailwindcss-colorizer-cmp", group_index = 4 },
		{ name = "npm", group_index = 4, keyword_length = 4 },
		{ name = "buffer", group_index = 5 },
		{ name = "path", group_index = 5 },
		{ name = "git", group_index = 6 },
		{ name = "emoji", group_index = 6 },
		{ name = "spell", group_index = 7, keyword_length = 3 },
	}
end

function M.get_text_sources()
	return {
		{ name = "dictionary", keyword_length = 2, group_index = 1 },
		{ name = "spell", keyword_length = 2, group_index = 1 },
		{ name = "buffer", keyword_length = 2, group_index = 2 },
		{ name = "path", group_index = 3 },
		{ name = "nvim_lsp", group_index = 4 },
		{ name = "luasnip", group_index = 4 },
	}
end

function M.get_search_sources()
	return {
		{ name = "buffer" },
		{ name = "spell" },
	}
end

function M.get_gitcommit_sources()
	return {
		{ name = "git" },
		{ name = "spell" },
		{ name = "dictionary" },
		{ name = "emoji" },
		{ name = "buffer" },
	}
end

function M.get_http_sources()
	return {
		{ name = "buffer" },
		{ name = "path" },
		{ name = "nvim_lsp" },
	}
end

function M.get_go_sources()
	return {
		{ name = "nvim_lsp", group_index = 1, priority = 1000 },
		{ name = "nvim_lsp_signature_help", group_index = 1 },
		{ name = "luasnip", group_index = 2 },
		{ name = "buffer", group_index = 3 },
		{ name = "path", group_index = 3 },
		-- AI disabled for Go to prioritize LSP
		-- { name = "copilot", group_index = 4, keyword_length = 2 },
		-- { name = "codeium", group_index = 4, keyword_length = 2 },
		-- { name = "supermaven", group_index = 4, keyword_length = 2 },
	}
end

return M
