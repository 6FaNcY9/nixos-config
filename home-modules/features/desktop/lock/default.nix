{
  config,
  lib,
  pkgs,
  palette,
  cfgLib,
  ...
}:
let
  cfg = config.features.desktop.lock;

  # Strip the '#' prefix from palette colors for i3lock-color
  stripHash = color: builtins.substring 1 6 color;

  lockScript = cfgLib.mkShellScript {
    inherit pkgs;
    name = "lock-screen";
    body = ''
      ${pkgs.maim}/bin/maim /tmp/lockscreen.png
      ${pkgs.imagemagick}/bin/convert /tmp/lockscreen.png -blur 0x8 /tmp/lockscreen.png
      ${pkgs.i3lock-color}/bin/i3lock-color \
        --image=/tmp/lockscreen.png \
        --inside-color=00000000 \
        --ring-color=${stripHash palette.muted}ff \
        --keyhl-color=${stripHash palette.accent}ff \
        --bshl-color=${stripHash palette.danger}ff \
        --separator-color=00000000 \
        --ringver-color=${stripHash palette.accent}ff \
        --ringwrong-color=${stripHash palette.danger}ff \
        --line-uses-ring \
        --ind-pos="w/2:h/2" \
        --radius=120 \
        --ring-width=8 \
        --time-str="%H:%M:%S" \
        --time-color=${stripHash palette.text}ff \
        --time-size=48 \
        --time-pos="w/2:h/2-80" \
        --date-str="%A, %d %B" \
        --date-color=${stripHash palette.muted}ff \
        --date-size=18 \
        --date-pos="w/2:h/2+60" \
        --verif-text="Verifying..." \
        --wrong-text="Wrong!" \
        --noinput-text="" \
        --clock \
        --pass-media-keys \
        --pass-screen-keys
      rm -f /tmp/lockscreen.png
    '';
  };
in
{
  options.features.desktop.lock = {
    enable = lib.mkEnableOption "desktop lock screen with i3lock-color";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ lockScript ];
  };
}
