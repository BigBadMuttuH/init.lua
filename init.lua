-- Настройка lazy.nvim (менеджер плагинов)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- LuaSnip
  { "L3MON4D3/LuaSnip", config = function() require("luasnip").setup() end },
  -- Цветовая схема
  { "folke/tokyonight.nvim" },
  -- Statusline
  { "nvim-lualine/lualine.nvim" },
  -- Git
  { "tpope/vim-fugitive" },

  -- LSP (Pyright)
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("lspconfig").pyright.setup {
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "off", -- Можно изменить на "basic" или "strict" позже
              diagnosticMode = "workspace",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      }

      -- LSP Key Mappings
      local bufopts = { noremap = true, silent = true }
      local map = vim.api.nvim_set_keymap
      map('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', bufopts)
      map('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', bufopts)
      map('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', bufopts)
      map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', bufopts)
      map('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', bufopts)
      map('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', bufopts)
      map('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', bufopts)
      map('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', bufopts)
      map('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', bufopts)
      map('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', bufopts)
      map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', bufopts)
      map('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', bufopts)
      map('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', bufopts)
      map('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', bufopts)
      map('n', '<space>qf', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', bufopts)
      map("n", "<leader>lf", ":lua vim.lsp.buf.formatting()<CR>", { noremap = true, silent = true }) -- Форматирование
    end,
  },

  -- Автодополнение (nvim-cmp)
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip", -- Источник для LuaSnip
      "hrsh7th/cmp-calc",      -- Источник для вычислений
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(), -- Принудительное автодополнение
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path",
            option = {
              get_cwd = function()
                local cwd = vim.fn.getcwd()
                if cwd:match("^/mnt/c") then
                  return nil -- Отключаем пути из Windows
                end
                return cwd
              end,
            },
          },
          { name = "luasnip" }, -- Добавляем LuaSnip
          { name = "calc" },    -- Добавляем возможность вычислять выражения
        }),
      })
    end,
  },

  -- Форматирование кода (black, ruff)
  {
    "mhartington/formatter.nvim",
    config = function()
      require("formatter").setup({
        filetype = {
          python = {
            function()
              return {
                exe = "black",
                args = { "--fast", "-" },
                stdin = true
              }
            end,
            function()
              return {
                exe = "ruff",
                args = { "--fix", "-" },
                stdin = true
              }
            end,
          },
        },
      })
    end,
  },

  -- Дерево файлов (nvim-tree)
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end,
  },

  -- DAP (отладчик)
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      dap.adapters.python = {
        type = "executable",
        command = "python",
        args = { "-m", "debugpy.adapter" },
      }

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Запуск Python-скрипта",
          program = "${file}",
          console = "integratedTerminal",
        },
      }
    end,
  },

  -- Telescope (поиск файлов, LSP-символов, команд) -  теперь *после* установки
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "node_modules", "__pycache__", "%.lock" },
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_down",
              ["<C-k>"] = "move_selection_up",
            },
          },
        },
        pickers = {
          live_grep = {
            additional_args = { "--no-ignore", "--hidden" }, -- Включаем поиск по скрытым файлам и каталогам
          },
        },
      })
    end,
  },
}, {}) -- Важно закрыть скобку!

-- Основные настройки
vim.opt.number = true            -- Включаем номера строк
vim.opt.relativenumber = true    -- Относительная нумерация
vim.opt.expandtab = true         -- Пробелы вместо табов
vim.opt.shiftwidth = 4           -- Отступ в 4 пробела
vim.opt.tabstop = 4              -- Таб в 4 пробела
vim.opt.smartindent = true       -- Умный отступ
vim.opt.mouse = "a"              -- Включаем мышь
vim.opt.clipboard = "unnamedplus" -- Общий буфер обмена с системой


-- Lualine Configuration (пример) - после установки
require('lualine').setup {
  options = { theme = 'tokyonight' },
}

-- TokyoNight Configuration (пример) - после установки
vim.cmd [[ colorscheme tokyonight ]]


-- Горячие клавиши
vim.api.nvim_set_keymap("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>f", ":Format<CR>", { noremap = true, silent = true })

-- Быстрые клавиши для отладки
vim.api.nvim_set_keymap("n", "<F5>", ":lua require'dap'.continue()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<F10>", ":lua require'dap'.step_over()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<F11>", ":lua require'dap'.step_into()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<F12>", ":lua require'dap'.step_out()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>b", ":lua require'dap'.toggle_breakpoint()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", { noremap = true, silent = true })

-- Telescope 
vim.api.nvim_set_keymap("n", "<leader>ff", ":Telescope find_files<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>fg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>fb", ":Telescope buffers<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>fh", ":Telescope help_tags<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>", { noremap = true, silent = true })
