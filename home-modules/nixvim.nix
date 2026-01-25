{
  pkgs,
  c,
  ...
}: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    opts = {
      cursorline = true;
      cursorlineopt = "number,line";
      relativenumber = true;
      number = true;

      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      smartindent = true;

      wrap = false;
      ignorecase = true;
      smartcase = true;

      hlsearch = false;
      incsearch = true;
      termguicolors = true;

      scrolloff = 8;
      signcolumn = "no";

      laststatus = 3;
      colorcolumn = "100";

      updatetime = 200;
      undofile = true;
      swapfile = false;
    };

    extraPlugins = with pkgs.vimPlugins; [
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      vim-matchup
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

      -- Cmdline completion (protect if cmp-cmdline isn’t available yet)
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

    plugins = {
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
          highlight.enable = true;
          indent.enable = true;

          ensure_installed = [
            # Shell & config
            "nix"
            "bash"
            "fish"
            "lua"
            "vim"
            "vimdoc"

            # Data formats
            "json"
            "yaml"
            "toml"
            "regex"

            # Systems programming
            "rust"
            "c"
            "cpp"
            "go"
            "gomod"
            "gosum"

            # Web development
            "javascript"
            "typescript"
            "tsx"
            "html"
            "css"

            # Documentation
            "markdown"
            "markdown_inline"

            # Git
            "diff"
            "gitcommit"
            "git_config"
          ];

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

    keymaps = [
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<cr>";
        options = {
          silent = true;
          desc = "Find files";
        };
      }
      {
        mode = "n";
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<cr>";
        options = {
          silent = true;
          desc = "Live grep";
        };
      }
      {
        mode = "n";
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<cr>";
        options = {
          silent = true;
          desc = "Buffers";
        };
      }
      {
        mode = "n";
        key = "<leader>fh";
        action = "<cmd>Telescope help_tags<cr>";
        options = {
          silent = true;
          desc = "Help tags";
        };
      }
      {
        mode = "n";
        key = "<leader>ft";
        action = "<cmd>Tutor<cr>";
        options = {
          silent = true;
          desc = "Tutor";
        };
      }
      {
        mode = "n";
        key = "<leader>?";
        action = "<cmd>Cheatsheet<cr>";
        options = {
          silent = true;
          desc = "Cheatsheet";
        };
      }
      {
        mode = "n";
        key = "<leader>fk";
        action = "<cmd>Telescope keymaps<cr>";
        options = {
          silent = true;
          desc = "Keymaps";
        };
      }
      {
        mode = "n";
        key = "<leader>fe";
        action = "<cmd>Neotree toggle<cr>";
        options = {
          silent = true;
          desc = "Toggle tree";
        };
      }
      {
        mode = "n";
        key = "<leader>tt";
        action = "<cmd>ToggleTerm<cr>";
        options = {
          silent = true;
          desc = "Floating terminal";
        };
      }
      {
        mode = "n";
        key = "<leader>fm";
        action = "<cmd>lua vim.lsp.buf.format({ async = true })<cr>";
        options = {
          silent = true;
          desc = "Format";
        };
      }
      {
        mode = "n";
        key = "<leader>fc";
        action = "<cmd>Telescope commands<cr>";
        options = {
          silent = true;
          desc = "Commands";
        };
      }
    ];
  };
}
