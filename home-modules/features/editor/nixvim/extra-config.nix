{
  pkgs,
  c,
  ...
}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      vim-matchup
      markview-nvim
      rainbow-delimiters-nvim
      cheatsheet-nvim
    ];

    extraConfigLua = ''
      vim.opt.completeopt = { "menu", "menuone", "noselect" }

      -- Softer indent guides and scope lines
      vim.api.nvim_set_hl(0, "IblIndent", { fg = "${c.base01}", nocombine = true })
      vim.api.nvim_set_hl(0, "IblScope", { fg = "${c.base02}", nocombine = true })

      -- Make the active window obvious
      vim.api.nvim_set_hl(0, "CursorLine", { bg = "${c.base01}" })
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "${c.base0A}", bold = true })
      vim.api.nvim_set_hl(0, "LineNr", { fg = "${c.base03}" })

      vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
        callback = function() vim.wo.cursorline = true end,
      })
      vim.api.nvim_create_autocmd({ "WinLeave" }, {
        callback = function() vim.wo.cursorline = false end,
      })

      -- Keep diagnostics signs out of the signcolumn; gitsigns is numhl-only below
      vim.diagnostic.config({ signs = false })

      vim.g.rainbow_delimiters = vim.g.rainbow_delimiters or {}
      vim.g.matchup_matchparen_offscreen = { method = "popup" }

      -- Cmdline completion (protect if cmp-cmdline isn't available yet)
      local has_cmp, cmp = pcall(require, "cmp")
      if has_cmp then
        cmp.setup.cmdline({ "/", "?" }, {
          mapping = cmp.mapping.preset.cmdline(),
          sources = { { name = "buffer" } },
        })

        cmp.setup.cmdline(":", {
          mapping = cmp.mapping.preset.cmdline(),
          sources = cmp.config.sources(
            { { name = "path" } },
            { { name = "cmdline" } }
          ),
        })
      end

      -- Cheatsheet: searchable quick help for keymaps/commands
      local has_cheatsheet, cheatsheet = pcall(require, "cheatsheet")
      if has_cheatsheet then
        cheatsheet.setup({
          bundled_cheatsheets = true,
          bundled_plugin_cheatsheets = true,
          include_only_installed_plugins = true,
        })

        -- Avoid Telescope "open in new tab" errors inside Cheatsheet picker
        vim.api.nvim_create_user_command("Cheatsheet", function()
          cheatsheet.show_cheatsheet(nil, {
            mappings = {
              n = { t = false },
              i = { ["<C-t>"] = false },
            },
          })
        end, { force = true })
      end

    '';
  };
}
