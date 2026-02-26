# Tmux Status Bar Configuration
# Enhanced status line optimized for laptop use with battery, load, hostname, and time
#
# Layout:
#   Left:  Session name (accent, bold) | window indicator
#   Right: Battery (warn) | Load average (accent2) | Hostname (accent2) | Date/Time (accent)
#
# Color scheme uses palette.* for consistency with overall theme
{ palette, ... }:
{
  programs.tmux.extraConfig = ''
    ##### Status line (enhanced for laptop use) #####
    set -g status on
    set -g status-interval 5
    set -g status-left-length 40
    set -g status-right-length 150
    set -g status-style "fg=${palette.text},bg=${palette.bg}"
    set -g message-style "fg=${palette.text},bg=${palette.bg}"

    # Left: session name (bold) + window indicator
    set -g status-left "#[fg=${palette.accent},bold]  #S #[default]#[fg=${palette.muted}]|#[default] "

    # Right: battery + load + host + time
    # Battery: Show percentage and charging status
    # Load: Show 1-min load average
    # Host: Hostname in accent color
    # Time: Date and time in accent color
    set -g status-right "#[fg=${palette.warn}]#{?#{==:#{battery_percentage},},, #{battery_percentage} #{battery_icon}}#[default] #[fg=${palette.muted}]|#[default] #[fg=${palette.accent2}]#{?#{==:#(cat /proc/loadavg | cut -d' ' -f1),},,  #(cat /proc/loadavg | cut -d' ' -f1)}#[default] #[fg=${palette.muted}]|#[default] #[fg=${palette.accent2}] #H#[default] #[fg=${palette.muted}]|#[default] #[fg=${palette.accent}] %Y-%m-%d %H:%M#[default]"

    # Window status format
    set -g window-status-format "#[fg=${palette.muted}]#I:#W#F#[default]"
    set -g window-status-current-format "#[fg=${palette.accent},bold] #W#F#[default]"
    set -g window-status-separator " #[fg=${palette.muted}]│#[default] "
  '';
}
