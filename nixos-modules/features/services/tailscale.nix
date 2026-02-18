# Feature: Tailscale VPN
# Provides: Secure mesh VPN networking
# Dependencies: None (standalone service)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.services.tailscale;
in
{
  options.features.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN mesh networking";

    useRoutingFeatures = lib.mkOption {
      type = lib.types.enum [
        "none"
        "client"
        "server"
        "both"
      ];
      default = "client";
      description = "Enable routing features (subnet routes, exit nodes)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Tailscale service
    services.tailscale = {
      enable = true;
      inherit (cfg) useRoutingFeatures;
    };

    # Firewall: Allow Tailscale
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ]; # Tailscale port
      checkReversePath = "loose"; # Required for Tailscale
    };

    # Persistence (if needed)
    environment.systemPackages = [ pkgs.tailscale ];
  };
}
