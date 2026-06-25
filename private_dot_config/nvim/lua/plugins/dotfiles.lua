local function executable(name)
  return vim.fn.executable(name) == 1
end

local function has_file(ctx, names)
  return vim.fs.find(names, { path = ctx.filename, upward = true })[1] ~= nil
end

return {
  {
    "xvzc/chezmoi.nvim",
    optional = true,
    init = function()
      local source = vim.fn.expand("~/.local/share/chezmoi")
      local worktrees = source .. "/.worktrees/"

      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("local_chezmoi_watch", { clear = true }),
        pattern = { source .. "/*" },
        callback = function(event)
          local path = vim.api.nvim_buf_get_name(event.buf)
          if path:sub(1, #worktrees) == worktrees then
            return
          end

          vim.schedule(function()
            require("chezmoi.commands.__edit").watch(event.buf)
          end)
        end,
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        bash = { "shfmt" },
        sh = { "shfmt" },
      },
      formatters = {
        shfmt = {
          prepend_args = { "-i", "4" },
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.lua = vim.list_extend(opts.linters_by_ft.lua or {}, { "selene" })
      opts.linters_by_ft.yaml = vim.list_extend(opts.linters_by_ft.yaml or {}, { "actionlint" })

      opts.linters = opts.linters or {}
      opts.linters.selene = {
        condition = function(ctx)
          return executable("selene") and has_file(ctx, { "selene.toml" })
        end,
      }
      opts.linters.actionlint = {
        condition = function(ctx)
          return executable("actionlint") and ctx.filename:match("/%.github/workflows/.*%.ya?ml$") ~= nil
        end,
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {
          filetypes = { "sh", "bash" },
        },
      },
    },
  },
}
