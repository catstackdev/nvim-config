# HTTP/API Testing in Neovim

Complete guide to testing HTTP APIs directly in Neovim using rest.nvim and hurl.nvim.

## Overview

Two complementary plugins for HTTP testing:

- **rest.nvim** - Quick manual testing with `.http` files (like VS Code REST Client)
- **hurl.nvim** - Automated testing with `.hurl` files (assertions, variable capture, CI/CD)

## Quick Start

### For Manual Testing (rest.nvim)

1. Create a `.http` file:
```http
GET http://localhost:8000/api/users
```

2. Press `<leader>rr` to run the request
3. View formatted response in split window

### For Automated Testing (hurl.nvim)

1. Create a `.hurl` file:
```hurl
GET http://localhost:8000/api/users
HTTP 200
[Asserts]
jsonpath "$.users" count > 0
```

2. Press `<leader>ht` to run all tests
3. See pass/fail summary

## Installation

Already configured in your setup! Required tools:

```bash
# Hurl (for .hurl files)
brew install hurl

# jq (for JSON formatting)
brew install jq

# Optional: prettier (for HTML formatting)
npm install -g prettier
```

## Keymaps Reference

### REST Client (`.http`, `.rest` files)

| Keymap | Description |
|--------|-------------|
| `<leader>rr` | Run request under cursor |
| `<leader>rl` | Run last request |
| `<leader>ro` | Open result pane |
| `<leader>re` | Select environment |
| `<leader>rc` | Copy as cURL command |
| `<leader>rL` | Show logs |
| `<leader>rt` | Toggle view |
| `<leader>rf` | Find requests (Telescope) |

**In result window:**
| Keymap | Description |
|--------|-------------|
| `q` | Close window |
| `<Esc>` | Close window |
| `<Tab>` | Re-run last request |

### Hurl (`.hurl` files)

| Keymap | Description |
|--------|-------------|
| `<leader>hr` | Run entire file (show last response) |
| `<leader>ha` | Run request at cursor |
| `<leader>ht` | Test mode (show pass/fail summary) ⭐ |
| `<leader>hT` | Test mode with full verbose output |
| `<leader>hv` | Toggle verbose mode |
| `<leader>he` | Manage variables |

**In terminal window:**
| Keymap | Description |
|--------|-------------|
| `q` | Close terminal |
| `<Esc>` | Close terminal |

## Environment Variables

### For rest.nvim (`.http` files)

Create `.env.local`:
```bash
baseUrl=http://localhost:8000
apiKey=your-api-key
```

Use in requests:
```http
GET {{baseUrl}}/api/users
Authorization: Bearer {{apiKey}}
```

### For hurl.nvim (`.hurl` files)

Create `hurl.env` or `test/api/hurl.env`:
```bash
baseUrl=http://localhost:8000
authToken=Bearer abc123
```

Use in tests:
```hurl
GET {{baseUrl}}/api/protected
Authorization: {{authToken}}
```

**Auto-detection:** The plugin automatically finds env files:
1. `hurl.env` (current directory)
2. `test/api/hurl.env` (test directory)
3. `.env` (fallback)

## Snippets

Type these prefixes and press `<Tab>` to expand:

### Common HTTP Snippets
- `get` - GET request
- `post` - POST with JSON body
- `crud-all` - Complete CRUD operation suite
- `auth` - Authorization header
- `local8000` - http://localhost:8000

### Hurl Test Snippets
- `get` - GET with assertions
- `post` - POST with capture and assertions
- `assert` - JSONPath assertion
- `capture` - Capture variable from response
- `crud-test` - Complete CRUD test suite

See `snippets/README.md` for full list.

## Examples

### Example 1: Simple GET Request

**File: `api/test.http`**
```http
### Get all users
GET http://localhost:8000/users
```

**Run:** Put cursor on the request, press `<leader>rr`

---

### Example 2: POST with JSON Body

**File: `api/create-user.http`**
```http
### Create new user
POST http://localhost:8000/users
Content-Type: application/json

{
  "name": "Alice",
  "email": "alice@example.com"
}
```

**Run:** `<leader>rr`

---

### Example 3: Authenticated Request

