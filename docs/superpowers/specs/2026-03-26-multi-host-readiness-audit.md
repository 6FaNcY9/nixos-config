# Multi-Host Readiness Audit

**Date:** 2026-03-26
**Scope:** Full repo structural analysis, excluding .direnv/.devenv
**Goal:** Identify technical debt before adding a second NixOS host

---

## Executive Summary

Top findings that must be addressed before a second host can be added:

1. **Hardware UUIDs baked into bandit entrypoint** (`blocker`) — `mainDisk` UUID and `resume_offset` kernel param in `nixos-configurations/bandit/default.nix` are Framework 13 AMD hardware values. While already isolated to the bandit entrypoint, any attempt to copy this file as a template for a second host will silently produce a broken config. Must stay per-host and be clearly flagged as non-shareable.
2. **nixd LSP expressions hardcode `bandit` and `vino@bandit`** (`moderate`) — `home-modules/features/editor/nixvim/plugins.nix` embeds `nixosConfigurations.bandit` and `homeConfigurations."vino@bandit"` as literals. On any second host these resolve the wrong configuration or fail at build time.
3. **`_module.args` block duplicated across user entrypoints** (`moderate`) — `home-configurations/vino/default.nix` contains a long `_module.args` derivation block. A second user must copy it entirely, creating a maintenance hazard with no shared helper.
4. **Unconditional secrets for every host** (`moderate`) — `home-modules/core/secrets.nix` declares all seven secrets for every user and host. A second host missing any secret file will fail assertions at build time.
5. **`.sops.yaml` generic `&host` anchor and flat creation rules** (`moderate`) — The unnamed host anchor and single creation rule encrypting all secrets for all hosts will become ambiguous and overprivileged as soon as a second host is enrolled.

---

## Layer 1: flake.nix

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| flake.nix | good-pattern | n/a | `username` is auto-derived from `builtins.readDir ./home-configurations` — not hardcoded. Works for exactly one user; adding a second user causes a `throw`. | Keep for single-user; when multi-user is needed, replace the guard with a list and iterate. |
| flake.nix | hardcoded-literal | moderate | `primaryHost = "bandit"` is a named variable but still a single hardcoded string. `ezConfigs.nixos.hosts.${primaryHost}` only registers one host, so adding a second host means manually extending this block. | Replace `primaryHost` with a set of hosts (`hosts = { bandit = ...; }`) or let `ez-configs` auto-discover all subdirectories under `nixos-configurations/`. |
| flake.nix | hardcoded-literal | moderate | `system = "x86_64-linux"` is a module-level constant passed to `systems = [ system ]`. A second host with a different architecture (e.g., aarch64 ARM laptop or server) would require changing this to a list and making `pkgsFor` calls per-host. | Rename to `defaultSystem` or expand `systems` to a list; keep `pkgsFor` parametric (it already is). |
| flake.nix | hardcoded-literal | minor | `repoRoot = "/home/${username}/src/nixos-config"` assumes a fixed path convention (`~/src/nixos-config`). Different users or a second host cloned to a different path would need a per-host override. | The inline comment already documents the `NIXOS_CONFIG_ROOT` override mechanism — ensure every consumer honours that env var, or document the path assumption clearly. |
| flake.nix | structural-coupling | moderate | `ezConfigs.nixos.hosts.${primaryHost}.userHomeModules = [ username ]` hardwires a single host→user mapping. A second host with different user(s), or a headless host with no Home Manager user, needs manual extension of this attrset. | Convert to an attrset of host definitions, each declaring its own `userHomeModules`. |
| flake.nix | good-pattern | n/a | `globalArgs` passes `inputs`, `username`, `repoRoot`, and `nixpkgsConfig` into every NixOS and HM module without repetition. Clean injection point. | Keep; extend by adding new host-agnostic globals here rather than in individual host files. |
| flake.nix | good-pattern | n/a | All flake inputs use `inputs.nixpkgs.follows` where applicable, preventing multiple nixpkgs copies in the closure. | Keep. |

