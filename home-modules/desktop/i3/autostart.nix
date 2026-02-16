{ pkgs, ... }:
{
  xsession.windowManager.i3.config.startup = [
    {
      command = "${pkgs.autotiling}/bin/autotiling";
      always = true;
      notification = false;
    }
    {
      command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      notification = false;
    }
    {
      command = "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock --ignore-sleep -- lock-screen";
      always = false;
      notification = false;
    }
    {
      command = "${pkgs.xautolock}/bin/xautolock -time 5 -locker lock-screen -killtime 10 -killer '${pkgs.xset}/bin/xset dpms force off'";
      always = false;
      notification = false;
    }
    {
      command = "${pkgs.blueman}/bin/blueman-applet";
      notification = false;
    }
  ];
}
