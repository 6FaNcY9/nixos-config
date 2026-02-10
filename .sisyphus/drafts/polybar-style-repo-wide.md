# Draft: Apply Polybar Style Repo-Wide + KISS Repo Cleanup

## Requirements (stated)
- Apply the style/look-and-feel of the newly created Polybar config across the whole `nixos-config` repo.
- Make repo structuring improvements similar to existing `desktop/` and `editor/` folders.
- General repo improvement, following KISS (keep it simple, avoid overengineering).

## Repo Signals (observed)
- Polybar is managed via Home Manager modules:
  - `home-modules/desktop/polybar/default.nix`
  - `home-modules/desktop/polybar/modules.nix`
  - `home-modules/desktop/polybar/colors.nix` (palette-driven)
- Stylix is already present and wired for both NixOS + Home Manager:
  - `flake.nix` includes `nix-community/stylix`
  - `shared-modules/stylix-common.nix`
  - `nixos-modules/stylix-nixos.nix`
- A shared semantic palette already exists:
  - `shared-modules/palette.nix`
- Other modules already consume `palette` (examples):
  - `home-modules/rofi/default.nix`
  - `home-modules/tmux.nix`
  - `home-modules/desktop/i3/config.nix`

## Working Interpretation (unconfirmed)
- You want Polybar to be the visual reference (colors/fonts/spacing), then ensure other desktop components match.
- You also want the repo layout to become easier to navigate, but with minimal churn.

## Open Questions
- What exactly counts as "apply across the whole repo" (desktop-only vs also CLI/terminal vs also GTK/Qt)?
- Should changes apply to:
  - one Home Manager profile (likely `home-configurations/vino`),
  - all Home Manager profiles,
  - and/or NixOS hosts too?
- How aggressive should restructuring be (minimal tidy vs moderate vs large)?
- Verification preference: flake eval/check only vs full `nixos-rebuild` / `home-manager switch` smoke checks.

## Tentative Scope Boundaries (KISS-default)
- INCLUDE: theme unification via shared palette/fonts, dedupe of hardcoded values, minimal module re-org.
- EXCLUDE (unless requested): hardware config changes, storage/network refactors, switching WM/DE, flake rewrite.
