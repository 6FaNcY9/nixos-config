# Transparent TOR routing
#
# Routes all locally-generated TCP and DNS traffic through TOR using
# nftables NAT rules in a dedicated systemd-managed table.
#
# Usage (bandit/default.nix):
#   features.security.tor-routing.enable = true;
#   features.security.tor-routing.excludedUIDs = [ "vino" ]; # bypass TOR for this user
#
# How it works:
#   1. TOR daemon listens on TransPort (9040) and DNSPort (9053)
#   2. A separate systemd service adds an nftables 'tor-routing' table
#      with an output hook that redirects all TCP → 9040 and DNS → 9053
#   3. The tor UID is always exempted to prevent routing loops
#   4. The routing table is removed when TOR stops (no unencrypted leaks)
#   5. The table is re-added when nftables is reloaded (nixos-rebuild switch)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.security.tor-routing;
  nft = "${pkgs.nftables}/bin/nft";

  # Shell lines that exempt each extra UID from TOR routing
  uidExcludeRules = lib.concatMapStringsSep "\n" (
    uid: "  ${nft} 'add rule ip tor-routing output meta skuid \"${uid}\" return'"
  ) cfg.excludedUIDs;
in
{
  options.features.security.tor-routing = {
    enable = lib.mkEnableOption "transparent TOR routing (all TCP and DNS traffic routed through TOR)";

    transparentPort = lib.mkOption {
      type = lib.types.port;
      default = 9040;
      description = "TOR TransPort — the port where TOR accepts transparently proxied TCP connections.";
    };

    dnsPort = lib.mkOption {
      type = lib.types.port;
      default = 9053;
      description = "TOR DNSPort — all DNS queries are redirected here to prevent DNS leaks.";
    };

    excludedUIDs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "vino" ];
      description = "Extra usernames or UIDs to exempt from TOR routing. The 'tor' user is always exempted.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Sanity check: we enable nftables below, but guard against someone
    # force-disabling it after the fact.
    assertions = [
      {
        assertion = config.networking.nftables.enable;
        message = ''
          features.security.tor-routing requires networking.nftables.enable = true.
          This is set automatically by the module — do not override it with lib.mkForce false.
        '';
      }
    ];

    # ── TOR daemon ─────────────────────────────────────────────────────────────
    # client.enable sets up the SOCKS listener on 9050.
    # TransPort and DNSPort are configured manually so they honour our options
    # (using client.transparentProxy.enable / client.dns.enable would hardcode
    # the ports and conflict with settings.* when non-default values are used).
    services.tor = {
      enable = true;
      client.enable = true;
      settings = {
        TransPort = [
          {
            addr = "127.0.0.1";
            port = cfg.transparentPort;
          }
        ];
        DNSPort = [
          {
            addr = "127.0.0.1";
            port = cfg.dnsPort;
          }
        ];
        # Rewrite .onion hostnames to TOR's virtual IP range so they are
        # routable before the TransPort rewrites the destination.
        AutomapHostsOnResolve = true;
        VirtualAddrNetworkIPv4 = "10.192.0.0/10";
      };
    };

    # ── nftables backend ───────────────────────────────────────────────────────
    # Required for socket-owner matching (meta skuid) used to exempt the tor
    # daemon from its own redirect rules.
    networking.nftables.enable = true;

    # ── routing table systemd service ─────────────────────────────────────────
    # Adds a dedicated 'tor-routing' nftables table that intercepts all
    # locally-generated traffic and redirects it through TOR.
    #
    # Lifecycle:
    #   • starts after nftables.service and tor.service are ready
    #   • stops (removing rules) when tor.service stops — traffic will fail
    #     cleanly rather than leak unencrypted
    #   • restarts when nftables.service restarts (nixos-rebuild switch
    #     flushes the main ruleset, so we re-add our table afterwards)
    systemd.services.nftables-tor-routing = {
      description = "TOR transparent proxy nftables routing rules";
      wantedBy = [ "multi-user.target" ];
      after = [
        "nftables.service"
        "tor.service"
      ];
      requires = [
        "nftables.service"
        "tor.service"
      ];
      # Remove our table whenever TOR stops (prevents routing to a closed port)
      bindsTo = [ "tor.service" ];
      # Re-add our table whenever nftables is reloaded / restarted
      partOf = [ "nftables.service" ];

      script = ''
        # (Re-)create table — delete first to keep the operation idempotent
        ${nft} delete table ip tor-routing 2>/dev/null || true
        ${nft} add table ip tor-routing

        # output chain — intercepts locally-generated traffic at priority -100
        # (before the main conntrack / filter chains)
        ${nft} 'add chain ip tor-routing output { type nat hook output priority -100; policy accept; }'

        # Always exempt the tor daemon itself — otherwise we get a routing loop
        ${nft} 'add rule ip tor-routing output meta skuid tor return'

        # Exempt any additional UIDs requested by the operator
        ${uidExcludeRules}

        # Skip loopback traffic (already local — no TOR tunnelling needed)
        ${nft} 'add rule ip tor-routing output oif lo return'

        # Redirect DNS (port 53, both TCP and UDP) → TOR DNSPort
        # This prevents DNS leaks regardless of the system resolver configuration.
        ${nft} 'add rule ip tor-routing output meta l4proto { tcp, udp } th dport 53 redirect to :${toString cfg.dnsPort}'

        # Redirect all remaining TCP connections → TOR TransPort
        ${nft} 'add rule ip tor-routing output meta l4proto tcp redirect to :${toString cfg.transparentPort}'
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # The '-' prefix tells systemd to ignore a non-zero exit code here,
        # so stopping the service succeeds even if the table was already gone.
        ExecStop = "-${nft} delete table ip tor-routing";
      };
    };

    # ── DNS leak prevention ────────────────────────────────────────────────────
    # Belt-and-suspenders: point the system resolver at localhost so that
    # applications querying 127.0.0.1:53 are also caught by the nftables rule.
    # Priority 900 is below mkDefault (1000) so explicit user overrides win.
    networking.nameservers = lib.mkOverride 900 [ "127.0.0.1" ];

    # If systemd-resolved is active, strip fallback upstream servers so it
    # cannot bypass TOR for unresolved names.
    services.resolved.fallbackDns = lib.mkOverride 900 [ ];
  };
}
