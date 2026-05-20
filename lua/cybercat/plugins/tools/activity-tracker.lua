-- Logs file opens, project context, and session duration to JSONL
-- Output: ~/.local/share/nvim/activity.jsonl
-- Synced to n8n via tracker-sync.sh
return {
  "nvim-lua/plenary.nvim",
  lazy = false,
  config = function()
    local log_path = vim.fn.expand("~/.local/share/nvim/activity.jsonl")
    local session_start = os.time()
    local files_touched = {}

    local function get_project()
      local cwd = vim.fn.getcwd()
      return vim.fn.fnamemodify(cwd, ":t")
    end

    local function get_lang(buf)
      return vim.bo[buf].filetype or "unknown"
    end

    local function write(entry)
      entry.ts = os.date("!%Y-%m-%dT%H:%M:%SZ")
      local line = vim.fn.json_encode(entry) .. "\n"
      local f = io.open(log_path, "a")
      if f then
        f:write(line)
        f:close()
      end
    end

    -- Track file opens
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function(ev)
        local file = vim.fn.expand("%:.")
        if file == "" or vim.bo.buftype ~= "" then return end
        local lang = get_lang(ev.buf)
        files_touched[file] = true
        write({
          type = "file_open",
          file = file,
          lang = lang,
          project = get_project(),
        })
      end,
    })

    -- Track session end with summary
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        local duration = math.floor((os.time() - session_start) / 60)
        local touched = vim.tbl_count(files_touched)
        write({
          type = "session_end",
          project = get_project(),
          duration_mins = duration,
          files_touched = touched,
        })
      end,
    })

    -- Track git branch switches (project context change)
    vim.api.nvim_create_autocmd("DirChanged", {
      callback = function()
        write({
          type = "dir_change",
          project = get_project(),
          cwd = vim.fn.getcwd(),
        })
      end,
    })
  end,
}
