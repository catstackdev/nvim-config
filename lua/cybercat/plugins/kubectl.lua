-- config using run--kubectl config view
return {
	"ramilito/kubectl.nvim",

	version = "2.*",
	-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
	-- build = 'cargo build --release',
	enabled = false,
	dependencies = "saghen/blink.download",
	config = function()
		require("kubectl").setup({
			auto_refresh = {
				enabled = true,
				interval = 3000, -- milliseconds
			},
			diff = {
				bin = "kubediff", -- or any other binary
			},
			namespace = "All",
			namespace_fallback = {}, -- If you have limited access you can list all the namespaces here
			notifications = {
				enabled = true,
				verbose = false,
				blend = 100,
			},
			hints = true,
			context = true,
			float_size = {
				-- Almost fullscreen:
				-- width = 1.0,
				-- height = 0.95, -- Setting it to 1 will cause bottom to be cutoff by statuscolumn

				-- For more context aware size:
				width = 0.9,
				height = 0.8,

				-- Might need to tweak these to get it centered when float is smaller
				col = 10,
				row = 5,
			},
			obj_fresh = 0, -- highlight if creation newer than number (in minutes)
			mappings = {
				-- exit = "<leader>uk",
			},
		})
	end,
}
