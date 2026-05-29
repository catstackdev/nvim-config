return {
	filetypes = { "wgsl" },
	settings = {
		["wgsl-analyzer"] = {
			-- customImports = {},                  -- map your /include/raymarch.glsl-style helpers if you add WGSL includes
			diagnostics = {
				typeErrors = true,
				nagaParsing = true, -- runs naga front-end
				nagaValidation = true, -- runs naga IR validation
				nagaVersion = "main",
			},
			inlayHints = {
				enabled = true,
				typeHints = true, -- shows inferred f32/vec2<f32> etc.
				parameterHints = true,
				structLayoutHints = true, -- shows byte offsets
				typeVerbosity = "compact",
			},
		},
	},
}
