# Core: System packages
# Always enabled (no option)
{
  lib,
  pkgs,
  ...
}:
let
  systemPackages =
    let
      p = pkgs;
    in
    [
      p.btrfs-progs
      p.cachix # Binary cache management
      p.curl
      p.efibootmgr
      p.git
      p.snapper
      p.vim
      p.wget
      p.gnupg
      p.sops
      p.age
      p.ssh-to-age
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
