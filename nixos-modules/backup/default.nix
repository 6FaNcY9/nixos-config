# Module: backup/default.nix
# Purpose: Aggregator for backup system components
#
# Structure:
#   - options.nix: Backup configuration options
#   - power-check.nix: Battery-aware power management
#   - restic.nix: Restic service configuration
#
# This replaces the monolithic backup.nix (425 lines → 3 focused modules)
{
  imports = [
    ./options.nix
    ./power-check.nix
    ./restic.nix
  ];
}
