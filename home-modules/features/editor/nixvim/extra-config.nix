# Extra Configuration
# Additional plugins and Lua config that don't have native nixvim modules
#
# Includes:
#   - vim-matchup: Enhanced % matching for brackets/tags
#   - cheatsheet-nvim: Searchable keymaps and commands help
#   - Treesitter runtime path fix for complete query files

{ pkgs, inputs, ... }:
{
  programs.nixvim = {
    extraPlugins = [
      # Plugins without native nixvim modules
      pkgs.vimPlugins.vim-matchup # Enhanced % matching
      pkgs.vimPlugins.cheatsheet-nvim # Searchable keymaps/commands help
      (pkgs.vimUtils.buildVimPlugin {
        name = "hmts-nvim";
        src = pkgs.applyPatches {
          name = "hmts-nvim-src";
          src = inputs.hmts-nvim;
          patches = [ ./hmts-neovim-compat.patch ];
        };
      })
    ];

    extraPackages = [
      pkgs.tree-sitter-cli
      # Formatters for conform.nvim
      pkgs.nixfmt
      pkgs.ruff
      pkgs.stylua
      pkgs.rustfmt
      # Linters for nvim-lint
      pkgs.statix
      pkgs.shellcheck
      pkgs.lua51Packages.luacheck
    ];

    extraConfigLua = ''
      -- Fix tree-sitter query errors by prepending nvim-treesitter runtime path
      -- This ensures complete query files with inheritance (e.g., ecma for JS/TS)
      -- See: https://github.com/NixOS/nixpkgs/issues/478561
      vim.opt.rtp:prepend("${pkgs.vimPlugins.nvim-treesitter}/runtime/")

      -- Plugin-specific global variables
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
      -- Filetype detection for LSP servers
      vim.filetype.add({
        extension = {
          mdx = "markdown.mdx",
          tmpl = "gotmpl",
        },
        filename = {
          ["go.work"] = "gowork",
        },
      })
    '';
  };
}
