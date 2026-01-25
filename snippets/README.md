# HTTP/Hurl Snippets

VSCode-style snippets for HTTP API testing with rest.nvim and hurl.nvim.

## Files

- **`http.json`** - Snippets for `.http` and `.rest` files (rest.nvim)
- **`hurl.json`** - Snippets for `.hurl` files (hurl.nvim)

## HTTP Snippets (`http.json`)

### HTTP Methods
| Prefix | Description |
|--------|-------------|
| `get` | GET request |
| `post` | POST request with JSON body |
| `put` | PUT request with JSON body |
| `patch` | PATCH request with JSON body |
| `delete` | DELETE request |
| `head` | HEAD request |
| `options` | OPTIONS request |

### Headers
| Prefix | Description |
|--------|-------------|
| `auth` | Authorization: Bearer token |
| `authbasic` | Authorization: Basic |
| `json` | Content-Type: application/json |
| `form` | Content-Type: form-urlencoded |
| `multipart` | Content-Type: multipart/form-data |
| `acceptjson` | Accept: application/json |
| `header` | Custom header |
| `cookie` | Cookie header |

### CRUD Operations
| Prefix | Description |
|--------|-------------|
| `crud-create` | POST create operation |
| `crud-list` | GET all resources |
| `crud-get` | GET single resource |
| `crud-update` | PUT update operation |
| `crud-delete` | DELETE operation |
| `crud-all` | Complete CRUD suite |

### Utilities
| Prefix | Description |
|--------|-------------|
| `var` | Variable placeholder {{name}} |
| `query` | Query parameters |
| `graphql` | GraphQL query |
| `upload` | File upload |
| `local8000` | http://localhost:8000 |
| `local3000` | http://localhost:3000 |

## Hurl Snippets (`hurl.json`)

### Requests with Assertions
| Prefix | Description |
|--------|-------------|
| `get` | GET with JSONPath assertions |
| `post` | POST with captures and assertions |
| `put` | PUT with assertions |
| `delete` | DELETE request |

### Assertions
| Prefix | Description |
|--------|-------------|
| `assert` | JSONPath assertion |
| `assertexists` | Assert key exists |
| `asserttype` | Assert value type |
| `assertcount` | Assert array count |
| `status` | Assert status code |
| `header` | Assert response header |
| `duration` | Assert response time |
| `bodycontains` | Assert body contains text |

### Captures
| Prefix | Description |
|--------|-------------|
| `capture` | Capture from JSONPath |
| `captureheader` | Capture response header |
| `capturecookie` | Capture cookie value |

### Advanced
| Prefix | Description |
|--------|-------------|
| `crud-test` | Complete CRUD test suite |
| `auth-flow` | Login + authenticated request |
| `query` | Query string params block |
| `formdata` | Form data params block |
| `options` | Request options block |
| `retry` | Retry configuration |

## Usage

In any `.http`, `.rest`, or `.hurl` file:

1. Type a prefix (e.g., `post`)
2. Press `<Tab>` or `<C-Space>` to expand
3. Use `<Tab>` to jump between placeholders
4. Fill in the values

### Example

```http
# Type: post<Tab>
# Expands to:
POST http://localhost:8000/endpoint
Content-Type: application/json

{
  "key": "value"
}
HTTP 200
```

## Adding Custom Snippets

Edit the JSON files to add your own snippets:

```json
{
  "My Custom Snippet": {
    "prefix": "mysnip",
    "body": [
      "GET ${1:url}",
      "HTTP ${2:200}"
    ],
    "description": "My custom snippet description"
  }
}
```

## Troubleshooting

If snippets don't appear:

1. Restart Neovim: `:qa` then reopen
2. Check LuaSnip is loading: `:lua print(vim.inspect(require('luasnip').get_snippets()))`
3. Verify file is in snippets directory: `:lua print(vim.fn.stdpath('config') .. '/snippets')`
4. Check nvim-cmp config loads VSCode snippets from this directory

## Related

- [rest.nvim documentation](https://github.com/rest-nvim/rest.nvim)
- [hurl.nvim documentation](https://github.com/jellydn/hurl.nvim)
- [Hurl documentation](https://hurl.dev)
