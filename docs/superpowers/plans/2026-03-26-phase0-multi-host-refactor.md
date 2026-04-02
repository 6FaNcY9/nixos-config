# Phase 0: Multi-Host Repo Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the 7 minimal issues that prevent adding a second NixOS host (the headless server) to this repo.

**Architecture:** Seven targeted edits to existing files — no new modules, no structural changes. Each task is independently verifiable via `just qa` and a dry-run build. Tasks 1–4 and 5–7 can be done in any order relative to each other, but Task 3 depends on Task 2.

**Tech Stack:** Nix, nixfmt-rfc-style, sops-nix, ez-configs, flake-parts. Verification: `just qa` (treefmt + statix + deadnix + flake check) and `just rebuild-test` (dry-run NixOS build).

---

## File Map

| Action | File | Change |
|--------|------|--------|
| Modify | `flake.nix` | Remove `primaryHost` variable, hardcode `bandit` in `userHomeModules` |
| Modify | `lib/default.nix` | Add `mkUserModuleArgs` helper + export it |
| Modify | `home-configurations/vino/default.nix` | Use `cfgLib.mkUserModuleArgs` instead of inline block |
| Modify | `nixos-modules/core/networking.nix` | Wrap 3 values in `lib.mkDefault` |
| Modify | `home-modules/features/editor/nixvim/plugins.nix` | Add `hostname`/`username` to args, remove literals |
| Modify | `home-modules/core/secrets.nix` | Gate each secret + validation with `pathExists` |
| Modify | `.sops.yaml` | Rename `&host` → `&host_bandit`, `*host` → `*host_bandit` |

---

## Task 1: Remove primaryHost from flake.nix

**Files:**
- Modify: `flake.nix:131` (remove variable), `flake.nix:208` (hardcode hostname)

- [ ] **Step 1: Remove the `primaryHost` variable**

In `flake.nix`, delete this line at line 131:
```nix
      primaryHost = "bandit";
```

- [ ] **Step 2: Hardcode `bandit` in userHomeModules**

In `flake.nix`, change line 208 from:
```nix
          nixos.hosts.${primaryHost}.userHomeModules = [ username ];
```
to:
```nix
          nixos.hosts.bandit.userHomeModules = [ username ];
```

- [ ] **Step 3: Verify no other references to primaryHost remain**

```bash
grep -n "primaryHost" /home/vino/src/nixos-config/flake.nix
```
Expected: no output (zero matches).

- [ ] **Step 4: Run qa**

```bash
cd /home/vino/src/nixos-config && just qa
```
Expected: exits 0 with no errors. `nix fmt` will show "0 changed" (no output). statix and deadnix pass silently.

- [ ] **Step 5: Commit**

```bash
cd /home/vino/src/nixos-config
git add flake.nix
git commit -m "refactor(flake): remove primaryHost variable, hardcode bandit in userHomeModules"
```

---

## Task 2: Add mkUserModuleArgs to lib/default.nix

**Files:**
- Modify: `lib/default.nix`

- [ ] **Step 1: Add the mkUserModuleArgs function**

In `lib/default.nix`, add this function after the `mkBtrfsOpts` definition (before the closing `in` block at line 228):

```nix
  # mkUserModuleArgs :: { config, pkgs, inputs, hostName } -> AttrSet
  # Build the _module.args attrset for a Home Manager user configuration.
  # Centralises the derivation of palette, workspaces, fonts, packages, and
  # hostname so that a second user config can call this instead of copy-pasting.
  #
  # Args:
  #   config   — Home Manager config (provides theme.*, workspaces, stylix.fonts)
  #   pkgs     — nixpkgs package set
  #   inputs   — flake inputs (used for codex-cli-nix)
  #   hostName — resolved hostname string (from osConfig or fallback)
  mkUserModuleArgs =
    {
      config,
      pkgs,
      inputs,
      hostName,
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      stylixFonts = lib.attrByPath [ "stylix" "fonts" ] {
        sansSerif.name = "Sans";
        monospace.name = "Monospace";
      } config;
    in
    {
      inherit (config.theme) palette;
      inherit (config) workspaces;
      c = config.theme.colors;
      inherit stylixFonts;
      i3Pkg = pkgs.i3;
      codexPkg = inputs.codex-cli-nix.packages.${system}.default;
      opencodePkg = pkgs.opencode;
      hostname = hostName;
      cfgLib = import ./. { inherit lib; };
    };
```

