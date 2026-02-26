# Plugin Ecosystem Configuration
# All plugins with their settings: LSP, completion, AI assistance, fuzzy finder, etc.

_: {
  programs.nixvim.plugins = {
    # GitHub Copilot: AI-powered code completion with auto-triggered suggestions
    copilot-lua = {
      enable = true;
      autoLoad = true;

      settings = {
        suggestion = {
          enable = true;
          auto_trigger = true;
          debounce = 75;
          keymaps = { };
        };

        panel = {
          enable = true;
          auto_refresh = false;
          keymaps = { };
        };
      };
    };

    # Telescope: Fuzzy finder for files, text, buffers, help (ascending layout)
    telescope = {
      enable = true;
      extensions.fzf-native.enable = true;
      settings.defaults = {
        sorting_strategy = "ascending";
        layout_config = {
          prompt_position = "top";
          horizontal = {
            preview_width = 0.55;
          };
          vertical = {
            mirror = true;
          };
        };
      };
    };

    # Treesitter: Advanced syntax highlighting and AST-based features
    treesitter = {
      enable = true;
      nixGrammars = true;

      settings = {
        auto_install = false;
        highlight.enable = true;
        indent.enable = true;

        incremental_selection = {
          enable = true;
          keymaps = {
            init_selection = "<CR>";
            node_incremental = "<CR>";
            node_decremental = "<BS>";
            scope_incremental = "<TAB>";
          };
        };
      };
    };

    # Git integration
    web-devicons.enable = true;
    # Gitsigns: Git changes in the gutter (uses number column tint instead of sign column)
    gitsigns = {
      enable = true;
      settings = {
        signcolumn = false; # keep numbers at the edge
        numhl = true; # tint line numbers instead of using signs
      };
    };

    # Neo-tree: Modern file tree with current file tracking and hidden file support
    "neo-tree" = {
      enable = true;
      settings = {
        close_if_last_window = true;
        filesystem = {
          follow_current_file = {
            enabled = true;
          };
          filtered_items = {
            hide_gitignored = false;
            hide_dotfiles = false;
          };
        };
      };
    };

    # Which-key: Show available keybindings in popup (defines keymap groups)
    which-key = {
      enable = true;
      settings = {
        delay = 300;
      };
      luaConfig.post = ''
        local wk = require("which-key")
        wk.add({
          { "<leader>f", group = "Find" },
          { "<leader>t", group = "Terminal" },
          { "<leader>c", group = "Code" },
        })
      '';
    };

    # Comment.nvim: Smart comment toggling
    comment.enable = true;

    # ToggleTerm: Floating terminal with C-\ toggle
    toggleterm = {
      enable = true;
      settings = {
        direction = "float";
        open_mapping = "[[<c-\\>]]";
      };
    };

    # Indent guides with scope highlighting
    indent-blankline = {
      enable = true;
      settings = {
        indent.char = "┆";
        scope = {
          enabled = true;
          show_start = false; # avoid heavy horizontal lines on braces
          show_end = false;
          highlight = [ "IblScope" ];
        };
      };
    };

    # Markview: Rich markdown rendering in buffer
    markview = {
      enable = true;
      autoLoad = true;
    };

    # Text automation
    nvim-autopairs.enable = true; # Auto-close brackets, quotes
    luasnip.enable = true; # Snippet engine for code templates

    # Colorizer: Show hex colors as text foreground (mode=foreground)
    colorizer = {
      enable = true;
      settings.user_default_options = {
        names = false;
        rgb = true;
        RRGGBBAA = true;
        AARRGGBB = true;
        mode = "foreground";
      };
    };

    # nvim-cmp: Autocompletion with LSP, path, buffer, and snippet sources
    # Keybinds: Tab/S-Tab=navigate, CR=confirm, C-Space=trigger
    cmp = {
      enable = true;
      autoEnableSources = true;

      settings = {
        snippet.expand.__raw = ''
          function(args)
            require("luasnip").lsp_expand(args.body)
          end
        '';

        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = "cmp.mapping.select_next_item()";
          "<S-Tab>" = "cmp.mapping.select_prev_item()";
        };

        sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
          { name = "luasnip"; }
        ];
      };

      # Cmdline completion
      cmdline = {
        "/" = {
          mapping.__raw = "cmp.mapping.preset.cmdline()";
          sources = [
            { name = "buffer"; }
          ];
        };

        "?" = {
          mapping.__raw = "cmp.mapping.preset.cmdline()";
          sources = [
            { name = "buffer"; }
          ];
        };

        ":" = {
          mapping.__raw = "cmp.mapping.preset.cmdline()";
          sources = [
            { name = "path"; }
            { name = "cmdline"; }
          ];
        };
      };
    };

    # Language Server Protocol: pyright, lua_ls, nixd, bashls, jsonls, yamlls,
    # rust_analyzer, clangd, gopls, ts_ls, marksman
    lsp = {
      enable = true;

      servers = {
        # Scripting & config
        pyright.enable = true;
        lua_ls.enable = true;
        nixd.enable = true;
        bashls.enable = true;

        # Data formats
        jsonls.enable = true;
        yamlls.enable = true;

        # Systems programming
        rust_analyzer = {
          enable = true;
          installCargo = true;
          installRustc = true;
        };
        clangd.enable = true; # C/C++
        gopls.enable = true; # Go

        # Web development
        ts_ls.enable = true; # TypeScript/JavaScript

        # Documentation
        marksman.enable = true; # Markdown
      };

      keymaps = {
        silent = true;
        lspBuf = {
          "gd" = "definition";
          "gD" = "declaration";
          "gr" = "references";
          "gi" = "implementation";
          "K" = "hover";
          "<leader>rn" = "rename";
          "<leader>ca" = "code_action";
        };
        diagnostic = {
          "[d" = "goto_prev";
          "]d" = "goto_next";
          "<leader>e" = "open_float";
        };
      };
    };
  };
}
