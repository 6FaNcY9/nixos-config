{ lib, pkgs, config, inputs, username ? "vino", hostname ? "bandit", ... }:

let
  # Safe: Stylix palette is exposed under config.lib.stylix.colors (when Stylix is loaded)
  c = lib.attrByPath [ "lib" "stylix" "colors" "withHashtag" ] {
    # fallback (only used if Stylix isn’t loaded)
    base00 = "#262626"; base01 = "#3a3a3a"; base02 = "#4e4e4e"; base03 = "#8a8a8a";
    base04 = "#949494"; base05 = "#dab997"; base06 = "#d5c4a1"; base07 = "#ebdbb2";
    base08 = "#d75f5f"; base09 = "#ff8700"; base0A = "#ffaf00"; base0B = "#afaf00";
    base0C = "#85ad85"; base0D = "#83a598"; base0E = "#d3869b"; base0F = "#af5f5f";
  } config;

  # Safe: Stylix fonts are under config.stylix.fonts (when Stylix is loaded)
  stylixFonts = lib.attrByPath [ "stylix" "fonts" ] {
    sansSerif = { name = "Sans"; };
    monospace = { name = "Monospace"; };
  } config;

  hasCodex = lib.hasAttr "codex" pkgs;
  i3Pkg = pkgs.i3;
  hmCli = inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.home-manager;
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

  wallpaper = "${inputs.gruvbox-wallpapers}/wallpapers/brands/gruvbox-rainbow-nix.png";
