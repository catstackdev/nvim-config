return {
	"m4xshen/hardtime.nvim",
	enabled = true,
	dependencies = { "MunifTanjim/nui.nvim" },
	-- Was told to use this event by m4xshen himself, in discord
	-- https://discord.com/channels/1323810827220029441/1371572869838012487/1371660878344097832
	event = "BufEnter",
	opts = function(_, opts)
		-- gj/gk are remapped for heading navigation (see keymaps-plugin/headings.lua);
		-- don't nag about a key hardtime doesn't know has a different meaning here
		opts.restricted_keys = opts.restricted_keys or {}
		opts.restricted_keys["gj"] = false
		opts.restricted_keys["gk"] = false

		-- y/Y/p/P are in hardtime's default resetting_keys, so it installs its own
		-- expr-mapping wrapper on them too. Since hardtime loads on BufEnter (after
		-- yanky.nvim's BufReadPre/BufNewFile), that wrapper overwrites yanky's
		-- <Plug>(YankyYank)/<Plug>(YankyPutAfter) remaps, silently disabling the
		-- yank-ring. Opt them out so hardtime never touches these keys.
		opts.resetting_keys = opts.resetting_keys or {}
		opts.resetting_keys["y"] = false
		opts.resetting_keys["Y"] = false
		opts.resetting_keys["p"] = false
		opts.resetting_keys["P"] = false

		opts.max_count = 30
		return opts
	end,
}
