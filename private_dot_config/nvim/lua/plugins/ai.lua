-- CodeCompanion: AI chat / inline-edit for Neovim.
-- Auth via ANTHROPIC_API_KEY from shell env (see dot_custom/exports.sh).
-- To route through gopass instead, change env.api_key to:
--   "cmd:gopass show --password <path> | head -n 1"
return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = {
      "CodeCompanion",
      "CodeCompanionChat",
      "CodeCompanionActions",
      "CodeCompanionCmd",
    },
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "CodeCompanion Chat" },
      { "<leader>ai", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "CodeCompanion Inline" },
      { "<leader>ap", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "CodeCompanion Paste Selection" },
    },
    opts = {
      adapters = {
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            env = {
              api_key = "ANTHROPIC_API_KEY",
            },
            schema = {
              model = {
                -- Sonnet is the daily-driver default; Opus stays reserved for
                -- the standalone Claude Code CLI to avoid burning budget here.
                default = "claude-sonnet-4-5",
              },
            },
          })
        end,
      },
      strategies = {
        chat = { adapter = "anthropic" },
        inline = { adapter = "anthropic" },
        cmd = { adapter = "anthropic" },
      },
      display = {
        chat = {
          show_settings = false,
          show_token_count = true,
          window = {
            layout = "vertical",
            width = 0.4,
          },
        },
        diff = {
          provider = "default",
        },
      },
      opts = {
        log_level = "ERROR",
        send_code = true,
      },
    },
  },
}
