# Yazi File Manager Configuration
# Modern terminal file manager with vim-like navigation and rich theme integration
#
# Features:
#   - Full keyboard navigation with vim-like bindings
#   - Smart enter: open files or enter directories seamlessly
#   - Git status in linemode (via git plugin)
#   - Visual borders (via full-border plugin)
#   - Jump to char: vim-like f<char> navigation
#   - Toggle / maximize preview pane
#   - Rich file openers: editor, xdg-open, mpv, unar, alacritty
#   - Complete palette-matched theme across all 12 UI sections
#
# Theme:
#   - Integrates with palette.* for consistent Gruvbox Dark Pale colors
#   - Mode indicators: normal (accent/olive), select (warn/amber), unset (danger/red)
#   - File type colors: images (accent2/steel), videos (orange), audio (purple)
#   - Archives (warn/amber), code (accent/olive), configs (aqua), dotfiles (muted)
{
  lib,
  config,
  pkgs,
  palette,
  ...
}:
let
  cfg = config.features.terminal.yazi;
in
{
  options.features.terminal.yazi = {
    enable = lib.mkEnableOption "yazi file manager";
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
      shellWrapperName = "yy";

      plugins = {
        inherit (pkgs.yaziPlugins) git chmod;
        "smart-enter" = pkgs.yaziPlugins."smart-enter";
        "full-border" = pkgs.yaziPlugins."full-border";
        "jump-to-char" = pkgs.yaziPlugins."jump-to-char";
        "toggle-pane" = pkgs.yaziPlugins."toggle-pane";
      };

      initLua = ''
        require("full-border"):setup()
        require("git"):setup()
      '';

      settings = {
        manager = {
          show_hidden = true;
          show_symlink = true;
          sort_by = "modified";
          sort_dir_first = true;
          sort_reverse = true;
          scrolloff = 5;
          linemode = "size";
          title_format = "Yazi: {cwd}";
        };

        preview = {
          image_filter = "lanczos3";
          image_quality = 80;
          max_width = 1920;
          max_height = 1080;
          wrap = "yes";
          tab_size = 2;
        };

        opener = {
          edit = [
            {
              run = ''$EDITOR "$@"'';
              block = true;
              desc = "Edit";
              for = "unix";
            }
          ];
          open = [
            {
              run = ''xdg-open "$@"'';
              desc = "Open";
              for = "unix";
            }
          ];
          play = [
            {
              run = ''mpv "$@"'';
              orphan = true;
              desc = "Play";
              for = "unix";
            }
          ];
          extract = [
            {
              run = ''unar "$1"'';
              desc = "Extract here";
              for = "unix";
            }
          ];
          terminal = [
            {
              run = ''alacritty --working-directory "$@"'';
              orphan = true;
              desc = "Open terminal here";
              for = "unix";
            }
          ];
        };

        open = {
          prepend_rules = [
            {
              mime = "text/*";
              use = "edit";
            }
            {
              mime = "image/*";
              use = "open";
            }
            {
              mime = "video/*";
              use = "play";
            }
            {
              mime = "audio/*";
              use = "play";
            }
            {
              mime = "application/pdf";
              use = "open";
            }
            {
              mime = "application/zip";
              use = "extract";
            }
            {
              mime = "application/x-tar";
              use = "extract";
            }
            {
              mime = "application/gzip";
              use = "extract";
            }
            {
              mime = "application/x-bzip2";
              use = "extract";
            }
            {
              mime = "application/x-xz";
              use = "extract";
            }
            {
              mime = "application/zstd";
              use = "extract";
            }
            {
              mime = "application/x-7z-compressed";
              use = "extract";
            }
            {
              name = "*.tar.*";
              use = "extract";
            }
          ];
        };
      };

      keymap = {
        mgr = {
          prepend_keymap = [
            # Smart enter: open file or enter directory
            {
              on = [ "l" ];
              run = "plugin smart-enter";
              desc = "Enter directory or open file";
            }
            {
              on = [ "<Enter>" ];
              run = "plugin smart-enter";
              desc = "Enter directory or open file";
            }
            # Jump to char (vim-like f<char>)
            {
              on = [ "f" ];
              run = "plugin jump-to-char";
              desc = "Jump to char";
            }
            # Preview pane control
            {
              on = [ "T" ];
              run = "plugin toggle-pane";
              desc = "Toggle preview pane";
            }
            # Copy operations
            {
              on = [
                "c"
                "c"
              ];
              run = "copy path";
              desc = "Copy absolute path";
            }
            {
              on = [
                "c"
                "f"
              ];
              run = "copy filename";
              desc = "Copy filename";
            }
            {
              on = [
                "c"
                "d"
              ];
              run = "copy dirname";
              desc = "Copy directory path";
            }
            # Chmod
            {
              on = [
                "c"
                "m"
              ];
              run = "plugin chmod";
              desc = "Change file permissions";
            }
          ];
        };
      };

      theme = {
        mgr = {
          cwd = {
            fg = "${palette.accent}";
          };
          hovered = {
            fg = "${palette.bg}";
            bg = "${palette.accent}";
            bold = true;
          };
          preview_hovered = {
            underline = true;
          };
          find_keyword = {
            fg = "${palette.warn}";
            bold = true;
            underline = true;
          };
          find_position = {
            fg = "${palette.accent2}";
            italic = true;
          };
          marker_selected = {
            fg = "${palette.accent}";
            bg = "${palette.accent}";
          };
          marker_copied = {
            fg = "${palette.warn}";
            bg = "${palette.warn}";
          };
          marker_cut = {
            fg = "${palette.danger}";
            bg = "${palette.danger}";
          };
          count_selected = {
            fg = "${palette.bg}";
            bg = "${palette.accent}";
            bold = true;
          };
          count_copied = {
            fg = "${palette.bg}";
            bg = "${palette.warn}";
            bold = true;
          };
          count_cut = {
            fg = "${palette.bg}";
            bg = "${palette.danger}";
            bold = true;
          };
          border_symbol = "|";
          border_style = {
            fg = "${palette.muted}";
          };
          symlink_target = {
            fg = "${palette.accent2}";
            italic = true;
          };
        };

        tabs = {
          active = {
            fg = "${palette.bg}";
            bg = "${palette.accent}";
            bold = true;
          };
          inactive = {
            fg = "${palette.muted}";
            bg = "${palette.bgAlt}";
          };
          sep_left = {
            open = "│";
            close = "│";
            fg = "${palette.accent}";
            bg = "${palette.bgAlt}";
          };
          sep_right = {
            open = "│";
            close = "│";
            fg = "${palette.bgAlt}";
            bg = "${palette.bg}";
          };
        };

        mode = {
          normal_main = {
            fg = "${palette.bg}";
            bg = "${palette.accent}";
            bold = true;
          };
          normal_alt = {
            fg = "${palette.accent}";
            bg = "${palette.bgAlt}";
          };
          select_main = {
            fg = "${palette.bg}";
            bg = "${palette.warn}";
            bold = true;
          };
          select_alt = {
            fg = "${palette.warn}";
            bg = "${palette.bgAlt}";
          };
          unset_main = {
            fg = "${palette.bg}";
            bg = "${palette.danger}";
            bold = true;
          };
          unset_alt = {
            fg = "${palette.danger}";
            bg = "${palette.bgAlt}";
          };
        };

        status = {
          overall = {
            bg = "${palette.bgAlt}";
            fg = "${palette.text}";
          };
          sep_left = {
            open = "│";
            close = "│";
            fg = "${palette.bgAlt}";
          };
          sep_right = {
            open = "│";
            close = "│";
            fg = "${palette.bgAlt}";
          };
          perm_read = {
            fg = "${palette.warn}";
          };
          perm_write = {
            fg = "${palette.danger}";
          };
          perm_exec = {
            fg = "${palette.accent}";
          };
          perm_sep = {
            fg = "${palette.muted}";
          };
          perm_type = {
            fg = "${palette.accent2}";
          };
          perm_owner = {
            fg = "${palette.cream}";
          };
          perm_group = {
            fg = "${palette.muted}";
          };
          progress_label = {
            fg = "${palette.text}";
            bold = true;
          };
          progress_normal = {
            fg = "${palette.accent}";
            bg = "${palette.bgAlt}";
          };
          progress_error = {
            fg = "${palette.danger}";
            bg = "${palette.bgAlt}";
          };
        };

        which = {
          mask = {
            bg = "${palette.bgAlt}";
          };
          cand = {
            fg = "${palette.accent}";
            bold = true;
          };
          rest = {
            fg = "${palette.text}";
          };
          desc = {
            fg = "${palette.accent2}";
          };
          separator = "  ";
          separator_style = {
            fg = "${palette.muted}";
          };
        };

        input = {
          border = {
            fg = "${palette.accent}";
          };
          title = {
            fg = "${palette.cream}";
            bold = true;
          };
          value = {
            fg = "${palette.text}";
          };
          selected = {
            reversed = true;
          };
        };

        confirm = {
          border = {
            fg = "${palette.accent}";
          };
          title = {
            fg = "${palette.cream}";
            bold = true;
          };
          content = {
            fg = "${palette.text}";
          };
          list = {
            fg = "${palette.text}";
          };
          btn_yes = {
            fg = "${palette.bg}";
            bg = "${palette.accent}";
            bold = true;
          };
          btn_no = {
            fg = "${palette.bg}";
            bg = "${palette.danger}";
            bold = true;
          };
        };

        pick = {
          border = {
            fg = "${palette.accent}";
          };
          active = {
            fg = "${palette.bg}";
            bg = "${palette.accent}";
            bold = true;
          };
          inactive = {
            fg = "${palette.text}";
          };
        };

        notify = {
          title_info = {
            fg = "${palette.accent}";
            bold = true;
          };
          title_warn = {
            fg = "${palette.warn}";
            bold = true;
          };
          title_error = {
            fg = "${palette.danger}";
            bold = true;
          };
          border_info = {
            fg = "${palette.accent}";
          };
          border_warn = {
            fg = "${palette.warn}";
          };
          border_error = {
            fg = "${palette.danger}";
          };
        };

        tasks = {
          border = {
            fg = "${palette.muted}";
          };
          title = {
            fg = "${palette.cream}";
            bold = true;
          };
          hovered = {
            fg = "${palette.bg}";
            bg = "${palette.accent}";
            bold = true;
          };
        };

        help = {
          on = {
            fg = "${palette.accent}";
          };
          run = {
            fg = "${palette.accent2}";
          };
          hovered = {
            fg = "${palette.bg}";
            bg = "${palette.accent}";
            bold = true;
          };
          footer = {
            fg = "${palette.text}";
          };
        };

        filetype = {
          rules = [
            # Code files — olive green (accent)
            {
              name = "*.nix";
              fg = "${palette.accent}";
            }
            {
              name = "*.lua";
              fg = "${palette.accent}";
            }
            {
              name = "*.sh";
              fg = "${palette.accent}";
            }
            {
              name = "*.bash";
              fg = "${palette.accent}";
            }
            {
              name = "*.fish";
              fg = "${palette.accent}";
            }
            {
              name = "*.py";
              fg = "${palette.accent}";
            }
            {
              name = "*.rs";
              fg = "${palette.accent}";
            }
            {
              name = "*.go";
              fg = "${palette.accent}";
            }
            {
              name = "*.ts";
              fg = "${palette.accent}";
            }
            {
              name = "*.tsx";
              fg = "${palette.accent}";
            }
            {
              name = "*.js";
              fg = "${palette.accent}";
            }
            {
              name = "*.jsx";
              fg = "${palette.accent}";
            }
            # Config files — aqua
            {
              name = "*.json";
              fg = "${palette.aqua}";
            }
            {
              name = "*.yaml";
              fg = "${palette.aqua}";
            }
            {
              name = "*.yml";
              fg = "${palette.aqua}";
            }
            {
              name = "*.toml";
              fg = "${palette.aqua}";
            }
            {
              name = "*.ini";
              fg = "${palette.aqua}";
            }
            {
              name = "*.conf";
              fg = "${palette.aqua}";
            }
            # Archives — amber (warn)
            {
              name = "*.zip";
              fg = "${palette.warn}";
            }
            {
              name = "*.tar";
              fg = "${palette.warn}";
            }
            {
              name = "*.tar.*";
              fg = "${palette.warn}";
            }
            {
              name = "*.gz";
              fg = "${palette.warn}";
            }
            {
              name = "*.bz2";
              fg = "${palette.warn}";
            }
            {
              name = "*.xz";
              fg = "${palette.warn}";
            }
            {
              name = "*.zst";
              fg = "${palette.warn}";
            }
            {
              name = "*.7z";
              fg = "${palette.warn}";
            }
            {
              name = "*.rar";
              fg = "${palette.warn}";
            }
            # Dotfiles — muted gray
            {
              name = ".*";
              fg = "${palette.muted}";
            }
            # Media files (mime-based)
            {
              mime = "image/*";
              fg = "${palette.accent2}";
            }
            {
              mime = "video/*";
              fg = "${palette.orange}";
            }
            {
              mime = "audio/*";
              fg = "${palette.purple}";
            }
            # Documents
            {
              mime = "application/pdf";
              fg = "${palette.cream}";
            }
            {
              mime = "text/html";
              fg = "${palette.orange}";
            }
            # Executables — danger red
            {
              mime = "application/x-executable";
              fg = "${palette.danger}";
            }
            {
              mime = "application/x-sharedlib";
              fg = "${palette.danger}";
            }
            # Text catch-all (must be last)
            {
              mime = "text/*";
              fg = "${palette.text}";
            }
          ];
        };
      };
    };
  };
}
