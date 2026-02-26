# i3 autostart programs - Launched when i3 session starts
# - autotiling: Auto-switch split direction based on window dimensions
# - polkit-gnome: Authentication agent for privilege escalation prompts
# - xss-lock: Screen locker integration (--transfer-sleep-lock ensures lock before suspend)
# - xautolock: Idle timer (5min → lock, 10min → DPMS off)

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
      # xss-lock: --transfer-sleep-lock makes lock fd available to systemd-logind
      # --ignore-sleep prevents double-locking on wakeup
      command = "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock --ignore-sleep -- lock-screen";
      always = false;
      notification = false;
    }
    {
      # xautolock: 5min idle → lock, 10min more → turn off display
      command = "${pkgs.xautolock}/bin/xautolock -time 5 -locker lock-screen -killtime 10 -killer '${pkgs.xset}/bin/xset dpms force off'";
      always = false;
      notification = false;
    }
  ];
}
