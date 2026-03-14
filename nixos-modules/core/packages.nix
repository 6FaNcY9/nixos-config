# Core: System packages
# Always enabled (no option)
{
  lib,
  pkgs,
  ...
}:
let
  systemPackages = [
    pkgs.btrfs-progs
    pkgs.cachix # Binary cache management
    pkgs.curl
    pkgs.efibootmgr
    pkgs.git
    pkgs.vim
    pkgs.wget
    pkgs.gnupg
    pkgs.sops
    pkgs.age
    pkgs.ssh-to-age
  ];
in
{
  environment.systemPackages = systemPackages;

  # Many third-party scripts use #!/bin/bash shebangs (e.g. Claude Code plugins).
  # NixOS doesn't provide /bin/bash by default — only /bin/sh.
  # See docs/bin-bash.md for rationale, alternatives, and when the symlink is justified.
  environment.shells = [ pkgs.bash ];
  system.activationScripts.binbash = lib.stringAfter [ "stdio" ] ''
    ln -sfn ${pkgs.bash}/bin/bash /bin/bash
  '';
}
