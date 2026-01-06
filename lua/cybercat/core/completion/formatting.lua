local M = {}

local function setup_formatting()
	local lspkind = require("lspkind")
	return lspkind.cmp_format({
		mode = "symbol_text",
		maxwidth = 50,
		ellipsis_char = "...",
		menu = "",
		before = function(entry, vim_item)
			if entry.source.name == "copilot" then
				vim_item.kind = ""
			elseif entry.source.name == "supermaven" then
				vim_item.kind = "󰚩"
			-- elseif entry.source.name == "cursor_agent" then
			-- 	vim_item.kind = ""
			elseif entry.source.name == "codeium" then
				vim_item.kind = ""
			elseif entry.source.name == "nvim_lsp" then
				vim_item.kind = ""
			elseif entry.source.name == "nvim_lsp_signature_help" then
				vim_item.kind = ""
			elseif entry.source.name == "lsp_sources" then
				vim_item.kind = ""
			elseif entry.source.name == "luasnip" then
				vim_item.kind = ""
			elseif entry.source.name == "buffer" then
				vim_item.kind = ""
			elseif entry.source.name == "path" then
				vim_item.kind = ""
			elseif entry.source.name == "npm" then
				vim_item.kind = ""
			elseif entry.source.name == "tailwindcss-colorizer-cmp" then
				vim_item.kind = ""
			elseif entry.source.name == "git" then
				vim_item.kind = ""
			elseif entry.source.name == "emoji" then
				vim_item.kind = "󰞅"
			elseif entry.source.name == "spell" then
				vim_item.kind = "󰓆"
			elseif entry.source.name == "dictionary" then
				vim_item.kind = ""
			else
				-- Default icon for any other source
				vim_item.kind = ""
			end

			return vim_item
		end,
	})
end

function M.get_formatting()
	return {
		format = setup_formatting(),
	}
end

return M
