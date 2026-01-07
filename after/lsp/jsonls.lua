-- JSON Language Server
return {
	settings = {
		json = {
			-- Use schemastore if available, otherwise use empty schemas
			schemas = (function()
				local ok, schemastore = pcall(require, "schemastore")
				if ok then
					return schemastore.json.schemas()
				end
				return {}
			end)(),
			validate = { enable = true },
			format = {
				enable = true,
			},
		},
	},
}
