{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      # Plugins without native nixvim modules
      vim-matchup # Enhanced % matching
      cheatsheet-nvim # Searchable keymaps/commands help
    ];

    extraPackages = with pkgs; [
      tree-sitter-cli
    ];

    extraConfigLua = ''
      -- Fix tree-sitter query errors by prepending nvim-treesitter runtime path
      -- This ensures complete query files with inheritance (e.g., ecma for JS/TS)
      -- See: https://github.com/NixOS/nixpkgs/issues/478561
      vim.opt.rtp:prepend("${pkgs.vimPlugins.nvim-treesitter}/runtime/")

      -- Plugin-specific global variables
      vim.g.rainbow_delimiters = vim.g.rainbow_delimiters or {}
      vim.g.matchup_matchparen_offscreen = { method = "popup" }

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
