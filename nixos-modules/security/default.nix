# Module: security/default.nix
# Purpose: Aggregator for security-related modules
#
# Structure:
#   - sysctl.nix: Kernel parameter hardening
#
# Future: AppArmor, USBGuard, audit rules, etc.
{
  imports = [
    ./sysctl.nix
    ./apparmor.nix
    ./usb-guard.nix
    ./audit.nix
  ];
}
