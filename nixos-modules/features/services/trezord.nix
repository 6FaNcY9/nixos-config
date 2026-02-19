# Feature: Trezor Hardware Wallet Support
# Provides: Trezord daemon for Trezor hardware wallet integration
# Dependencies: None
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.services.trezord;
in
{
  options.features.services.trezord = {
    enable = lib.mkEnableOption "Trezor hardware wallet daemon";
  };

  config = lib.mkIf cfg.enable {
    services.trezord.enable = true;
  };
}
