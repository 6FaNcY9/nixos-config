{pkgs, ...}: {
  xsession.windowManager.i3.config.startup = [
    {
      command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      notification = false;
    }
    {
      command = "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock --ignore-sleep ${pkgs.i3lock}/bin/i3lock";
      notification = false;
    }
    {
      command = "${pkgs.blueman}/bin/blueman-applet";
      notification = false;
    }
  ];
}