## Layer 2: nixos-configurations/bandit/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| nixos-configurations/bandit/default.nix | good-pattern | n/a | All feature toggles are explicit opt-ins under `features.*`; nothing is always-on outside a module's own default. Structure cleanly separates host intent from module implementation. | Keep this pattern for all future hosts. |
| nixos-configurations/bandit/default.nix | hardcoded-literal | minor | `networking.hostName = "bandit"` is hardcoded in the file that is already identified by its directory name (`bandit/`). This is redundant and a copy-paste hazard when creating a second host directory. | Remove the explicit `hostName` assignment and derive it from the directory name via `ez-configs` (the framework passes `hostname` as a module arg); or define a convention that the directory name IS the hostname. |
| nixos-configurations/bandit/default.nix | hardcoded-literal | blocker | `mainDisk = "/dev/disk/by-uuid/0629aaee-..."` and `kernelParams = [ "resume_offset=1959063" ]` are Framework 13 AMD hardware UUIDs baked into the entrypoint. A second host must not inherit these. | These are already scoped to `bandit/default.nix` (not a shared module), so they are isolated. Risk is low today. Flag for future: ensure any shared module never imports these values; they must stay per-host. |
| nixos-configurations/bandit/default.nix | hardcoded-literal | minor | `features.desktop.i3-xfce.keyboardLayout = "at"` (Austrian) is a personal/hardware preference baked into the host. Acceptable here, but should be noted as user-specific (not host-specific) if a second user is ever added. | Move to `home-configurations` if the layout is user preference; keep in NixOS config only if it is hardware/locale enforced. |
| nixos-configurations/bandit/hardware-configuration.nix | hardcoded-literal | minor | UUID `0629aaee-1698-49d1-b3e1-e7bb6b957cda` appears seven times (root, home, nix, var, swap, two snapshot mounts). `default.nix` already extracts this to `mainDisk` but `hardware-configuration.nix` repeats it inline — it is the auto-generated file and not meant to be edited, but the duplication is a maintenance note. | `default.nix` already overrides the mount options with `lib.mkForce`. The generated file is not a scaling risk. Document that it must not be shared across hosts. |
| nixos-configurations/bandit/hardware-configuration.nix | good-pattern | n/a | `nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux"` uses `mkDefault`, allowing the flake-level `system` to override it cleanly. | Keep. |
| nixos-configurations/bandit/default.nix | missing-abstraction | minor | `features.hardware.laptop.framework.model = "framework-13-amd"` is a free-form string with no validation. A second Framework model (e.g., Framework 16) would require knowing the correct string value. | Define an enum or validated option type in the laptop hardware module so invalid model names fail at evaluation. |

