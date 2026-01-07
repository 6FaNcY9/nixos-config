# nixos-config

Personal NixOS flake for a Framework 13 AMD laptop (`bandit`) with Home Manager (`vino`). The system layers i3 on top of XFCE services, themed via Stylix (Gruvbox dark), and ships a Nixvim-based editor setup.

## Layout
- `flake.nix` – pins NixOS 25.11, Home Manager, Stylix, nixvim; exports `nixosConfigurations.bandit`, `homeConfigurations.vino`, formatter, and an optional Flask dev shell.
- `configuration.nix` – host settings: GRUB on EFI, latest kernel, resume offsets for Btrfs swap, Snapper/Btrfs maintenance, NetworkManager + firewall, fail2ban, PipeWire, fish as default shell, Docker, i3 + XFCE session, font stack, base packages.
- `hardware-configuration.nix` – generated hardware profile and Btrfs subvolume layout (/, /home, /nix, /var, /swap, snapshots) plus boot UUIDs.
- `home.nix` – Home Manager profile: Stylix targets (gtk, i3, xfce, rofi, starship, nixvim, firefox), Firefox userChrome override, package set (CLIs, dev tools, desktop utilities), fish setup with abbreviations, Atuin/Zoxide/direnv/fzf, i3 config, XFCE session XML, and detailed nixvim plugin stack (LSP, Telescope, gitsigns, neo-tree, toggleterm, indent guides, etc.).
- `modules/stylix-common.nix` – shared Stylix palette/fonts (JetBrains Mono + Nerd Font fallback, Gruvbox dark).
- `modules/stylix-nixos.nix` – NixOS-only Stylix tweaks (GRUB theming, HM integration knobs).
- `modules/workspaces.nix` – shared i3 workspace name/icon list.
- `firefox/` – userChrome.css for JetBrainsMono UI fonts and theme template hydrated by Stylix colors.
- `nixFilesOld/` – archived copy of a previous layout (flake + configs).

## Usage
- System switch: `sudo nixos-rebuild switch --flake .#bandit`
- Home-only switch: `home-manager switch --flake .#vino`
- Formatter: `nix fmt` (uses `alejandra`).
- Optional dev shell: `nix develop .#flask`

## Maintenance
- Enter maintenance shell: `nix develop .#maintenance`
- Lint: `statix check .`
- Dead code scan: `deadnix -f .`
- Flake checks: `nix flake check`

Notes
- `allowUnfree = true` is enabled for packages like VS Code.
- Stylix auto-enables Gruvbox; Home Manager targets follow system theme (see `modules/stylix-nixos.nix`).
- `programs.i3blocks` is currently disabled in `home.nix`.
- Hibernate/suspend rely on the swap device/offset in `configuration.nix`—keep in sync if storage changes.