- [ ] **Step 2: Export mkUserModuleArgs in the return attrset**

At the bottom of `lib/default.nix`, in the final `{...}` block, add `mkUserModuleArgs` next to `mkBtrfsOpts`:

```nix
  # Filesystem helpers
  inherit mkBtrfsOpts;

  # Home Manager module args helper
  inherit mkUserModuleArgs;
```

- [ ] **Step 3: Run qa**

```bash
cd /home/vino/src/nixos-config && just qa
```
Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
cd /home/vino/src/nixos-config
git add lib/default.nix
git commit -m "feat(lib): add mkUserModuleArgs helper for Home Manager module args"
```

---

## Task 3: Use mkUserModuleArgs in home-configurations/vino/default.nix

**Depends on: Task 2**

**Files:**
- Modify: `home-configurations/vino/default.nix`

- [ ] **Step 1: Remove the inline _module.args block and local let bindings**

In `home-configurations/vino/default.nix`, remove these lines from the `let` block (lines 21–34):
```nix
  # Stylix fonts (with fallback)
  stylixFonts = lib.attrByPath [ "stylix" "fonts" ] {
    sansSerif = {
      name = "Sans";
    };
    monospace = {
      name = "Monospace";
    };
  } config;

  codexPkg = inputs.codex-cli-nix.packages.${system}.default;
  opencodePkg = pkgs.opencode;

  i3Pkg = pkgs.i3;
```

Also remove the `inherit (pkgs.stdenv.hostPlatform) system;` line (line 16) — it is no longer needed here.

- [ ] **Step 2: Replace the _module.args block**

Replace the entire `_module.args = { ... };` block (lines 54–66) with:

```nix
  # Inject shared arguments into all home-modules via _module.args.
  # See lib/default.nix:mkUserModuleArgs for the full list of injected args.
  _module.args = cfgLib.mkUserModuleArgs {
    inherit config pkgs inputs hostName;
  };
```

Where `cfgLib` is defined in the `let` block below, and `hostName` is already derived at line 17 from `osConfig.networking.hostName`.

- [ ] **Step 3: Add cfgLib to the let block**

In `home-configurations/vino/default.nix`, the `let` block currently does not define `cfgLib` (it was injected via `_module.args` from itself). After removing the inline block, add `cfgLib` to the `let` block:

```nix
let
  hostName = if osConfig != null then osConfig.networking.hostName else hostname;
  hostModulePath = ./hosts/${hostName}.nix;
  hostModules = lib.optionals (builtins.pathExists hostModulePath) [ hostModulePath ];
  cfgLib = import ../../lib { inherit lib; };
in
```

- [ ] **Step 4: Verify the file compiles**

```bash
cd /home/vino/src/nixos-config
nix build .#homeConfigurations."vino@bandit".activationPackage --dry-run 2>&1 | tail -5
```
Expected: exits 0, last line shows "these derivations will be built" or "nothing to do".

- [ ] **Step 5: Run qa**

```bash
cd /home/vino/src/nixos-config && just qa
```
Expected: exits 0.

- [ ] **Step 6: Commit**

```bash
cd /home/vino/src/nixos-config
git add home-configurations/vino/default.nix
git commit -m "refactor(home): use cfgLib.mkUserModuleArgs in vino home config"
```

---

## Task 4: Wrap locale/timezone in mkDefault

**Files:**
- Modify: `nixos-modules/core/networking.nix`

- [ ] **Step 1: Add lib to the module args**

`networking.nix` currently takes `_:` (ignores all args). Change the first line to accept `lib`:

```nix
{ lib, ... }:
```

- [ ] **Step 2: Wrap the three values in lib.mkDefault**

Replace:
```nix
  # Locale and timezone
  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de-latin1-nodeadkeys";
```
With:
```nix
  # Locale and timezone — mkDefault allows per-host overrides.
  # Server hosts should set time.timeZone = "UTC" and console.keyMap = "us" in their entrypoint.
  time.timeZone = lib.mkDefault "Europe/Vienna";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "de-latin1-nodeadkeys";
