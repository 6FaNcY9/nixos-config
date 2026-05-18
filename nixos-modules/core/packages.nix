# Core: System packages
# Always enabled (no option)
{
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.cachix # Binary cache management
    pkgs.curl
    pkgs.efibootmgr
    pkgs.git
    pkgs.vim
    pkgs.wget
    pkgs.gnupg
    pkgs.sops
    pkgs.age
    pkgs.file
    pkgs.ssh-to-age
    pkgs.ntfs3g # NTFS write support for root (mount.ntfs-3g helper in system PATH)
  ];

  # Many third-party scripts use #!/bin/bash shebangs (e.g. Claude Code plugins).
  # NixOS doesn't provide /bin/bash by default — only /bin/sh.
  # See docs/bin-bash.md for rationale, alternatives, and when the symlink is justified.
  environment.shells = [ pkgs.bash ];
  system.activationScripts.binbash = lib.stringAfter [ "stdio" ] ''
    ln -sfn ${pkgs.bash}/bin/bash /bin/bash
  '';
}