## Layer 3: home-configurations/vino/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| home-configurations/vino/default.nix | good-pattern | n/a | `hosts/<hostname>.nix` override pattern with `lib.optionals (builtins.pathExists hostModulePath)` is clean and safe — missing host file does not error. | Keep. |
| home-configurations/vino/default.nix | good-pattern | n/a | `hostName` is derived from `osConfig.networking.hostName` at runtime (falling back to the `hostname` arg), so polybar/devices/etc. get the real hostname without hardcoding. | Keep the dual-source fallback. |
| home-configurations/vino/default.nix | structural-coupling | moderate | `_module.args` is injected inside the `vino` user's entrypoint, so it is per-user. A second user (`home-configurations/alice/default.nix`) would need to duplicate the entire `_module.args` block (`palette`, `c`, `workspaces`, `cfgLib`, `stylixFonts`, `i3Pkg`, `codexPkg`, `opencodePkg`, `hostname`). There is no shared helper to produce this block. | Extract a `mkUserModuleArgs` helper in `lib/` that takes `{config, inputs, pkgs, ...}` and returns the standard `_module.args` attrset. Each user's `default.nix` calls it rather than duplicating the derivation logic. |
| home-configurations/vino/default.nix | hardcoded-literal | minor | `home.stateVersion = "25.11"` is user-specific and correct here. A second user entrypoint must set their own `stateVersion`. Not a shared-module problem — just a per-user checklist item. | Document in a new-user checklist; not a code change. |
| home-configurations/vino/default.nix | hardcoded-literal | minor | Git identity (`user.name`, `user.email`, `user.signingkey`) and `commit.gpgsign = true` live in the user entrypoint. Correct place. A second user must supply their own. | No change needed; document in a new-user checklist. |
| home-configurations/vino/hosts/bandit.nix | good-pattern | n/a | `devices` block (`battery`, `backlight`, `networkInterface`) cleanly captures hardware identifiers at the host-override level. Polybar reads them without hardcoding device names inside the module. | Keep and enforce this pattern for all hosts. |
| home-configurations/vino/hosts/bandit.nix | good-pattern | n/a | Feature toggles and profiles are all opt-in; the host file is the single place to enable desktop features for this machine. | Keep. |
| home-configurations/vino/hosts/bandit.nix | scaling-gap | minor | If a second host (e.g., a headless server) is added for the same user `vino`, a `hosts/server.nix` file is all that is needed — the pattern scales. However, there is currently no documentation or template showing what a minimal host-override file must contain (`devices`, `profiles`, `features`). | Add a `hosts/_template.nix` or a comment block in `bandit.nix` listing required vs. optional keys. |
| home-modules/profiles.nix | structural-coupling | moderate | `profiles.nix` uses `codexPkg ? null` and `opencodePkg ? null` with null guards, but `aiPkgs` includes `pkgs.agentsys` unconditionally when `cfg.ai = true`. If `agentsys` is absent from the overlay on a second host, this causes a hard evaluation error at build time when `profiles.ai = true` — blocking that host's build entirely. | Apply the same null-guard / `lib.attrByPath` pattern used for `claudeCodePkg` to `agentsys` and other platform-specific packages. |

