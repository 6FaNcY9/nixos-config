_: {
  programs.nixvim.plugins = {
    telescope = {
      enable = true;
      extensions.fzf-native.enable = true;
      settings.defaults = {
        sorting_strategy = "ascending";
        layout_config = {
          prompt_position = "top";
          horizontal = {preview_width = 0.55;};
          vertical = {mirror = true;};
        };
      };
    };

    lualine.enable = true;

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

    web-devicons.enable = true;
    gitsigns = {
      enable = true;
      settings = {
        signcolumn = false; # keep numbers at the edge
        numhl = true; # tint line numbers instead of using signs
      };
    };

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

    comment.enable = true;

    toggleterm = {
      enable = true;
      settings = {
        direction = "float";
        open_mapping = "[[<c-\\>]]";
      };
    };

    indent-blankline = {
      enable = true;
      settings = {
        indent.char = "┆";
        scope = {
          enabled = true;
          show_start = false; # avoid heavy horizontal lines on braces
          show_end = false;
          highlight = ["IblScope"];
        };
      };
    };

    markview = {
      enable = true;
      autoLoad = true;
    };

    nvim-autopairs.enable = true;
    luasnip.enable = true;

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
          {name = "nvim_lsp";}
          {name = "path";}
          {name = "buffer";}
          {name = "luasnip";}
        ];
      };
    };

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
