{
  lib,
  pkgs,
  config,
  inputs,
  username ? "vino",
  hostname ? "bandit",
  repoRoot ? "/home/${username}/src/nixos-config",
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  # Safe: Stylix palette is exposed under config.lib.stylix.colors (when Stylix is loaded)
  c =
    lib.attrByPath ["lib" "stylix" "colors" "withHashtag"] {
      # fallback (only used if Stylix isn’t loaded)
      base00 = "#262626";
      base01 = "#3a3a3a";
      base02 = "#4e4e4e";
      base03 = "#8a8a8a";
      base04 = "#949494";
      base05 = "#dab997";
      base06 = "#d5c4a1";
      base07 = "#ebdbb2";
      base08 = "#d75f5f";
      base09 = "#ff8700";
      base0A = "#ffaf00";
      base0B = "#afaf00";
      base0C = "#85ad85";
      base0D = "#83a598";
      base0E = "#d3869b";
      base0F = "#af5f5f";
    }
    config;

  # Safe: Stylix fonts are under config.stylix.fonts (when Stylix is loaded)
  stylixFonts =
    lib.attrByPath ["stylix" "fonts"] {
      sansSerif = {name = "Sans";};
      monospace = {name = "Monospace";};
    }
    config;

  unstablePkgs =
    pkgs.unstable or (import inputs.nixpkgs-unstable {
      inherit system;
      config = {
        allowUnfree = true;
      };
    });

  codexInput = inputs."codex-cli-nix" or null;

  codexPkg =
    if codexInput != null
    then codexInput.packages.${system}.default
    else if lib.hasAttr "codex" unstablePkgs
    then unstablePkgs.codex
    else if lib.hasAttr "codex" pkgs
    then pkgs.codex
    else null;
  i3Pkg = pkgs.i3;
  hmCli = inputs.home-manager.packages.${system}.home-manager;
  workspaceDefs = import ../modules/shared/workspaces.nix;
  palette = {
    bg = c.base00;
    bgAlt = c.base01;
    text = c.base05;
    accent = c.base0B;
    accent2 = c.base0D;
    warn = c.base0A;
    danger = c.base08;
    muted = c.base03;
  };
in {
  imports = [
    ../modules/home-manager
  ];

  _module.args = {
    inherit c stylixFonts palette i3Pkg hostname hmCli codexPkg;
    workspaces = workspaceDefs;
  };

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.11";
  };
  profiles = {
    core = true;
    dev = true;
    desktop = true;
    extras = true;
    ai = true;
  };
  home.sessionVariables = {
    NH_NOM = "1";
  };
  news.display = "silent";

  # home.activation.installPackages = lib.mkForce (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
  #   profile="${config.xdg.stateHome or "${config.home.homeDirectory}/.local/state"}/nix/profiles/home-manager"
  #   mkdir -p "$(dirname "$profile")"
  #   nix profile wipe-history --profile "$profile" >/dev/null 2>&1 || true
  #   nix profile remove --profile "$profile" home-manager-path >/dev/null 2>&1 || true
  #   nix profile add --profile "$profile" ${config.home.path}
  # '');

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # ------------------------------------------------------------
  # Stylix targets
  # ------------------------------------------------------------
  stylix = {
    enable = true;
    autoEnable = false;

    targets = {
      qt.enable = true;
      gtk = {
        enable = true;
        flatpakSupport.enable = true;
      };

      alacritty.enable = true;
      btop.enable = true;
      fzf.enable = true;
      #i3.enable = true;
      dunst.enable = true;
      xfce.enable = true;
      rofi.enable = true;

      starship = {
        enable = true;
        colors.enable = true;
      };

      nixvim = {
        enable = true;
        plugin = "mini.base16";
        transparentBackground = {
          main = false;
          signColumn = true;
        };
      };

      firefox = {
        enable = lib.mkDefault true;
        profileNames = [username];
      };

      #polybar.enable = true;
    };
  };

  # Packages are grouped in modules/home-manager/profiles.nix

  programs = {
    home-manager.enable = true;

    # ------------------------------------------------------------
    # Fish + plugins
    # ------------------------------------------------------------
    fish = {
      enable = true;

      shellInit = "";

      interactiveShellInit = ''
        set -g fish_greeting
        fish_default_key_bindings

        set -gx SUDO_EDITOR nvim
        set -gx EDITOR nvim
        set -gx VISUAL nvim

        set -gx GPG_TTY (tty)
        set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
        set -e SSH_AGENT_PID

        set -g fzf_fd_opts --hidden --follow --exclude .git
        set -g fzf_preview_dir_cmd 'eza --all --color=always --group-directories-first'
        set -g fzf_preview_file_cmd 'bat --style=numbers --color=always'

        set -g fzf_diff_highlighter 'delta --paging=never --width=120'
        set -g fzf_git_log_format "%C(auto)%h%d %s %C(blue)%cr %C(green)%an"

        set -g fzf_history_time_format "%Y-%m-%d %H:%M"
        set -g fzf_history_opts "--no-sort --exact"

        # Make autosuggestions visible and ensure they stay enabled
        # set -g fish_autosuggestion_enabled 1
        # set -g fish_color_autosuggestion '#8a8a8a'

        set -Ux fifc_editor nvim
        fzf_configure_bindings --directory=\ct --git_log=\cg --git_status=\cs --history=\cr --processes=\cp --variables=\cv
      '';

      shellAbbrs = {
        rebuild = "nh os switch -H ${hostname}";
        hms = "nh home switch -c ${username}@${hostname}";

        qa = "nix --option warn-dirty false run ${repoRoot}#qa";
        gcommit = "nix --option warn-dirty false run ${repoRoot}#commit";
        diffsys = "nvd diff /run/booted-system /run/current-system";

        ll = "eza -lah";
        ls = "eza -ah";

        #gs = "git status";
        #gl = "git log --oneline --decorate --graph --all";
        lg = "lazygit";

        se = "sudoedit";

        v = "nvim";
        zj = "zellij";

        nixhome = "cd ${repoRoot}/";
      };

      plugins = with pkgs.fishPlugins; [
        {
          name = "plugin-git";
          inherit (plugin-git) src;
        }
        {
          name = "fzf-fish";
          inherit (fzf-fish) src;
        }
        {
          name = "sponge";
          inherit (sponge) src;
        }
        {
          name = "fifc";
          inherit (fifc) src;
        }
        #{ name = "autopair"; src = autopair.src; }
        #{ name = "done";     src = done.src; }
        #{ name = "pisces";   src = pisces.src; }
      ];
    };

    atuin = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        auto_sync = true;
        keymap_mode = "vim-insert";
        search_mode = "fuzzy";
        style = "compact";
      };
    };

    fzf = {
      enable = true;
      enableFishIntegration = false;
    };

    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = ["--cmd" "z"];
    };

    rofi = {
      enable = true;
      terminal = "${pkgs.alacritty}/bin/alacritty";
      extraConfig = {
        show-icons = true;
        icon-theme = "Papirus-Dark";
        modi = "drun,run,window";
        drun-display-format = "{name}";
        font = "${stylixFonts.sansSerif.name} 12";
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        light = false;
        line-numbers = true;
      };
    };

    git = {
      enable = true;

      settings = {
        user = {
          # Identity
          name = "6FaNcY9";
          email = "29282675+6FaNcY9@users.noreply.github.com";

          # gpgsign Key
          signingkey = "FC8B68693AF4E0D9DC84A4D3B872E229ADE55151";
        };

        # sign keys automatically
        commit.gpgsign = true;

        init.defaultBranch = "main";
        pull.ff = "only";
        push.autoSetupRemote = true;

        core.editor = "nvim";
        diff.colorMoved = "default";
        merge.conflictstyle = "zdiff3";
        fetch.prune = true;
        rebase.autoStash = true;
      };
    };

    starship = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        add_newline = false;

        format = ''
          $directory$git_branch$git_status$nix_shell$direnv$cmd_duration
          $character
        '';

        directory = {
          format = "[   $path ]($style)";
          style = "fg:${c.base05} bg:${c.base01}";
          truncation_length = 4;
          truncation_symbol = "…/";
        };

        git_branch = {
          format = "[  $branch ]($style)";
          style = "fg:${c.base0B} bg:${c.base01}";
        };

        git_status = {
          format = "[ $all_status$ahead_behind ]($style)";
          style = "fg:${c.base0A} bg:${c.base01}";
        };

        nix_shell = {
          format = "[  $state ]($style)";
          style = "fg:${c.base0D} bg:${c.base01}";
        };

        direnv = {
          disabled = false;
          format = "[ direnv ]($style)";
          style = "fg:${c.base08} bg:${c.base01}";
        };

        cmd_duration = {
          format = "[  $duration ]($style)";
          style = "fg:${c.base0E} bg:${c.base01}";
          min_time = 500;
        };

        character = {
          success_symbol = " [](fg:${c.base0B})";
          error_symbol = " [](fg:${c.base08})";
          vimcmd_symbol = " [](fg:${c.base0A})";
        };
      };
    };

    alacritty = {
      enable = true;
      settings = {
        window = {
          dynamic_padding = true;
          decorations = "none";
        };

        scrolling.history = 10000;

        keyboard.bindings = [
          # Enter/leave Vi mods (selection /search)
          {
            key = "Space";
            mods = "Control|Shift";
            action = "ToggleViMode";
          }

          # search prompts (works vi mode)
          {
            key = "F";
            mods = "Control|Shift";
            action = "SearchForward";
          }
          {
            key = "B";
            mods = "Control|Shift";
            action = "SearchBackward";
          }

          # Copy/Paste helpers
          {
            key = "C";
            mods = "Control|Shift";
            action = "Copy";
          }
          {
            key = "V";
            mods = "Control|Shift";
            action = "Paste";
          }
        ];
      };
    };

    btop = {
      enable = true;
      settings = {
        vim_keys = true;
        update_ms = 1000;
        proc_sorting = "cpu lazy";
      };
    };
  };

  # ------------------------------------------------------------
  # Session services
  # ------------------------------------------------------------
  services = {
    # Launch nm-applet on demand via i3blocks click (see net block below)
    network-manager-applet.enable = true;
    dunst.enable = true;
    picom.enable = true;

    # Flameshot configuration
    flameshot = {
      enable = true;
      package = pkgs.flameshot;
      settings = {
        General = {
          # Theme-ish bits
          uiColor = c.base01; # panel background
          #contrastColor = c.base05;  # text/icons
          drawColor = c.base0B; # pen color
          #fillColor = c.base02;      # fills for shapes
          showSidePanelButton = true;
          showDesktopNotification = false;
          disabledTrayIcon = false; # set true if you don’t want a tray icon
          #checkForUpdates = false;
        };
        Shortcuts = {
          TYPE_COPY = "Return";
          TYPE_SAVE = "Ctrl+S";
        };
      };
    };
  };

  # ------------------------------------------------------------
  # XFCE session xml (unchanged)
  # ------------------------------------------------------------
  xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml" = {
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-session" version="1.0">
        <property name="sessions" type="empty">
          <property name="Failsafe" type="empty">
            <property name="Client0_Command" type="array">
              <value type="string" value="xfsettingsd"/>
            </property>
            <property name="Client1_Command" type="array">
              <value type="string" value="i3"/>
            </property>
            <property name="Client2_Command" type="array">
              <value type="string" value="xfce4-panel"/>
            </property>
            <property name="Client3_Command" type="array">
              <value type="string" value="xfce4-power-manager"/>
            </property>
            <property name="Client4_Command" type="array">
              <value type="string" value="thunar --daemon"/>
            </property>
          </property>
        </property>
      </channel>
    '';
  };
}
