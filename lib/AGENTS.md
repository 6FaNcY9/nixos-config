# AGENTS.md — lib/

Pure helper functions. Imported as `cfgLib` into both NixOS and HM via `_module.args`.

## Signature
```nix
import ../lib { inherit lib; pkgs ? null; }
```
`pkgs` is **required** by `mkPolybarIcon` (runs Python). NixOS side passes `lib` only → calling `mkPolybarIcon` from NixOS will throw. HM side at `home-configurations/vino/default.nix:45` passes both.

## Exports (`lib/default.nix`)
| Function | Purpose |
|---|---|
| `mkWorkspaceName { number, icon }` | `"3:icon"` or `"3"` |
| `mkWorkspaceBindings { mod, workspaces, commandPrefix, shift? }` | i3 keybind attrset; remaps workspace 10 → key `"0"` |
| `mkSecretValidation { secrets, label? }` | Returns `{ valid, assertions }`; checks existence + sops encryption (both `ENC[AES256_GCM` payload AND `sops:` metadata required) |
| `mkPolybarIcon <int>` | Build-time Python `chr(codepoint)` → glyph string. **The only safe way to emit FA6 PUA icons** |
| `mkPolybarTwoTone { icon, color, colorAlt?, fg? }` | Two-block format-prefix + label module style |
| `mkPolybarTwoToneState { state, icon, color, ... }` | Same pattern for `format-<state>` (volume, charging, ...) |
| `mkBtrfsOpts <subvol>` | BTRFS SSD mount opts: `compress-force=zstd:1`, `noatime`, `space_cache=v2`, `discard=async` |

## When Adding Helpers
- Pure, side-effect-free at evaluation time. `mkPolybarIcon` is the only IFD-style escape — only because PUA literals are unsafe to write.
- Update the `in { inherit ...; }` block at the bottom (`lib/default.nix:141-172`).
- Reference from a module via the injected `cfgLib` arg, never re-import this path.
