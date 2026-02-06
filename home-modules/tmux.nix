{
  lib,
  pkgs,
  palette,
  ...
}: let
  # If nixpkgs already has tmuxPlugins.tmux-which-key (it usually does),
  # this will work as-is. If not, see the fallback snippet below.
  wkPlugin = pkgs.tmuxPlugins.tmux-which-key;

  # Helper: YAML config for tmux-which-key (XDG mode).
  wkYaml = lib.generators.toYAML {} {
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
            command = "select-pane -t :.+";  # note the dot after :
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
      {separator = true;}
      {
        name = "Reload tmux config";
        key = "r";
        command = "source-file ~/.config/tmux/tmux.conf \\; display-message 'tmux reloaded'";
      }
      {
        name = "Kill tmux server";
        key = "K";
        command = "confirm-before -p 'kill-server? (y/n)' kill-server";
      }
    ];
  };
in {
  programs.tmux = {
    enable = true;

    # HM-typed options (safe defaults)
    mouse = true;
    keyMode = "vi";
    historyLimit = 50000;
    terminal = "tmux-256color";

    # Plugins: Home Manager will append run-shell lines for them.
    # NOTE: tmux-continuum should be last because it hooks status-right and can be broken
    # by themes/plugins that overwrite status-right. :contentReference[oaicite:4]{index=4}
    plugins = [
      # Sensible defaults (optional but recommended if available)
      pkgs.tmuxPlugins.sensible

      # Keybinding helper (which-key style popup menus). :contentReference[oaicite:5]{index=5}
      {
        plugin = wkPlugin;
        extraConfig = ''
          # Use XDG paths so config lives under ~/.config (works well on declarative systems). :contentReference[oaicite:6]{index=6}
          set -g @tmux-which-key-xdg-enable 1

          # Optional: if you don't want YAML->init rebuild on each tmux start:
          set -g @tmux-which-key-disable-autobuild 1
        '';
      }

      # Clipboard yank in copy-mode. :contentReference[oaicite:7]{index=7}
      pkgs.tmuxPlugins.yank

      # Session restore/save. :contentReference[oaicite:8]{index=8}
      pkgs.tmuxPlugins.resurrect

      # Autosave + auto-restore (requires resurrect). :contentReference[oaicite:9]{index=9}
      pkgs.tmuxPlugins.continuum
    ];

    extraConfig = ''
      ##### Core ergonomics #####
      # Prefix: C-a (common), keep C-b as send-prefix
      set -g prefix C-a
      unbind C-b
      bind C-a send-prefix

      # Fast reload (also available in which-key menu)
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux reloaded"

      # Vi copy-mode and better selection keys
      setw -g mode-keys vi
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-selection-and-cancel

      # Make splits use current path
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Pane navigation (vim-ish)
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Resize panes quickly
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      ##### Status line (minimal; customize freely) #####
      set -g status on
      set -g status-interval 2
      set -g status-left-length 40
      set -g status-right-length 120
      set -g status-style "fg=${palette.text},bg=${palette.bg}"
      set -g message-style "fg=${palette.text},bg=${palette.bg}"

      # Left: session + window list
      set -g status-left "#[fg=${palette.text},bold] #S #[default]"

      # Right: host + time (continuum may append/hook here; keep it simple)
      set -g status-right "#[fg=${palette.accent2}]#H#[default]  #[fg=${palette.accent}]%Y-%m-%d %H:%M#[default]"

      ##### Plugin-specific settings #####
      # continuum: enable auto-restore
      set -g @continuum-restore "on"

      # resurrect: include pane contents? (commented; enable if you want it)
      # set -g @resurrect-capture-pane-contents "on"
    '';
  };

  # Dependencies commonly needed for the included plugins / workflows:
  home.packages = with pkgs; [ 
    python3
    wl-clipboard
    xclip
  ];

  # Write the which-key YAML config into XDG config path.
  # tmux-which-key supports XDG locations when @tmux-which-key-xdg-enable is set. :contentReference[oaicite:12]{index=12}
  xdg.configFile."tmux/plugins/tmux-which-key/config.yaml".text = wkYaml;
}
