# Tailscale VPN — zero-config mesh networking
_: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ 41641 ];
  };
}