**File: `.env.local`**
```bash
baseUrl=http://localhost:8000
token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**File: `api/protected.http`**
```http
### Access protected endpoint
GET {{baseUrl}}/api/protected
Authorization: Bearer {{token}}
```

**Run:** `<leader>re` to select environment, then `<leader>rr`

---

### Example 4: Complete Test Suite (Hurl)

**File: `test/api/users.hurl`**
```hurl
### Create user
POST http://localhost:8000/users
Content-Type: application/json
{
  "name": "Alice",
  "email": "alice@example.com"
}
HTTP 201
[Captures]
user_id: jsonpath "$.id"
[Asserts]
jsonpath "$.name" == "Alice"
jsonpath "$.id" exists

### Get user by ID
GET http://localhost:8000/users/{{user_id}}
HTTP 200
[Asserts]
jsonpath "$.id" == {{user_id}}
jsonpath "$.name" == "Alice"

### Delete user
DELETE http://localhost:8000/users/{{user_id}}
HTTP 204
```

**Run:** `<leader>ht` to see test results

---

### Example 5: CRUD with Variables

**File: `test/api/hurl.env`**
```bash
baseUrl=http://localhost:8000
```

**File: `test/api/crud.hurl`**
```hurl
### Create
POST {{baseUrl}}/items
Content-Type: application/json
{"name": "Item 1"}
HTTP 201
[Captures]
item_id: jsonpath "$.id"

### Read
GET {{baseUrl}}/items/{{item_id}}
HTTP 200

### Update
PUT {{baseUrl}}/items/{{item_id}}
Content-Type: application/json
{"name": "Updated Item"}
HTTP 200

### Delete
DELETE {{baseUrl}}/items/{{item_id}}
HTTP 204
```

**Run:** `<leader>ht`

## Tips & Tricks

### 1. Quick localhost URLs

Use snippets:
- `local8000` → `http://localhost:8000`
- `local3000` → `http://localhost:3000`

### 2. Copy as cURL

In a `.http` file, press `<leader>rc` to copy the request as a cURL command.

### 3. Test individual requests

In `.hurl` files, use `<leader>ha` to test just the request at cursor.

### 4. Chain requests

Hurl can capture values from one request and use in the next:
```hurl
POST /login
{"username": "admin"}
HTTP 200
[Captures]
token: jsonpath "$.token"

GET /protected
Authorization: Bearer {{token}}
HTTP 200
```

### 5. Performance testing

Add duration assertions:
```hurl
GET /api/fast
HTTP 200
[Asserts]
duration < 100  # Must respond in under 100ms
```

### 6. Run from command line

```bash
# Run all tests
hurl --test --variables-file test/api/hurl.env test/api/*.hurl

# Run specific file
hurl --test test/api/users.hurl

# Different environment
hurl --test --variable baseUrl=https://staging.api.com test/api/users.hurl
```

## Troubleshooting

### Snippets not appearing

1. Check LuaSnip is loaded: `:Lazy`
2. Restart Neovim
3. Verify: `:lua print(vim.inspect(require('luasnip').get_snippets('http')))`

### "hurl: command not found"

Install Hurl:
```bash
brew install hurl
```

### Variables not working in Hurl

1. Check env file exists: `:!ls test/api/hurl.env`
2. Verify format:
   ```bash
   baseUrl=http://localhost:8000
   # No spaces around =
   # No quotes needed
   ```
3. Run with explicit env file:
   ```bash
   hurl --variables-file test/api/hurl.env file.hurl
   ```

### Terminal won't close with 'q'

The terminal autocmd might not be set. Restart Neovim or run:
```vim
:lua require("cybercat.utils.http").setup()
```

### No syntax highlighting in .hurl files

Install treesitter parser:
```vim
:TSInstall hurl
```

## Related Documentation

- [rest.nvim GitHub](https://github.com/rest-nvim/rest.nvim)
- [hurl.nvim GitHub](https://github.com/jellydn/hurl.nvim)
- [Hurl Official Docs](https://hurl.dev)
- [HTTP Status Codes](https://httpstatuses.com)
- [JSONPath Syntax](https://goessner.net/articles/JsonPath/)

## Advanced: CI/CD Integration

### GitHub Actions Example

```yaml
name: API Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Hurl
        run: |
          curl -LO https://github.com/Orange-OpenSource/hurl/releases/download/latest/hurl_amd64.deb
          sudo dpkg -i hurl_amd64.deb
      
      - name: Start API server
        run: |
          uvicorn main:app &
          sleep 2
      
      - name: Run API tests
        run: hurl --test --variables-file test/api/hurl.env test/api/*.hurl
```

Your API tests are now part of your CI pipeline! 🚀
