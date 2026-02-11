_: {
  programs.tmux.extraConfig = ''
    ##### Core ergonomics #####
    # Prefix: C-a (common), keep C-b as send-prefix
    set -g prefix C-a
    unbind C-b
    bind C-a send-prefix

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
