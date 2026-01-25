local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node

return {
	-- GET request
	s("get", {
		t("### "),
		i(1, "Request Name"),
		t({ "", "GET {{baseUrl}}/" }),
		i(2, "endpoint"),
		t({ "", "" }),
		i(0),
	}),

	-- POST request
	s("post", {
		t("### "),
		i(1, "Request Name"),
		t({ "", "POST {{baseUrl}}/" }),
		i(2, "endpoint"),
		t({ "", "Content-Type: application/json", "", "{", '  "' }),
		i(3, "key"),
		t('": "'),
		i(4, "value"),
		t({ '"', "}" }),
		t({ "", "" }),
		i(0),
	}),

	-- PUT request
	s("put", {
		t("### "),
		i(1, "Update Request"),
		t({ "", "PUT {{baseUrl}}/" }),
		i(2, "endpoint"),
		t({ "", "Content-Type: application/json", "", "{", '  "' }),
		i(3, "key"),
		t('": "'),
		i(4, "value"),
		t({ '"', "}" }),
		t({ "", "" }),
		i(0),
	}),

	-- PATCH request
	s("patch", {
		t("### "),
		i(1, "Partial Update"),
		t({ "", "PATCH {{baseUrl}}/" }),
		i(2, "endpoint"),
		t({ "", "Content-Type: application/json", "", "{", '  "' }),
		i(3, "key"),
		t('": "'),
		i(4, "value"),
		t({ '"', "}" }),
		t({ "", "" }),
		i(0),
	}),

	-- DELETE request
	s("delete", {
		t("### "),
		i(1, "Delete Request"),
		t({ "", "DELETE {{baseUrl}}/" }),
		i(2, "endpoint"),
		t({ "", "" }),
		i(0),
	}),

	-- GET with Authorization
	s("getauth", {
		t("### "),
		i(1, "Authenticated Request"),
		t({ "", "GET {{baseUrl}}/" }),
		i(2, "endpoint"),
		t({ "", "Authorization: Bearer {{apiKey}}", "" }),
		i(0),
	}),

	-- POST with Authorization
	s("postauth", {
		t("### "),
		i(1, "Authenticated POST"),
		t({ "", "POST {{baseUrl}}/" }),
		i(2, "endpoint"),
		t({ "", "Authorization: Bearer {{apiKey}}", "Content-Type: application/json", "", "{", '  "' }),
		i(3, "key"),
		t('": "'),
		i(4, "value"),
		t({ '"', "}" }),
		t({ "", "" }),
		i(0),
	}),

	-- GET with query parameters
	s("getquery", {
		t("### "),
		i(1, "Request with Query Params"),
		t({ "", "GET {{baseUrl}}/" }),
		i(2, "endpoint"),
		t("?"),
		i(3, "param"),
		t("="),
		i(4, "value"),
		t({ "", "" }),
		i(0),
	}),

	-- Complete API test template
	s("apitest", {
		t("### "),
		i(1, "API Test"),
		t({ "", "", "# Get all items", "GET {{baseUrl}}/" }),
		i(2, "endpoint"),
		t({ "", "Authorization: Bearer {{apiKey}}", "", "###", "", "# Create new item", "POST {{baseUrl}}/" }),
		i(3, "endpoint"),
		t({ "", "Authorization: Bearer {{apiKey}}", "Content-Type: application/json", "", "{", '  "name": "' }),
		i(4, "test"),
		t({ '"', "}" }),
		t({ "", "" }),
		i(0),
	}),
}