## Layer 4: nixos-modules/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| core/nix.nix:35,40 | hardcoded-literal | minor | `https://vino-nixos-config.cachix.org` and its public key are baked into the shared core module. Every host will attempt to use this cache regardless of whether it belongs to a different owner or organisation. | Extract into a flake-level option or `_module.args` (e.g. `extraSubstituters`) so the cache list is injected from `flake.nix` and can be overridden per-host without editing the shared module. |
| core/networking.nix:12-13 | hardcoded-literal | moderate | `time.timeZone = "Europe/Vienna"`, `i18n.defaultLocale = "en_US.UTF-8"`, and `console.keyMap = "de-latin1-nodeadkeys"` are fixed in the always-on core module. A second host in a different timezone or locale silently inherits these wrong values. | Move timezone, locale, and keyMap into a `features.locale` module (or add `mkDefault` wrappers so hosts can override) — or at minimum expose them as `options` in the core module. |
| features/storage/snapper.nix:26 | structural-coupling | moderate | `ALLOW_USERS = [ username ]` in `defaultSnapperConfig` grants snapshot permissions to the single injected `username`. If a second user or a headless host (no `username` arg) uses this module, the list is wrong. | Make `allowUsers` an explicit option (`lib.mkOption`) with `default = [ username ]` so hosts can extend or override it cleanly; document the dependency on `username`. |
| features/services/auto-update.nix:84-86 | structural-coupling | moderate | The update script calls `runuser -u ${username}` twice and then `nixos-rebuild switch --flake ${repoRoot}#${config.networking.hostName}`. This couples the service to both the injected `username` arg and `repoRoot`. Adding a second host is fine (hostName is dynamic), but a headless host without the same user would break silently. | Document the dependency on `username` and `repoRoot` in the module header; consider making `runUser` an explicit option. |
| features/security/secrets.nix:17 | hardcoded-literal | moderate | `githubSecretFile = "${inputs.self}/secrets/github.yaml"` is the only secret wired up, with the path hard-coded in the module body. Adding a second host or user that needs different secrets requires editing this shared module. | Expose a `secrets` option (list of `{ name, file, owner, path }` submodules) so each host can declare its own secrets declaratively; keep the current github key as the default or as a bandit-specific entry in the host config. |
| core/system.nix:4 | structural-coupling | minor | `system.stateVersion = "25.11"` is a single value shared by every host. Different hosts may have been installed on different NixOS releases. | Move `stateVersion` to each host's `default.nix` entrypoint (where it semantically belongs) so it tracks the actual install date of that machine. |
| core/packages.nix:10 | missing-abstraction | minor | `pkgs.btrfs-progs` is unconditionally installed at the system level even though BTRFS is an opt-in feature (`features.storage.btrfs`). A second host without BTRFS still gets the package. | Move `btrfs-progs` into `features/storage/btrfs.nix` where it is conditionally guarded. |
| core/fonts.nix | structural-coupling | minor | `pkgs.iosevka-bin` and `pkgs.nerd-fonts.symbols-only` are always-on core fonts tied to the polybar/desktop setup. A headless server host would pull in these desktop fonts for no reason. | Gate these fonts on `features.desktop.i3-xfce.enable` (or a generic `features.desktop.enable`) rather than loading them unconditionally in core. |
| core/memory.nix | structural-coupling | minor | `vm.swappiness = 80` and `vm.vfs_cache_pressure = 50` are tuned for a laptop with zram. A server host without zram would inherit aggressive swap behaviour that may degrade performance. | Move these sysctl tunables into `features.hardware.laptop` (already the right home for laptop-specific kernel params) and use `lib.mkDefault` at minimum so server hosts can override without conflict. |
| nixos-modules/home-manager.nix | good-pattern | n/a | `home-manager.extraSpecialArgs` passes `username` and `repoRoot` as dynamic args rather than hardcoding "vino" or any path. Adding a second user requires only a new entry under `home-configurations/` — no change to this file. | Keep as-is. |
| nixos-modules/core/users.nix | good-pattern | n/a | User account is built from the `username` arg (`users.users.${username}`) with no literal name. A second user would work if the arg is changed; the groups list is generic. | Keep as-is. |
| features/desktop/i3-xfce.nix | good-pattern | n/a | All keyboard layout, display manager, audio, and i3 package choices are exposed as typed `mkOption` entries with sane defaults. No hostname or username references anywhere in the module. | Keep as-is; this is a well-parameterised feature module. |
| features/hardware/laptop.nix | good-pattern | n/a | Framework-specific kernel params, udev rules, and packages are all gated behind `cfg.framework.enable && cfg.framework.model == "framework-13-amd"`. A second laptop model is addable without touching existing logic. | Keep as-is. |
| features/storage/boot.nix | good-pattern | n/a | Bootloader selection (grub vs systemd-boot), EFI variables, OS prober, and kernel channel are all options. No device paths or UUIDs appear in the module (they live in the host entrypoint). | Keep as-is. |
| features/security/server-hardening.nix | good-pattern | n/a | Uses `lib.mkDefault` wrappers where appropriate, carries an `assertions` guard requiring openssh to be enabled, and exposes `ssh.allowUsers` as an option. Clean separation of desktop vs server hardening. | Keep as-is. |
| features/services/monitoring.nix | good-pattern | n/a | Prometheus and Grafana ports, retention, and exporters are all options. Firewall rules use `interfaces.lo` to stay localhost-only. No literals that assume a single host. | Keep as-is. |
| nixos-modules/default.nix | good-pattern | n/a | `cfgLib` is injected via `_module.args` from the shared `lib/` — not hardcoded into individual modules, and available to all nixos-modules uniformly. | Keep as-is. |