```

- [ ] **Step 3: Run qa**

```bash
cd /home/vino/src/nixos-config && just qa
```
Expected: exits 0.

- [ ] **Step 4: Verify bandit still builds correctly**

```bash
cd /home/vino/src/nixos-config && just rebuild-test
```
Expected: dry-run completes without errors. Timezone and locale are unchanged for bandit (mkDefault loses to any explicit value, but bandit sets nothing, so the default applies).

- [ ] **Step 5: Commit**

```bash
cd /home/vino/src/nixos-config
git add nixos-modules/core/networking.nix
git commit -m "fix(networking): wrap locale/timezone in mkDefault to allow per-host overrides"
```

---

## Task 5: Fix nixd LSP literals in plugins.nix

**Files:**
- Modify: `home-modules/features/editor/nixvim/plugins.nix`

- [ ] **Step 1: Add hostname and username to function args**

Change the first line from:
```nix
{ pkgs, ... }:
```
To:
```nix
{ pkgs, hostname, username, ... }:
```

Both `hostname` and `username` are already available in `_module.args` (injected by `home-configurations/vino/default.nix`).

- [ ] **Step 2: Replace hardcoded literals**

Replace lines 202–203:
```nix
              nixos.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.bandit.options";
              home_manager.expr = "(builtins.getFlake (builtins.toString ./.)).homeConfigurations.\"vino@bandit\".options";
```
With:
```nix
              nixos.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${hostname}.options";
              home_manager.expr = "(builtins.getFlake (builtins.toString ./.)).homeConfigurations.\"${username}@${hostname}\".options";
```

- [ ] **Step 3: Run qa**

```bash
cd /home/vino/src/nixos-config && just qa
```
Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
cd /home/vino/src/nixos-config
git add home-modules/features/editor/nixvim/plugins.nix
git commit -m "fix(nixvim): replace hardcoded bandit/vino@bandit literals with injected hostname/username"
```

---

## Task 6: Make home secrets optional

**Files:**
- Modify: `home-modules/core/secrets.nix`

- [ ] **Step 1: Replace the file with the pathExists-gated version**

Replace the entire `home-modules/core/secrets.nix` with:

```nix
# sops-nix Home Manager secret management
# Each secret is declared only if its file exists on disk.
# This allows a host to have a subset of secrets without build failures.
# Secrets: GitHub MCP PAT, GPG signing key, Cachix auth, Exa API, Context7 API, Mistral API, Helicone API
{
  config,
  lib,
  inputs,
  pkgs,
  cfgLib,
  ...
}:
let
  # Secret file paths
  githubMcpSecretFile = "${inputs.self}/secrets/github-mcp.yaml";
  gpgSigningKeyFile = "${inputs.self}/secrets/gpg-signing-key.yaml";
  cachixSecretFile = "${inputs.self}/secrets/cachix.yaml";
  exaApiSecretFile = "${inputs.self}/secrets/exa-api.yaml";
  context7SecretFile = "${inputs.self}/secrets/context7-api.yaml";
  mistralSecretFile = "${inputs.self}/secrets/mistral.yaml";
  heliconeSecretFile = "${inputs.self}/secrets/helicone.yaml";

  # Only validate files that are actually present on this host.
  presentSecrets = builtins.filter builtins.pathExists [
    githubMcpSecretFile
    gpgSigningKeyFile
    cachixSecretFile
    exaApiSecretFile
    context7SecretFile
    mistralSecretFile
    heliconeSecretFile
  ];
  secretValidation = cfgLib.mkSecretValidation {
    secrets = presentSecrets;
    label = "Home";
  };
in
{
  inherit (secretValidation) assertions;

  # sops-nix Home Manager defaults (kept minimal)
  sops = {
    age.keyFile = lib.mkDefault "${config.xdg.configHome}/sops/age/keys.txt";

    secrets =
      lib.optionalAttrs (builtins.pathExists githubMcpSecretFile) {
        github_mcp_pat = {
          sopsFile = githubMcpSecretFile;
          format = "yaml";
          mode = "0400";
        };
      }
      // lib.optionalAttrs (builtins.pathExists gpgSigningKeyFile) {
        gpg_signing_key = {
          sopsFile = gpgSigningKeyFile;
          key = "gpg_private_key";
          format = "yaml";
          mode = "0400";
        };
      }
      // lib.optionalAttrs (builtins.pathExists cachixSecretFile) {
        cachix_auth_token = {
          sopsFile = cachixSecretFile;
          key = "cachix_auth_token";
          format = "yaml";
          mode = "0400";
        };
      }
      // lib.optionalAttrs (builtins.pathExists exaApiSecretFile) {
        exa_api_key = {
          sopsFile = exaApiSecretFile;
          format = "yaml";
          mode = "0400";
        };
      }
      // lib.optionalAttrs (builtins.pathExists context7SecretFile) {
        context7_api_key = {
          sopsFile = context7SecretFile;
          format = "yaml";
          mode = "0400";
        };
      }
      // lib.optionalAttrs (builtins.pathExists mistralSecretFile) {
        mistral_api_key = {
          sopsFile = mistralSecretFile;
          format = "yaml";
          mode = "0400";
        };
      }
      // lib.optionalAttrs (builtins.pathExists heliconeSecretFile) {
        helicone_api_key = {
          sopsFile = heliconeSecretFile;
          format = "yaml";
          mode = "0400";
        };
      };
  };

  # Import GPG key after sops-nix has decrypted secrets.
  # Non-fatal: only runs if the secret path exists at activation time.
  home.activation.importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" "reloadSystemd" ] ''
    SECRET_PATH="${config.sops.secrets.gpg_signing_key.path or ""}"
    if [ -n "$SECRET_PATH" ] && [ -f "$SECRET_PATH" ]; then
      echo "Importing GPG signing key..."
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "$SECRET_PATH" 2>/dev/null || echo "GPG key already imported or import failed (non-fatal)"
    else
      echo "GPG signing key secret not available on this host, skipping import"
    fi
  '';
}
```

