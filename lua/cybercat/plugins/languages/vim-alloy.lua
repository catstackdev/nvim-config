-- https://github.com/grafana/vim-alloy
--
-- Syntax highlighting for Grafana Alloy (.alloy) config files

return {
	"grafana/vim-alloy",
	ft = "alloy",
	init = function()
		vim.filetype.add({ extension = { alloy = "alloy" } })
	end,
}
