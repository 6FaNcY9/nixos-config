# Module: security/usb-guard.nix
# Purpose: USB device control via usbguard (opt-in)
#
# Notes:
# - Disabled by default
# - When enabled with enforce=true, unknown devices are blocked
# - Start in allow mode to learn device IDs, then enforce
{
  lib,
  config,
  ...
}: let
  cfg = config.security.hardening.usbguard;

  allowRules =
    (lib.optional cfg.allowHid "allow with-interface 03:00:00")
    ++ (lib.optional cfg.allowHid "allow with-interface 03:01:00")
    ++ (lib.optional cfg.allowStorage "allow with-interface 08:06:50")
    ++ (map (id: "allow id ${id}") cfg.allowedDevices);

  rulesText = lib.concatStringsSep "\n" allowRules;
  implicitPolicy = if cfg.enforce then "block" else "allow";

  hasRules = allowRules != [];
  finalRules = if hasRules then rulesText else "# No explicit allow rules";
in {
  options.security.hardening.usbguard = {
    enable = lib.mkEnableOption "USBGuard device control";

    enforce = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Block unknown devices when true (recommended after learning)";
    };

    allowHid = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow standard USB HID devices (keyboard/mouse)";
    };

    allowStorage = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow USB mass storage devices";
    };

    allowedDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Explicitly allowed USB device IDs (e.g., 0781:5581)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.usbguard = {
      enable = true;
      implicitPolicyTarget = implicitPolicy;
      rules = finalRules;
    };
  };
}