## Layer 5: home-modules/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| home-modules/features/editor/nixvim/plugins.nix:202-203 | hardcoded-literal | moderate | nixd LSP option expressions hardcode both `nixosConfigurations.bandit` and `homeConfigurations."vino@bandit"`. On a second host these expressions silently evaluate the wrong configuration or fail. | Use the injected `hostname` and `username` args (already available via `_module.args`) to build these strings dynamically: `nixosConfigurations.${hostname}` and `homeConfigurations."${username}@${hostname}"`. |
| home-modules/core/secrets.nix | scaling-gap | moderate | All seven secrets are unconditionally declared for every user/host. A second host that doesn't need, say, `helicone_api_key` or `cachix_auth_token` would still require those secret files to exist on disk, causing failed assertions. | Wrap each secret in its own `mkEnableOption` or group them under a feature flag so a minimal host can opt out. |
| home-modules/profiles.nix:129-131 | scaling-gap | minor | `core`, `dev`, and `desktop` profiles all default to `true`. A headless second host would need to explicitly override all three to `false` and would still pull in desktop packages unless overridden in its host file. | Consider defaulting `desktop` (and possibly `dev`) to `false`; enable them explicitly per host as `bandit.nix` already does for `extras` and `ai`. |
| home-modules/features/shell/fish.nix:68-69 | good-pattern | n/a | Shell abbreviations `rebuild` and `hms` use the injected `hostname` and `username` args — no hardcoded strings. | No action needed. |
| home-modules/features/desktop/polybar/modules.nix:107 | good-pattern | n/a | Polybar `host` module uses `echo ${hostname}` from the injected arg rather than a literal. | No action needed. |
| home-modules/core/devices.nix | good-pattern | n/a | Battery, backlight, and network interface device names are options with empty defaults; bandit's values are set only in `home-configurations/vino/hosts/bandit.nix`. Clean per-host override pattern. | No action needed. |
| home-modules/features/desktop/polybar/default.nix:18-19 | good-pattern | n/a | Polybar conditionally includes battery and network modules based on `config.devices.battery != ""` — adapts to hardware automatically. | No action needed. |
| home-configurations/vino/default.nix:17-19 | good-pattern | n/a | Host module is loaded via `./hosts/${hostName}.nix` with a `pathExists` guard, enabling per-host overrides without a mandatory file. | No action needed. |
| home-modules/features/desktop/services.nix | good-pattern | n/a | All desktop services (dunst, picom, flameshot, blueman, network-manager-applet) are behind a single `features.desktop.services.enable` flag — trivially disabled on a headless host. | No action needed. |
| home-modules/features/desktop/vibe/default.nix | good-pattern | n/a | Vibe AI devenv config is feature-flagged via `features.desktop.vibe.enable` and enabled only in `bandit.nix`. | No action needed. |
| home-modules/features/shell/git.nix | good-pattern | n/a | Git identity (name, email, signingkey) is not present in this module — correctly delegated to `home-configurations/vino/default.nix`. Module only carries generic settings. | No action needed. |
| home-modules/core/package-managers.nix | good-pattern | n/a | All paths use `config.xdg.*Home` variables — fully portable across users and hosts. | No action needed. |

## Layer 6: shared-modules/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| shared-modules/stylix-common.nix | good-pattern | n/a | Wallpaper is an overridable option (`theme.wallpaper`) with a flake-input-relative default — no `/home/vino` path present. Per-host override is possible by setting `theme.wallpaper` in the host config. | No action needed. |
| shared-modules/stylix-common.nix | hardcoded-literal | minor | Font sizes (`applications = 14`, `terminal = 10`) are hardcoded constants with no per-host option. A HiDPI or low-res host would need to override the entire `stylix.fonts.sizes` block rather than a single option. | Promote font sizes to `lib.mkDefault` values or add `theme.fontSizes.*` options so per-host overrides are minimal. |
| shared-modules/stylix-common.nix | scaling-gap | moderate | `nixos-modules/default.nix` imports `stylix-common.nix` directly but does not import `palette.nix` or `workspaces.nix`. Those are only in `home-modules/default.nix`. If a second host adds NixOS-level modules that need palette/workspace data they will be unavailable. | Document the asymmetry or move palette/workspaces imports into `nixos-modules/default.nix` so both layers have a consistent shared baseline. |
| shared-modules/workspaces.nix | good-pattern | n/a | Generic 10-slot workspace list (Firefox, Window, Code, Folder, Music, Image, Video, Chat, Settings, File). No bandit-specific app, monitor count, or slot count assumption. Override mechanism via host config comment is documented in `bandit.nix`. | No action needed. |
| shared-modules/workspaces.nix | scaling-gap | minor | Workspace count (10) and icon set are a static default with no per-host count option. A host with a different primary browser or workflow would require overriding the entire list rather than individual slots. | Low priority for now. Consider a `workspaces` option that accepts overrides per-index if a second host diverges. |
| shared-modules/palette.nix | good-pattern | n/a | Purely aesthetic — derives colors from Stylix base16 with a hardcoded Gruvbox Dark Pale fallback. No host-specific paths, hardware identifiers, or structural assumptions. `palette.*` semantic layer cleanly decouples downstream modules from raw base16 slots. | No action needed. |
| shared-modules/palette.nix | good-pattern | n/a | All palette options use `lib.mkOption` with explicit types and descriptions, making them overridable per-host or per-user without patching the module. | No action needed. |
| Import paths (home-modules/default.nix, nixos-modules/default.nix) | good-pattern | n/a | All shared-module imports use relative paths (`../shared-modules/…`) — no hostname literals in import paths. ez-configs auto-discovery means adding a second host requires no import edits here. | No action needed. |