- [ ] **Step 2: Run qa**

```bash
cd /home/vino/src/nixos-config && just qa
```
Expected: exits 0. nixfmt may reformat the file.

- [ ] **Step 3: Verify bandit HM still builds**

```bash
cd /home/vino/src/nixos-config
nix build .#homeConfigurations."vino@bandit".activationPackage --dry-run 2>&1 | tail -5
```
Expected: exits 0 — all secret files exist on bandit so behavior is identical.

- [ ] **Step 4: Commit**

```bash
cd /home/vino/src/nixos-config
git add home-modules/core/secrets.nix
git commit -m "fix(secrets): gate each HM secret with pathExists — optional per host"
```

---

## Task 7: Rename .sops.yaml host anchor

**Files:**
- Modify: `.sops.yaml`

- [ ] **Step 1: Rename the anchor and its reference**

In `.sops.yaml`, replace:
```yaml
  - &host age1r6cncetmt3xx9mv2hedvwm8dwc2nhy9rmekhah747kxeguzygplq6a875l
```
With:
```yaml
  - &host_bandit age1r6cncetmt3xx9mv2hedvwm8dwc2nhy9rmekhah747kxeguzygplq6a875l
```

And in `creation_rules`, replace:
```yaml
          - *host
```
With:
```yaml
          - *host_bandit
```

The age key value itself is unchanged — only the YAML anchor name changes.

- [ ] **Step 2: Verify sops can still decrypt an existing secret**

```bash
cd /home/vino/src/nixos-config
sops -d secrets/github-mcp.yaml > /dev/null && echo "OK"
```
Expected: prints `OK` with no errors. (The anchor rename is a YAML metadata change — the key itself is identical, so existing encrypted files remain readable.)

- [ ] **Step 3: Commit**

```bash
cd /home/vino/src/nixos-config
git add .sops.yaml
git commit -m "chore(secrets): rename &host anchor to &host_bandit for multi-host clarity"
```

---

## Task 8: Final verification

- [ ] **Step 1: Run full qa**

```bash
cd /home/vino/src/nixos-config && just qa
```
Expected: exits 0.

- [ ] **Step 2: Dry-run NixOS build for bandit**

```bash
cd /home/vino/src/nixos-config && just rebuild-test
```
Expected: exits 0, prints "dry activation" or "nothing to activate". No evaluation errors.

- [ ] **Step 3: Dry-run Home Manager build**

```bash
cd /home/vino/src/nixos-config
nix build .#homeConfigurations."vino@bandit".activationPackage --dry-run
```
Expected: exits 0.

- [ ] **Step 4: Confirm ez-configs still auto-discovers bandit**

```bash
cd /home/vino/src/nixos-config
nix eval .#nixosConfigurations --apply builtins.attrNames 2>&1
```
Expected: `[ "bandit" ]` — bandit is still the only host.

- [ ] **Step 5: Tag the completion**

```bash
cd /home/vino/src/nixos-config
git tag phase0-complete
```
