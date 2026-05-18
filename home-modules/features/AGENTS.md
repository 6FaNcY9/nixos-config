# AGENTS.md — home-modules/features/

User-level opt-in features. Aggregator at `./default.nix`. Same opt-in pattern as NixOS features.

## Categories
| Dir | Scope |
|---|---|
| `ai/` | Hermes agent, AI tooling |
| `desktop/` | i3, polybar, rofi, firefox, qutebrowser, dunst/picom/flameshot via `services.nix`, lock, notepad, vibe, filezilla |
| `editor/` | nixvim configuration |
| `shell/` | Bash/zsh/starship/direnv |
| `terminal/` | Terminal emulators, tmux (statusbar consumes `palette.*`) |

## Desktop Hot Spots
- **Polybar**: `desktop/polybar/`. PUA icons MUST go through `cfgLib.mkPolybarIcon`; codepoints live as integers in `desktop/polybar/icons.nix`. `font-0 = "iosevka-bin"` is non-negotiable (system font; `nixos-modules/core/fonts.nix:16-19`).
- **Rofi**: `desktop/rofi/{default,theme.rasi,config.rasi,dropdown-theme.rasi,audio-switcher-theme.rasi,powermenu-theme.rasi}.nix`. Inline `palette.*` strings; **no** `@@placeholder@@`. `stylix.targets.rofi.enable` is forced `false`.
- **Firefox**: `desktop/firefox.nix:193-233` IS the live placeholder generator — `builtins.replaceStrings` against `assets/firefox/userChrome.theme.css`.
- **Services (`desktop/services.nix:17-113`)**: dunst, picom, flameshot — consumers of `palette.*`.

## Adding a Feature
1. File in matching category dir, follow `options.features.<category>.<name>.enable` pattern.
2. Add to that category's `default.nix` imports.
3. Reference `palette.*` for theming. Drop to `c.baseXX` only when no semantic name exists.
4. Toggle per-host in `home-configurations/vino/hosts/<host>.nix` or globally in `home-configurations/vino/user.nix`.
