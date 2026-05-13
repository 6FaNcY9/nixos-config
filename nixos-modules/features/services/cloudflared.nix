# Feature: Cloudflare Tunnel
# Provides: CGNAT-safe inbound traffic via cloudflared remote-managed tunnel
# Dependencies: sops-nix (tokenFile must be a sops secret path), Caddy on upstream
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.services.cloudflared;
in
{
  options.features.services.cloudflared = {
    enable = lib.mkEnableOption "Cloudflare Tunnel ingress via cloudflared";

    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file whose sole content is the Cloudflare Tunnel token
        (plain string, no trailing newline needed). Typically a sops secret path:
          config.sops.secrets.cloudflare_tunnel_token.path
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    features.services.cloudflared.tokenFile = lib.mkDefault config.sops.secrets.cloudflare_tunnel_token.path;

    assertions = [
      {
        assertion = config.features.security.secrets.enable;
        message = "features.services.cloudflared requires features.security.secrets.enable = true — tokenFile must be a sops secret and sops-nix must be active";
      }
    ];

    users.users.cloudflared = {
      isSystemUser = true;
      group = "cloudflared";
      description = "Cloudflare Tunnel daemon";
    };
    users.groups.cloudflared = { };

    systemd.services.cloudflared = {
      description = "Cloudflare Tunnel";
      after = [
        "network-online.target"
        "sops-nix.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = "cloudflared";
        Group = "cloudflared";
        # Read token from sops secret file; export as TUNNEL_TOKEN env var.
        # cloudflared remote-managed tunnels accept TUNNEL_TOKEN instead of a
        # credentials JSON file. Cannot use EnvironmentFile because sops writes
        # the raw token value (not KEY=VALUE dotenv format) to the secret path.
        ExecStart =
          let
            startScript = pkgs.writeShellScript "cloudflared-start" ''
              export TUNNEL_TOKEN=$(< ${toString cfg.tokenFile})
              exec ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run
            '';
          in
          "${startScript}";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        # tokenFile must resolve to a path under /run (e.g. sops default /run/secrets/<name>).
        # ProtectSystem=strict makes /etc read-only but leaves /run accessible.
        ProtectSystem = "strict";
        ProtectHome = true;
        RuntimeDirectory = "cloudflared";
      };
    };
  };
}
