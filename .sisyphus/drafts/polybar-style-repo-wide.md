# Draft: Apply Polybar Style Repo-Wide + KISS Repo Cleanup

## Requirements (stated)
- Apply the style/look-and-feel of the newly created Polybar config across the whole `nixos-config` repo.
- Make repo structuring improvements similar to existing `desktop/` and `editor/` folders.
- General repo improvement, following KISS (keep it simple, avoid overengineering).

## Requirements (confirmed from answers)
- Theme scope: Desktop + Terminal/CLI
- Apply to: Home + NixOS host(s)
- Restructure: Moderate (KISS-friendly; avoid sweeping refactors)
- Verification in plan: flake eval/check only (no mandatory `switch` smoke checks)

## New Requirement (added)
- Improve i3 focus visibility (make it obvious which window is focused) and improve tabbed/stacking titlebars so they match the overall theme.

## i3 Decisions (confirmed)
- Focus visibility: improve both border + tab highlight.
- Titlebars/tabs: keep clean default; add a keybinding-based toggle for more visible tabbed/stacking bars.
- Focus highlight color (repo-wide): use `palette.accent` (keep `warn` for warnings, `danger` for urgent).

## Additional Decisions (confirmed)
- Outside Polybar, also mimic the Polybar "block segment" motif where it makes sense (tmux + starship at minimum).
- Promote Polybar-specific hardcoded "alt" colors to shared tokens so other modules can reuse them.
- Restructure approach: move files/directories and update imports (bounded, not sweeping).

## Git / Branch Workflow (user preference)
- Before changes: create a new branch `newdev` from `main` and do all planned work there.
- Note: in git, creating a branch already gives you the same content as `main` at that commit — no manual copying needed.
- If local uncommitted changes exist, they will move with you when you create/switch branches; keep `main` clean by branching first, then committing on `newdev`.

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

## Claude Artifacts (observed)
- `.claude/` exists but currently contains only `settings.local.json` (no plans/notes files).
- `CLAUDE.md` exists at repo root and is guidance for Claude Code (commands, architecture, conventions) — not a change log.

## Theme Anchor (Polybar) — key style traits (observed)
- Visual motif: blocky two-tone colored segments (icon-bg + label-bg), with minimal padding and a small border.
- Fonts: explicit polybar fonts set (Iosevka Term + Font Awesome 6 variants).
- Colors are mostly derived from shared theme inputs (`palette` + base16 `c.*`) but include a few hardcoded “bright” variants (e.g., `green-alt`, `yellow-alt`, etc.).
- Modules include: menu (rofi), i3 workspaces (with optional icons), xwindow title, time/date, host, cpu/temp/memory, pulseaudio, optional network + battery, power (rofi-power-menu).

## Terminal/CLI Theme Signals (observed)
- `home-modules/terminal/alacritty.nix` currently sets window behavior + keybindings; no explicit color theme yet.
- `home-modules/shell/starship.nix` already uses base16 colors (`c.baseXX`) and a consistent background token (`c.base01`).

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