## Layer 7: lib/

No issues found.

## Layer 8: overlays/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| overlays/default.nix | good-pattern | n/a | Single-entry re-export; no hostname or hardware references anywhere in overlays — fully portable to any host. | Keep as-is. |
| overlays/custom-packages.nix | good-pattern | n/a | `mistral-vibe` resolves its system string from `final.stdenv.hostPlatform.system` rather than a hardcoded arch string — correct cross-host pattern. | Keep as-is. |
| overlays/custom-packages.nix | good-pattern | n/a | `opencode` bun version guard uses `lib.versionAtLeast` rather than a pinned hash unconditionally — degrades gracefully when nixpkgs catches up. | Keep as-is. |
| overlays/custom-packages.nix | hardcoded-literal | minor | `bun_1_3_10` fallback contains a hardcoded `bun-linux-x64` URL; will silently produce a wrong binary on `aarch64-linux` if a second host uses that arch. | Gate the fallback fetch URL on `final.stdenv.hostPlatform.system` (x86_64 vs aarch64) if ARM hosts are ever added. |
| overlays/custom-packages.nix | hardcoded-literal | minor | `opencode` `postFixup` embeds `${final.stdenv.cc.cc.lib}/lib` as a literal `LD_LIBRARY_PATH` injection — correct for x86_64-linux glibc but would need review on musl or aarch64. | No action needed until a non-glibc/aarch64 host is added; add a comment flagging the assumption. |
| overlays/npm-locks/ | good-pattern | n/a | Vendored `package-lock.json` files for packages that lack one upstream are stored alongside the overlay, keeping reproducibility self-contained. | Keep as-is. |
| overlays/custom-packages.nix | good-pattern | n/a | `tree-sitter-cli` pin is explicitly motivated by a version compatibility comment (library vs CLI split) — future maintainers can evaluate whether the pin is still needed. | Keep as-is. |

## Layer 9: home-modules/profiles.nix

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| home-modules/profiles.nix | good-pattern | n/a | Profile flags cleanly separate package sets; per-host activation via `hosts/<hostname>.nix` overrides works correctly for multi-host. | No change needed. |
| home-modules/profiles.nix | good-pattern | n/a | Defaults (`core=true`, `dev=true`, `desktop=true`) are reasonable for a desktop user and can be inverted per-host without touching the module. | No change needed. |
| home-modules/profiles.nix | scaling-gap | minor | `desktop` profile defaults to `true` globally. A headless server host must explicitly set `desktop = false` — no guard preventing GUI packages being installed silently if the host override is forgotten. | Document the `desktop = false` requirement for headless hosts; consider a NixOS-level assertion or derive the default from `features.desktop.*.enable`. |
| home-modules/profiles.nix | structural-coupling | minor | `desktopPkgs` list duplicates packages already declared individually in feature modules (e.g. `pkgs.alacritty`, `pkgs.rofi`, `pkgs.picom`, `pkgs.dunst`). The profile installs them unconditionally when `desktop = true`, regardless of whether the corresponding feature is enabled. | Either drive package installation from feature-module `enable` flags alone and remove the `desktopPkgs` list, or document that the profile is intentionally coarse-grained and the feature modules handle config. |
| home-modules/profiles.nix | hardcoded-literal | minor | `devPkgs` includes `pkgs.jetbrains.idea` (JetBrains Ultimate, requires paid license). This is a desktop-only, license-gated tool silently installed for every `dev = true` host. | Move `idea` to a dedicated `ide` profile or gate it behind `extras`/`ai`. |

