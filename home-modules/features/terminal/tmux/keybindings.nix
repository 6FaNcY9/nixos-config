# Tmux Keybindings Configuration
# Ergonomic prefix and vim-style navigation
#
# Prefix: C-Space (replaces default C-b for easier reach)
#
# Key bindings:
#   r         - Reload tmux config
#   |         - Split window horizontally (keeps current path)
#   -         - Split window vertically (keeps current path)
#   h/j/k/l   - Navigate panes (vim-style)
#   H/J/K/L   - Resize panes (repeatable with -r flag)
#
# Vi copy mode:
#   v         - Begin selection
#   y         - Copy selection and cancel

_: {
  programs.tmux.extraConfig = ''
    ##### Core ergonomics #####
    # Prefix: C-Space
    set -g prefix C-Space
    unbind C-b
    bind C-Space send-prefix

    # Fast reload (also available in which-key menu)
    bind r source-file $XDG_CONFIG_HOME/tmux/tmux.conf \; display-message "tmux reloaded"

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
  '';
}
