{ cfgLib }:
let
  inherit (cfgLib) mkPolybarIcon;
in
{
  xwindow = mkPolybarIcon 983523;
  time = mkPolybarIcon 983277;
  host = mkPolybarIcon 989770;
  cpu = mkPolybarIcon 62652;
  temp = mkPolybarIcon 61227;
  memory = mkPolybarIcon 983899;
  volume = mkPolybarIcon 984446;
  muted = mkPolybarIcon 984449;
  power = mkPolybarIcon 984101;
  autotiling = mkPolybarIcon 984429;
  networkConnected = mkPolybarIcon 984489;
  networkDisconnected = mkPolybarIcon 984490;
  lanConnected = mkPolybarIcon 983552;
  lanDisconnected = mkPolybarIcon 983554;
  batteryCharging = mkPolybarIcon 983172;
  batteryDischarging = mkPolybarIcon 983182;
  batteryFull = mkPolybarIcon 983161;
}
