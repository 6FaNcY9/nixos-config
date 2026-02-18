# Feature: Secrets Management
# Provides: sops-nix integration for encrypted secrets
# Dependencies: None
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.security.secrets;
in
{
  options.features.security.secrets = {
    enable = lib.mkEnableOption "sops-nix secrets management";
  };

  config = lib.mkIf cfg.enable {
    # sops-nix is already configured in nixos-modules/secrets.nix
    # This module just provides the feature flag
    # Actual sops configuration will be migrated here in later task
  };
}