## Layer 10: secrets/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| .sops.yaml | good-pattern | n/a | Age key separation (user key vs. host key) allows independent key rotation. Auto-generated host key via `generateKey = true` means zero manual bootstrap for a new host until it needs to decrypt existing secrets. | No change needed. |
| .sops.yaml | good-pattern | n/a | GPG key provides backup decryption path independent of Age key availability. | No change needed. |
| .sops.yaml | scaling-gap | moderate | Single `creation_rules` entry encrypts every secret for every host key. As hosts multiply, each host can decrypt every secret even if it only needs a subset. Acceptable today with one host; becomes an overprivileged flat structure at 3+ hosts. | When adding a second host, consider introducing path-scoped rules (e.g. `secrets/host-bandit/` vs. `secrets/shared/`) so host keys decrypt only what they need. |
| .sops.yaml | scaling-gap | moderate | The `&host` anchor is unnamed/generic. Adding a second host requires a naming decision (`&host_bandit`, `&host_hostname2`) and a manual README update. The current single-host naming will be ambiguous at two hosts. | Rename `&host` to `&host_bandit` now to establish the per-host naming convention before a second host is added. |
| nixos-modules/features/security/secrets.nix | good-pattern | n/a | Secret file paths are generic (no hostname embedded); the `username` arg is parametric. Module is reusable across hosts unchanged. | No change needed. |
| nixos-modules/features/security/secrets.nix | missing-abstraction | minor | Only `github.yaml` is wired up in the NixOS secrets module. Other secrets (`cachix.yaml`, `context7-api.yaml`, `helicone.yaml`, `mistral.yaml`, `github-mcp.yaml`) exist in the `secrets/` directory but are not referenced by any module. It is unclear whether they are consumed elsewhere or orphaned. | Audit each `.yaml` in `secrets/` for active module references; remove or document orphaned entries. |
| secrets/README.md | good-pattern | n/a | The README documents the full add-new-machine workflow including `sops updatekeys`, recovery procedures, and key rotation. Operationally complete. | No change needed. |

---

## Good Patterns

Things done well that should be preserved or extended in the refactor:

