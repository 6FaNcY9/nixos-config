# XFCE4 session configuration for i3-XFCE hybrid desktop
# Custom XML session that combines i3 window manager with XFCE components:
# - xfsettingsd: XFCE settings daemon for theme/font/display management
# - i3: Tiling window manager
# - xfce4-panel: System tray and panel (used for systray icons)
# - xfce4-power-manager: Battery/power management
# - thunar: File manager daemon for desktop icons and automount
# This XML overrides the default XFCE session to launch i3 instead of xfwm4
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.desktop.xfce-session;
in
{
  options.features.desktop.xfce-session = {
    enable = lib.mkEnableOption "XFCE4 session configuration for i3-xfce setup";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml" = {
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xfce4-session" version="1.0">
          <property name="sessions" type="empty">
            <property name="Failsafe" type="empty">
              <property name="Client0_Command" type="array">
                <value type="string" value="xfsettingsd"/>
              </property>
              <property name="Client1_Command" type="array">
                <value type="string" value="i3"/>
              </property>
              <property name="Client2_Command" type="array">
                <value type="string" value="xfce4-panel"/>
              </property>
              <property name="Client3_Command" type="array">
                <value type="string" value="xfce4-power-manager"/>
              </property>
              <property name="Client4_Command" type="array">
                <value type="string" value="thunar --daemon"/>
              </property>
            </property>
          </property>
        </channel>
      '';
    };
  };
}
