{palette, ...}: {
  services.polybar.settings."colors" = {
    background = "${palette.bg}";
    background-alt = "${palette.bgAlt}";
    foreground = "${palette.text}";
    accent = "${palette.accent}";
    accent2 = "${palette.accent2}";
    warn = "${palette.warn}";
    danger = "${palette.danger}";
    muted = "${palette.muted}";
  };
}
