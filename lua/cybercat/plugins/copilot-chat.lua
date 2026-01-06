return {
  "CopilotC-Nvim/CopilotChat.nvim",
  branch = "canary",
  dependencies = {
    { "zbirenbaum/copilot.lua" },
    { "nvim-lua/plenary.nvim" },
  },
  opts = {
    debug = false,
    model = "gpt-4o",
    prompts = {
      Commit = {
        prompt = "Generate a commit message using commitizen convention based ONLY on the git diff shown below. Rules:\n- Use type(scope): summary format (feat/fix/docs/chore/refactor/test/style)\n- First line max 50 chars\n- Only describe files/changes actually in the diff\n- For simple file additions, just say 'docs: add [filename]' or 'chore: add [files]'\n- NO assumptions, NO inventions, ONLY what's in the diff\n- Output plain text commit message, no code blocks",
        selection = function(source)
          return require("CopilotChat.select").gitdiff(source, true)
        end,
      },
      CommitStaged = {
        prompt = "Generate a commit message using commitizen convention based ONLY on the git diff shown below. Rules:\n- Use type(scope): summary format (feat/fix/docs/chore/refactor/test/style)\n- First line max 50 chars\n- Only describe files/changes actually in the diff\n- For simple file additions, just say 'docs: add [filename]' or 'chore: add [files]'\n- NO assumptions, NO inventions, ONLY what's in the diff\n- Output plain text commit message, no code blocks",
        selection = function(source)
          return require("CopilotChat.select").gitdiff(source, true)
        end,
      },
    },
    window = {
      layout = "float",
      width = 0.8,
      height = 0.8,
    },
  },
  keys = {
    -- Quick chat
    {
      "<leader>gcc",
      function()
        local input = vim.fn.input("Quick Chat: ")
        if input ~= "" then
          require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
        end
      end,
      desc = "CopilotChat - Quick chat",
    },
    -- Show help actions
    {
      "<leader>gch",
      function()
        local actions = require("CopilotChat.actions")
        require("CopilotChat.integrations.telescope").pick(actions.help_actions())
      end,
      desc = "CopilotChat - Help actions",
    },
    -- Show prompts actions
    {
      "<leader>gcp",
      function()
        local actions = require("CopilotChat.actions")
        require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
      end,
      desc = "CopilotChat - Prompt actions",
    },
    -- Generate commit message for staged changes
    {
      "<leader>gcm",
      function()
        -- Get git diff file list
        local diff_names = vim.fn.system("git diff --cached --name-status")
        
        if vim.v.shell_error ~= 0 or diff_names == "" then
          vim.notify("No staged changes", vim.log.levels.WARN)
          return
        end
        
        -- Get full diff for more context
        local full_diff = vim.fn.system("git diff --cached")
        
        -- Build detailed prompt with both file list and diff
        local prompt = string.format([[Here are the git changes:

FILES CHANGED:
%s

FULL DIFF:
%s

Write a DETAILED commit message using commitizen convention:

1. First line: type(scope): concise summary (max 50 chars)
   - Types: feat, fix, docs, chore, refactor, test, style, perf

2. Blank line

3. Body (if needed): Explain WHAT changed and WHY
   - Wrap at 72 characters per line
   - Use bullet points if multiple changes
   - Be specific about the actual changes shown in the diff
   - Don't make assumptions or invent features

Example format:
feat(auth): add user authentication

- Implement JWT token generation and validation
- Add login/logout endpoints
- Include password hashing with bcrypt
- Add user session management

Only describe what's actually in the diff above. Be thorough but accurate.]], diff_names, full_diff)
        
        require("CopilotChat").ask(prompt)
      end,
      desc = "CopilotChat - Generate commit message for staged changes",
    },
    -- Open chat
    {
      "<leader>gco",
      "<cmd>CopilotChatToggle<cr>",
      desc = "CopilotChat - Toggle chat",
    },
  },
  config = function(_, opts)
    local chat = require("CopilotChat")
    local select = require("CopilotChat.select")

    -- Use unnamed register for the selection
    opts.selection = select.unnamed

    chat.setup(opts)

    vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
      chat.ask(args.args, { selection = select.visual })
    end, { nargs = "*", range = true })

    -- Inline chat with Copilot
    vim.api.nvim_create_user_command("CopilotChatInline", function(args)
      chat.ask(args.args, {
        selection = select.visual,
        window = {
          layout = "float",
          relative = "cursor",
          width = 1,
          height = 0.4,
          row = 1,
        },
      })
    end, { nargs = "*", range = true })

    -- Restore CopilotChatBuffer
    vim.api.nvim_create_user_command("CopilotChatBuffer", function(args)
      chat.ask(args.args, { selection = select.buffer })
    end, { nargs = "*", range = true })

    -- Custom buffer for CopilotChat
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "copilot-*",
      callback = function()
        vim.opt_local.relativenumber = true
        vim.opt_local.number = true
      end,
    })

    -- Note: Auto-generate commit message autocmd moved to core/autocmds.lua
    -- to ensure it loads before git commit buffers open
  end,
  event = "VeryLazy",
}
