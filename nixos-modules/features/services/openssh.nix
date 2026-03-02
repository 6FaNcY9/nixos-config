# Feature: OpenSSH Server
# Provides: Secure SSH server with hardened defaults
# Dependencies: None
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.services.openssh;
in
{
  options.features.services.openssh = {
    enable = lib.mkEnableOption "OpenSSH server with secure defaults";

    passwordAuthentication = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow password authentication (disabled for security)";
    };

    permitRootLogin = lib.mkOption {
      type = lib.types.enum [
        "yes"
        "no"
        "prohibit-password"
        "forced-commands-only"
      ];
      default = "no";
      description = "Whether to allow root login";
      example = "prohibit-password";
    };

    keyboardInteractiveAuthentication = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow keyboard-interactive authentication";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = cfg.passwordAuthentication;
        PermitRootLogin = cfg.permitRootLogin;
        KbdInteractiveAuthentication = cfg.keyboardInteractiveAuthentication;
        MaxAuthTries = 3;
        LoginGraceTime = 30;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        AllowTcpForwarding = "no";
        LogLevel = "VERBOSE";
    };
  };
}