- **`globalArgs` injection in flake.nix:** `inputs`, `username`, `repoRoot`, and `nixpkgsConfig` are passed into every NixOS and HM module from a single clean injection point. New host-agnostic globals belong here, not in individual host files.
- **`hosts/<hostname>.nix` override pattern:** The `pathExists` guard in `home-configurations/vino/default.nix` loads host-specific overrides safely without erroring on missing files. This is the correct pattern for per-host hardware device names and feature toggles.
- **`devices` options in `home-modules/core/devices.nix`:** Battery, backlight, and network interface identifiers default to empty strings and are set only in the host override file. Polybar adapts automatically. A model other host configuration files should follow.
- **Feature modules as typed options:** `features/desktop/i3-xfce.nix`, `features/hardware/laptop.nix`, and `features/storage/boot.nix` all expose typed `mkOption` entries with sane defaults and no hostname/username literals. This pattern scales directly to additional hosts.
- **`server-hardening.nix` defensive design:** Uses `lib.mkDefault`, carries an `assertions` guard, and exposes `ssh.allowUsers` as an option — a model for how to write host-category-specific modules safely.
- **Overlay portability:** `mistral-vibe` uses `final.stdenv.hostPlatform.system` for the arch string; no literal `x86_64-linux` in the overlay itself. Vendored `npm-locks/` keeps reproducibility self-contained.
- **`lib/default.nix` purity:** All helpers are fully parameterized with no host config or flake inputs leaked in. `mkWorkspaceBindings`, `mkColorReplacer`, `mkPolybarTwoTone`, and `mkSecretValidation` are all caller-supplies-everything functions.
- **Semantic color layer (`palette.*`):** `palette.nix` decouples downstream modules from raw base16 slots. The two-layer system (`c.*` raw, `palette.*` semantic) means a theme change or scheme swap only requires updating the palette mapping.
- **Age key separation in `.sops.yaml`:** User key vs. host key separation allows independent rotation. `generateKey = true` provides zero-bootstrap enrollment for a new host's key.
- **`secrets/README.md` operational completeness:** The full add-new-machine workflow (sops updatekeys, recovery, key rotation) is documented. No tribal knowledge required.
- **`username` arg propagation in `home-manager.nix`:** `home-manager.extraSpecialArgs` uses the dynamic `username` arg throughout — no literal "vino" in the NixOS HM integration file.

---

## Refactor Priorities

Ordered list of what to address before adding a second host (blockers first, then moderates):

1. **Guard hardware UUIDs against accidental sharing** — `nixos-configurations/bandit/default.nix` contains `mainDisk` UUID and `resume_offset` that must never appear in any shared module. Add a prominent comment or assertion to prevent these values from being referenced outside the bandit entrypoint directory.
2. **Fix nixd LSP hardcoded host/user strings** — `home-modules/features/editor/nixvim/plugins.nix:202-203` embeds `bandit` and `vino@bandit` as literals. Replace with `nixosConfigurations.${hostname}` and `homeConfigurations."${username}@${hostname}"` using the already-injected `_module.args`.
3. **Extract `mkUserModuleArgs` helper** — `home-configurations/vino/default.nix` contains a large `_module.args` block that any second user entrypoint must duplicate. Extract it to `lib/` as `mkUserModuleArgs` so it is called rather than copied.
4. **Make `home-modules/core/secrets.nix` opt-in per secret** — All seven secrets are unconditionally asserted. Wrap each in an `mkEnableOption` or feature group so a second host that lacks certain secret files does not fail its build.
5. **Rename `.sops.yaml` `&host` anchor to `&host_bandit`** — Establishes the per-host naming convention before a second host's key needs to be added. Low-effort, high-clarity fix.
6. **Scope `.sops.yaml` creation rules by path** — Introduce `secrets/host-bandit/` and `secrets/shared/` directories so future host keys decrypt only the secrets they need. Do this when the second host is enrolled rather than immediately.
7. **Move timezone/locale/keyMap out of always-on core** — `core/networking.nix` hardcodes `Europe/Vienna` and `de-latin1-nodeadkeys`. Wrap with `lib.mkDefault` or move to a `features.locale` module so a second host in a different locale can override without conflict.
8. **Apply null-guard to `pkgs.agentsys` in `profiles.nix`** — `aiPkgs` includes `agentsys` unconditionally when `cfg.ai = true`. If the overlay is absent on a second host this is a hard build failure. Apply the same `lib.attrByPath` / null-check pattern used for `claudeCodePkg`.
9. **Expose `secrets` as a declarative option in `features/security/secrets.nix`** — Currently only `github.yaml` is wired up via a hardcoded path. Expose a list-of-submodules option so each host can declare its own secrets without editing the shared module.
10. **Move `system.stateVersion` to per-host entrypoints** — `core/system.nix` shares a single stateVersion across all hosts. Move it to each host's `default.nix` so it reflects the actual install date of that machine.
11. **Audit orphaned secrets** — `cachix.yaml`, `context7-api.yaml`, `helicone.yaml`, `mistral.yaml`, and `github-mcp.yaml` exist in `secrets/` but are not referenced by any module. Determine whether they are consumed via other means or can be removed.
