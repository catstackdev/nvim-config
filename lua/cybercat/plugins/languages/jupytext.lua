-- jupytext.nvim: open/edit .ipynb notebooks as plain text in Neovim.
-- With style = "percent", cells become `# %%` blocks in a normal Python buffer,
-- so molten (languages/molten.lua) can run them and LSP/ruff/pyright work as usual.
-- Converts back to .ipynb on save. Requires the `jupytext` python package in the
-- g:python3_host_prog interpreter (already installed).
return {
	"GCBallesteros/jupytext.nvim",
	lazy = false, -- must be ready before a .ipynb is opened
	opts = {
		style = "percent",
		output_extension = "auto",
		force_ft = nil,
	},
}