in
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";
  news.display = "silent";

  programs.home-manager.enable = true;
  home.activation.installPackages = lib.mkForce (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    profile="${config.xdg.stateHome or "${config.home.homeDirectory}/.local/state"}/nix/profiles/home-manager"
    mkdir -p "$(dirname "$profile")"
    nix profile wipe-history --profile "$profile" >/dev/null 2>&1 || true
    nix profile remove --profile "$profile" home-manager-path >/dev/null 2>&1 || true
    nix profile add --profile "$profile" ${config.home.path}
  '');

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
      i3.enable = true;
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
        profileNames = [ username ];
      };
    };
  };

  # ------------------------------------------------------------
  # Firefox (userChrome.css)
  # ------------------------------------------------------------
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;

    profiles.${username} = {
      id = 0;
      isDefault = lib.mkDefault true;

      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "toolkit.tabbox.switchByScrolling" = true;
        "browser.tabs.tabMinWidth" = 120;
      };

      userChrome =
        let
          themeTemplate = builtins.readFile ./firefox/userChrome.theme.css;
          replaceColors = builtins.replaceStrings
            [ "@@base00@@" "@@base01@@" "@@base02@@" "@@base03@@" "@@base04@@" "@@base05@@" "@@base08@@" "@@base0A@@" "@@base0B@@" "@@base0D@@" ]
            [ c.base00     c.base01     c.base02     c.base03     c.base04     c.base05     c.base08     c.base0A     c.base0B     c.base0D ];
        in
        lib.mkAfter (
          (builtins.readFile ./firefox/userChrome.css)
          + "\n"
          + replaceColors themeTemplate
        );
    };
  };

  # ------------------------------------------------------------
  # Packages
  # ------------------------------------------------------------
  home.packages =
    (with pkgs; [
      yq-go delta git lazygit
      broot eza tree xfce.thunar
      ripgrep fzf fd jq gdu bat
      zoxide tmux zellij
      neofetch btop i3lock
      networkmanagerapplet curl wget
      hmCli chafa hexyl procs
      man-pages man-pages-posix
      clang gnumake pkg-config nodejs rustfmt clippy rustc cargo
      p7zip unzip zip
      brightnessctl dunst flameshot picom playerctl polkit_gnome pulseaudio
      vscode devenv feh fontconfig killall xclip
    ])
    ++ lib.optionals hasCodex [ pkgs.codex ];

  # ------------------------------------------------------------
  # Fish + plugins
  # ------------------------------------------------------------
  programs.fish = {
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
      
      set -Ux fifc_editor nvim
      fzf_configure_bindings --directory=\ct --git_log=\cg --git_status=\cs --history=\cr --processes=\cp --variables=\cv
    '';

    shellAbbrs = {
      rebuild = "sudo nixos-rebuild switch --flake ~/src/nixos-config#bandit";
      hms = "home-manager switch --flake ~/src/nixos-config#vino";
      
      ll = "eza -lah";
      
      gs = "git status";
      gl = "git log --oneline --decorate --graph --all";
      lg = "lazygit";

      se = "sudoedit";

      v = "nvim";
      zj = "zellij";

      nixos-git = "git -C ~/src/nixos-config";
    };

    plugins = with pkgs.fishPlugins; [
      { name = "plugin-git";  src = plugin-git.src; }
      { name = "fzf-fish";    src = fzf-fish.src; }
      { name = "sponge";      src = sponge.src; }
      { name = "fifc";        src = fifc.src; } 
    #{ name = "autopair"; src = autopair.src; }
    #{ name = "done";     src = done.src; }
    #{ name = "pisces";   src = pisces.src; }
   ];
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      auto_sync = true;
      keymap_mode = "vim-insert";
      search_mode = "fuzzy";
      style = "compact";
    };
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = false;
  };

  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd" "z" ];
  };

  programs.rofi = {
    enable = true;
    terminal = "${pkgs.alacritty}/bin/alacritty";
    extraConfig = {
      show-icons = true;
      modi = "drun,run,window";
      drun-display-format = "{name}";
      font = "${stylixFonts.sansSerif.name} 12";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      line-numbers = true;
    };
  };

  programs.git = {
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

  programs.starship = {
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
        success_symbol = "[\\$](fg:${c.base0B}) ";
        error_symbol = "[\\$](fg:${c.base08}) ";
        vimcmd_symbol = "[❮](fg:${c.base0A}) ";
      };
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        dynamic_padding = true;
        decorations = "none";
      };
      
      scrolling.history = 10000;

      keyboard.bindings = [
        # Enter/leave Vi mods (selection /search)
        { key = "Space"; mods = "Control|Shift"; action = "ToggleViMode"; }
        
        # search prompts (works vi mode)
        { key = "F"; mods = "Control|Shift"; action = "SearchForward"; }
        { key = "B"; mods = "Control|Shift"; action = "SearchBackward"; }

        # Copy/Paste helpers
        { key = "C"; mods = "Control|Shift"; action = "Copy"; }
        { key = "V"; mods = "Control|Shift"; action = "Paste"; }
        
        # optional: clear init_selection
        { key = "Escape"; action = "ClearSelection"; }
      ];
    };
  };

  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
      update_ms = 1000;
      proc_sorting = "cpu lazy";
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
          uiColor = c.base01;        # panel background
          #contrastColor = c.base05;  # text/icons
          drawColor = c.base0B;      # pen color
          #fillColor = c.base02;      # fills for shapes
          showSidePanelButton = true;
          showDesktopNotification = false;
          disabledTrayIcon = false;  # set true if you don’t want a tray icon
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
  # i3blocks (DAG entries to match module option type)
  # ------------------------------------------------------------
  programs.i3blocks =
    let
      /** 
      # Helper for net-popup ip informantin terminal gui
      netPopus = pkgs.writeShellScriptBin "net-popup" ''
        #!/usr/bin env bash
        set -euo pipefail

        I3MSG = "${i3Pkg}/bin/i3-msg"
        JQ = "${pkgs.jq}/bin/jq"
        XDOTOOL = "${pkgs.xdotool}/bin/xdotool"
        TERM = "${pkgs.alacritty}/bin/alacritty"
        NMTUI = "${pkgs.networkmanager}/bin/nmtui"

        CLASS = "NetPopup"
        TITLE = "netpopup"
      
        WIDTH_PX = "560"
        HEIGHT_PX = "330"
        COLS = 70
        LINES = 20
        MARGIN = 8

        # Toggle existing popup
        if "$I3MSG" -t get_tree | "$JQ" -e \
          '.. | objects | select(.window_properties? and .window_properties.class? = "'"$CLASS"'") ' \
          >/dev/null 2>&1; then
          "$I3MSG" '[class="'"$CLASS"'"] kill' >/dev/null
          exit 0
        fi

        # Mouse location + determine output under Mouse
        eval"$("$XDOTOOL" getmouselocstion --shell)" #gives X, Y, SCREEN, window_properties

             
      ''; 
      **/  
      # Generic wrapper for block
      mkBlockScript = name: body: pkgs.writeShellScriptBin "i3blocks-${name}" ''
        #!/usr/bin/env bash
        set -euo pipefail
        ${body}
      '';

      hostBlock = mkBlockScript "host" ''
        printf '  %s\n\n${palette.accent2}\n' "${hostname}"
      '';

      netBlock = mkBlockScript "net" ''
        info="$(${pkgs.networkmanager}/bin/nmcli -t -f TYPE,STATE,CONNECTION dev status | ${pkgs.gawk}/bin/awk -F: '$2=="connected"{print $1":"$3; exit}')"
        color="${palette.danger}"
        text=" 󰖪 offline"

        if test -n "$info"; then
          type="''${info%%:*}"
          name="''${info#*:}"
          icon="󰈀"
          color="${palette.accent2}"

          if test "$type" = "wifi"; then
            icon=""
            color="${palette.accent}"
          fi

          text=" $icon $name"
        fi

        printf '%s\n%s\n%s\n' "$text" "$text" "$color"
      '';

      volumeBlock = mkBlockScript "volume" ''
        sink="$(${pkgs.pulseaudio}/bin/pactl info | ${pkgs.gawk}/bin/awk -F': ' '$1=="Default Sink"{print $2}')"
        if test -z "$sink"; then sink="@DEFAULT_SINK@"; fi

        volume="$(${pkgs.pulseaudio}/bin/pactl get-sink-volume "$sink" | ${pkgs.coreutils}/bin/head -n1 | ${pkgs.gawk}/bin/awk '{gsub("%","",$5); print $5}')"
        mute="$(${pkgs.pulseaudio}/bin/pactl get-sink-mute "$sink" | ${pkgs.gawk}/bin/awk '{print $2}')"

        vol="''${volume:-0}"
        icon="󰕾"
        color="${palette.accent}"

        if test "''${mute:-no}" = "yes"; then
          icon="󰝟"
          color="${palette.danger}"
        elif test "$vol" -gt 80; then
          color="${palette.warn}"
        fi

        printf ' %s %s%%\n\n%s\n' "$icon" "$vol" "$color"
      '';

      batteryBlock = mkBlockScript "battery" ''
        bat="$(${pkgs.upower}/bin/upower -e | ${pkgs.gnugrep}/bin/grep -m1 BAT || true)"
        if test -z "$bat"; then
          printf '   n/a\n\n${palette.muted}\n'
          exit 0
        fi

        info="$(${pkgs.upower}/bin/upower -i "$bat")"
        percent="$(echo "$info" | ${pkgs.gawk}/bin/awk '/percentage/ {gsub("%","",$2); print $2}')"
        state="$(echo "$info" | ${pkgs.gawk}/bin/awk '/state/ {print $2}')"

        p="''${percent:-0}"
        icon=""
        color="${palette.accent}"

        if test "''${state:-}" = "charging"; then
          icon=""
          color="${palette.accent2}"
        elif test "''${state:-}" = "fully-charged"; then
          icon=""
        else
          if test "$p" -lt 20; then
            icon=""
            color="${palette.danger}"
          elif test "$p" -lt 40; then
            icon=""
            color="${palette.warn}"
          elif test "$p" -lt 65; then
            icon=""
          fi
        fi

        printf ' %s %s%%\n\n%s\n' "$icon" "$p" "$color"
      '';

      brightnessBlock = mkBlockScript "brightness" ''
        level="$(${pkgs.brightnessctl}/bin/brightnessctl -m | ${pkgs.coreutils}/bin/cut -d, -f4 | tr -d "%" 2>/dev/null || true)"
        lvl="''${level:-0}"

        icon="󰃝"
        color="${palette.accent2}"

        if test "$lvl" -lt 30; then
          icon="󰃞"
          color="${palette.accent}"
        elif test "$lvl" -gt 70; then
          icon="󰃟"
          color="${palette.warn}"
        fi

        printf ' %s %s%%\n\n%s\n' "$icon" "$lvl" "$color"
      '';

      timeBlock = mkBlockScript "time" ''
        now="$(${pkgs.coreutils}/bin/date '+%H:%M')"
        printf '   %s\n\n${palette.accent2}\n' "$now"
      '';

      dateBlock = mkBlockScript "date" ''
        today="$(${pkgs.coreutils}/bin/date '+%a %d %b %Y')"
        printf '   %s\n\n${palette.text}\n' "$today"
      '';
    in
    {
      enable = true;

      bars.top = {
        host = lib.hm.dag.entryAnywhere {
          command = "${hostBlock}/bin/i3blocks-host";
          interval = 600;
          separator = false;
        };

        net = lib.hm.dag.entryAfter [ "host" ] {
          command = "${netBlock}/bin/i3blocks-net";
          interval = 10;
          separator = false;
        };

        volume = lib.hm.dag.entryAfter [ "net" ] {
          command = "${volumeBlock}/bin/i3blocks-volume";
          interval = 2;
          separator = false;
        };

        battery = lib.hm.dag.entryAfter [ "volume" ] {
          command = "${batteryBlock}/bin/i3blocks-battery";
          interval = 20;
          separator = false;
        };

        brightness = lib.hm.dag.entryAfter [ "battery" ] {
          command = "${brightnessBlock}/bin/i3blocks-brightness";
          interval = 5;
          separator = false;
        };

        time = lib.hm.dag.entryAfter [ "brightness" ] {
          command = "${timeBlock}/bin/i3blocks-time";
          interval = 5;
          separator = false;
        };

        date = lib.hm.dag.entryAfter [ "time" ] {
          command = "${dateBlock}/bin/i3blocks-date";
          interval = 60;
          separator = false;
        };
      };
    };

  # ------------------------------------------------------------
  # Xsession + i3
  # ------------------------------------------------------------
  xsession = {
    enable = true;

    windowManager.i3 = {
      enable = true;
      package = i3Pkg;

      config =
        let
          mod = "Mod4";
          workspaceNames = [
            "1: " "2: " "3: " "4: " "5: " "6: " "7: " "8: " "9: "
          ];
          workspaceIndices = lib.range 1 (builtins.length workspaceNames);

          workspaceSwitch =
            builtins.listToAttrs (
              lib.lists.zipListsWith (wsName: idx: {
                name = "${mod}+${builtins.toString idx}";
                value = "workspace ${wsName}";
              }) workspaceNames workspaceIndices
            );

          workspaceMove =
            builtins.listToAttrs (
              lib.lists.zipListsWith (wsName: idx: {
                name = "${mod}+Shift+${builtins.toString idx}";
                value = "move container to workspace ${wsName}";
              }) workspaceNames workspaceIndices
            );
        in
        {
          modifier = mod;
          terminal = "alacritty";
          menu = "rofi -show drun";

          gaps = {
            inner = 10;
            outer = 0;
            smartGaps = true;
          };

          window = {
            border = 3;
            titlebar = false;
          };

          colors = lib.mkForce {
            focused = {
              border = c.base0A;
              background = c.base01;
              text = c.base07;
              indicator = c.base0A;
              childBorder = c.base0A;
            };

            focusedInactive = {
              border = c.base03;
              background = c.base00;
              text = c.base05;
              indicator = c.base03;
              childBorder = c.base03;
            };

            unfocused = {
              border = c.base02;
              background = c.base00;
              text = c.base04;
              indicator = c.base02;
              childBorder = c.base02;
            };

            urgent = {
              border = c.base08;
              background = c.base00;
              text = c.base07;
              indicator = c.base08;
              childBorder = c.base08;
            };
          };

          workspaceAutoBackAndForth = true;

          startup = [
            { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; notification = false; }
            { command = "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock --ignore-sleep ${pkgs.i3lock}/bin/i3lock"; notification = false; }
            { command = "${pkgs.feh}/bin/feh --bg-fill /home/vino/Pictures/gruvbox-rainbow-nix.png"; notification = false; }
          ];

          assigns = {
            "${builtins.elemAt workspaceNames 0}" = [ { class = "firefox"; } { class = "Firefox"; } ];
            "${builtins.elemAt workspaceNames 1}" = [ { class = "Alacritty"; } ];
            "${builtins.elemAt workspaceNames 2}" = [ { class = "Code"; } ];
            "${builtins.elemAt workspaceNames 3}" = [ { class = "Thunar"; } ];
          };

          bars = [
            ({
              position = "top";
              statusCommand = "${pkgs.i3blocks}/bin/i3blocks -c ${config.xdg.configHome}/i3blocks/top";
              colors = {
                background = c.base00;
                statusline = c.base05;
                separator = c.base03;

                focusedWorkspace = {
                  border = c.base0A;
                  background = c.base01;
                  text = c.base07;
                };

                activeWorkspace = {
                  border = c.base03;
                  background = c.base00;
                  text = c.base05;
                };

                inactiveWorkspace = {
                  border = c.base02;
                  background = c.base00;
                  text = c.base04;
                };

                urgentWorkspace = {
                  border = c.base08;
                  background = c.base00;
                  text = c.base07;
                };

                bindingMode = {
                  border = c.base09;
                  background = c.base00;
                  text = c.base07;
                };
              };
            } // config.stylix.targets.i3.exportedBarConfig)
          ];

          keybindings = lib.mkOptionDefault (
            let
              directionalFocus = {
                "${mod}+j" = "focus left";  "${mod}+k" = "focus down";
                "${mod}+l" = "focus up";    "${mod}+semicolon" = "focus right";
                "${mod}+Left" = "focus left"; "${mod}+Down" = "focus down";
                "${mod}+Up" = "focus up";     "${mod}+Right" = "focus right";
              };

              directionalMove = {
                "${mod}+Shift+j" = "move left";  "${mod}+Shift+k" = "move down";
                "${mod}+Shift+l" = "move up";    "${mod}+Shift+semicolon" = "move right";
                "${mod}+Shift+Left" = "move left"; "${mod}+Shift+Down" = "move down";
                "${mod}+Shift+Up" = "move up";     "${mod}+Shift+Right" = "move right";
              };

              layoutBindings = {
                "${mod}+h" = "split horizontal";
                "${mod}+v" = "split vertical";
                "${mod}+e" = "layout toggle split";
                "${mod}+s" = "layout stacking";
                "${mod}+w" = "layout tabbed";
                "${mod}+f" = "fullscreen toggle";
                "${mod}+space" = "focus mode_toggle";
                "${mod}+Shift+space" = "floating toggle";
                "${mod}+a" = "focus parent";
                "${mod}+Shift+a" = "focus child";
              };

              systemBindings = {
                "${mod}+Return" = "exec alacritty";
                "${mod}+d" = "exec rofi -show drun";
                "${mod}+Shift+q" = "kill";
                "${mod}+Shift+c" = "reload";
                "${mod}+Shift+r" = "restart";
                "${mod}+Shift+x" = "exec ${pkgs.i3lock}/bin/i3lock";
                "${mod}+Shift+z" = "exec systemctl suspend";
                "${mod}+Shift+b" = "exec systemctl reboot";
                "${mod}+Shift+p" = "exec systemctl poweroff";
                "${mod}+Shift+e" = "exec i3-nagbar -t warning -m 'Exit i3?' -b 'Yes' 'i3-msg exit'";
                "${mod}+r" = "mode \"resize\"";

                "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui";

                "XF86AudioRaiseVolume" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
                "XF86AudioLowerVolume" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
                "XF86AudioMute" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";

                "XF86MonBrightnessUp" = "exec --no-startup-id ${pkgs.brightnessctl}/bin/brightnessctl set +10%";
                "XF86MonBrightnessDown" = "exec --no-startup-id ${pkgs.brightnessctl}/bin/brightnessctl set 10%-";

                "XF86AudioPlay" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl play-pause";
                "XF86AudioNext" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl next";
                "XF86AudioPrev" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl previous";
              };
            in
            directionalFocus
            // directionalMove
            // layoutBindings
            // systemBindings
            // workspaceSwitch
            // workspaceMove
          );

          modes = lib.mkOptionDefault {
            resize = {
              "h" = "resize shrink width 10 px or 10 ppt";
              "j" = "resize grow height 10 px or 10 ppt";
              "k" = "resize shrink height 10 px or 10 ppt";
              "l" = "resize grow width 10 px or 10 ppt";
              "Left" = "resize shrink width 10 px or 10 ppt";
              "Down" = "resize grow height 10 px or 10 ppt";
              "Up" = "resize shrink height 10 px or 10 ppt";
              "Right" = "resize grow width 10 px or 10 ppt";
              "Return" = "mode default";
              "Escape" = "mode default";
            };
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

  # ------------------------------------------------------------
  # NixVim (keymaps fixed to use `options = { ...; }`)
  # ------------------------------------------------------------
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
    
    # extraPackages = with pkgs; [
    #   clang
    #   gcc
    # ];

    extraPlugins = with pkgs.vimPlugins; [
      vim-matchup
      rainbow-delimiters-nvim
      cmp-cmdline
    ];
    
    extraConfigLua = ''
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
        cmp.setup.cmdline(":", {
          mapping = cmp.mapping.preset.cmdline(),
          sources = cmp.config.sources(
            { { name = "path" } },
            { { name = "cmdline" } }
          ),
        })

        cmp.setup.cmdline("/", {
          mapping = cmp.mapping.preset.cmdline(),
          sources = { { name = "buffer" } },
        })
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
            horizontal = { preview_width = 0.55; };
            vertical = { mirror = true; };
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
            "nix"
            "bash"
            "fish"
            "lua"
            "vim"
            "vimdoc"
            "regex"
            "json"
            "yaml"
            "toml"
            "markdown"
            "markdown_inline"
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
          numhl = true;       # tint line numbers instead of using signs
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

      which-key.enable = true;
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
            highlight = [ "IblScope" ];
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
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
            { name = "luasnip"; }
          ];
        };
      };

      lsp = {
        enable = true;

        servers = {
          pyright.enable = true;
          lua_ls.enable = true;
          nixd.enable = true;
          bashls.enable = true;
          jsonls.enable = true;
          yamlls.enable = true;
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
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; options = { silent = true; }; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<cr>"; options = { silent = true; }; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<cr>"; options = { silent = true; }; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope help_tags<cr>"; options = { silent = true; }; }
      { mode = "n"; key = "<leader>fe"; action = "<cmd>Neotree toggle<cr>"; options = { silent = true; desc = "Toggle tree"; }; }
      { mode = "n"; key = "<leader>tt"; action = "<cmd>ToggleTerm<cr>"; options = { silent = true; desc = "Floating terminal"; }; }
      { mode = "n"; key = "<leader>fm"; action = "<cmd>lua vim.lsp.buf.format({ async = true })<cr>"; options = { silent = true; desc = "Format"; }; }
    ];
  };
}
