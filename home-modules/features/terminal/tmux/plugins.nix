# Tmux Plugins Configuration
# Plugin ecosystem for enhanced tmux functionality
#
# Plugins:
#   sensible      - Sensible tmux defaults
#   tmux-which-key - Which-key style popup menu for keybinding discovery (XDG config)
#   battery       - Battery status with emoji indicators (🔋/🪫/🔌/⚡)
#   yank          - Clipboard integration in copy mode
#   resurrect     - Session save/restore
#   continuum     - Automatic session save with auto-restore on startup

{
  lib,
  pkgs,
  ...
}:
let
  # If nixpkgs already has tmuxPlugins.tmux-which-key (it usually does),
  # this will work as-is. If not, see the fallback snippet below.
  wkPlugin = pkgs.tmuxPlugins.tmux-which-key;

  # Helper: YAML config for tmux-which-key (XDG mode).
  wkYaml = lib.generators.toYAML { } {
    command_alias_start_index = 200;

    # Default bindings (as upstream): prefix+Space and optionally Ctrl+Space.
    keybindings = {
      prefix_table = "Space";
      root_table = "C-Space";
    };

    title = {
      style = "align=centre,bold";
      prefix = "tmux";
      prefix_style = "fg=green,align=centre,bold";
    };

    # Keep this menu small at first; expand as you learn what you actually use.
    # Keys here are mnemonic: w=windows, p=panes, s=session, r=reload, q=quit
    items = [
      {
        name = "+Windows";
        key = "w";
        menu = [
          {
            name = "New window";
            key = "c";
            command = "new-window";
          }
          {
            name = "Next window";
            key = "n";
            command = "next-window";
            transient = true;
          }
          {
            name = "Prev window";
            key = "p";
            command = "previous-window";
            transient = true;
          }
          {
            name = "Find window";
            key = "f";
            command = "command-prompt -p 'find:' 'find-window %%'";
          }
          {
            name = "Rename window";
            key = "r";
            command = "command-prompt -I '#W' -p 'rename:' 'rename-window %%'";
          }
        ];
      }
      {
        name = "+Panes";
        key = "p";
        menu = [
          {
            name = "Split horizontal";
            key = "/";
            command = "split-window -h -c '#{pane_current_path}'";
          }
          {
            name = "Split vertical";
            key = "-";
            command = "split-window -v -c '#{pane_current_path}'";
          }
          {
            name = "Next pane";
            key = "Tab";
            command = "select-pane -t :.+"; # note the dot after :
            transient = true;
          }
          {
            name = "Swap pane";
            key = "s";
            command = "swap-pane -D";
            transient = true;
          }
          {
            name = "Zoom";
            key = "z";
            command = "resize-pane -Z";
            transient = true;
          }
        ];
      }
      {
        name = "+Session";
        key = "s";
        menu = [
          {
            name = "New session";
            key = "n";
            command = "command-prompt -p 'new session:' 'new-session -s %%'";
          }
          {
            name = "Switch client";
            key = "s";
            command = "choose-tree -Zs";
          }
          {
            name = "Rename session";
            key = "r";
            command = "command-prompt -I '#S' -p 'rename:' 'rename-session %%'";
          }
        ];
      }
      { separator = true; }
      {
        name = "Reload tmux config";
        key = "r";
        command = "source-file $XDG_CONFIG_HOME/tmux/tmux.conf \\; display-message 'tmux reloaded'";
      }
      {
        name = "Kill tmux server";
        key = "K";
        command = "confirm-before -p 'kill-server? (y/n)' kill-server";
      }
    ];
  };
in
{
  programs.tmux = {
    # Plugins: Home Manager will append run-shell lines for them.
    # NOTE: tmux-continuum should be last because it hooks status-right and can be broken
    # by themes/plugins that overwrite status-right. :contentReference[oaicite:4]{index=4}
    plugins = [
      # Sensible defaults (optional but recommended if available)
      pkgs.tmuxPlugins.sensible

      # Keybinding helper (which-key style popup menus)
      {
        plugin = wkPlugin;
        extraConfig = ''
          # Use XDG paths so config lives under ~/.config (works well on declarative systems)
          set -g @tmux-which-key-xdg-enable 1

          # Optional: if you don't want YAML->init rebuild on each tmux start
          set -g @tmux-which-key-disable-autobuild 1
        '';
      }

      # Battery status indicator
      {
        plugin = pkgs.tmuxPlugins.battery;
        extraConfig = ''
          # Battery icons
          set -g @batt_icon_charge_tier8 '🔋'
          set -g @batt_icon_charge_tier7 '🔋'
          set -g @batt_icon_charge_tier6 '🔋'
          set -g @batt_icon_charge_tier5 '🔋'
          set -g @batt_icon_charge_tier4 '🔋'
          set -g @batt_icon_charge_tier3 '🔋'
          set -g @batt_icon_charge_tier2 '🪫'
          set -g @batt_icon_charge_tier1 '🪫'
          set -g @batt_icon_status_charged '🔌'
          set -g @batt_icon_status_charging '⚡'
          set -g @batt_icon_status_discharging '🔋'
        '';
      }

      # Clipboard yank in copy-mode
      pkgs.tmuxPlugins.yank

      # Session restore/save
      pkgs.tmuxPlugins.resurrect

      # Autosave + auto-restore (requires resurrect)
      pkgs.tmuxPlugins.continuum
    ];

    extraConfig = ''
      ##### Plugin-specific settings #####
      # continuum: enable auto-restore
      set -g @continuum-restore "on"

      # resurrect: include pane contents? (commented; enable if you want it)
      # set -g @resurrect-capture-pane-contents "on"
    '';
  };

  # xclip is in profiles.nix desktopPkgs; wl-clipboard not needed (X11, not Wayland)

  # Write the which-key YAML config into XDG config path.
  # tmux-which-key supports XDG locations when @tmux-which-key-xdg-enable is set.
  xdg.configFile."tmux/plugins/tmux-which-key/config.yaml".text = wkYaml;
}
