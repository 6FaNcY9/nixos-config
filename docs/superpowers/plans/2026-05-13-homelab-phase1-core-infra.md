# Homelab Phase 1 — Core Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy arion + Caddy + cloudflared + sops secrets scaffolding on the homelab NixOS host so that Phases 2–5 have a stable, tested foundation to build on.

**Architecture:** cloudflared (NixOS systemd service) receives inbound HTTPS from Cloudflare's edge via a remotely-managed tunnel and forwards plain HTTP to Caddy on `127.0.0.1:80`. Caddy runs as an arion-managed Podman container (`caddy:2-alpine`). sops-nix manages the Cloudflare Tunnel token and will hold all future per-service secrets (Phase 2+). Deployment is two-pass: Pass 1 (Nix config, no secrets) and Pass 2 (after first boot when the homelab age key exists).

**Tech Stack:** NixOS unstable, arion (hercules-ci/arion flake), Podman, Caddy 2, cloudflared, sops-nix

---

## File map

| File | Action | Responsibility |
|------|--------|---------------|
| `flake.nix` | Modify | Add arion flake input with nixpkgs follow |
| `flake.lock` | Generated | Locked arion revision |
| `nixos-configurations/homelab/default.nix` | Modify | arion backend + Podman socket, Caddyfile, Caddy project, cloudflared feature, sops config (Pass 2) |
| `nixos-modules/features/services/cloudflared.nix` | Create | Feature module wrapping a custom cloudflared systemd service |
| `nixos-modules/features/services/default.nix` | Modify | Import cloudflared.nix |
| `.sops.yaml` | Modify | Add homelab age + SSH keys, homelab creation rule (post first-boot) |
| `secrets/homelab.yaml` | Create | Encrypted homelab secrets (post first-boot, created with `sops`) |

---

## Pass 1 — pre-first-boot Nix config

### Task 1: Add arion flake input

arion's NixOS module (`virtualisation.arion`) ships in the arion flake, not nixpkgs.

**Files:**
- Modify: `flake.nix` (inputs block)

- [ ] **Step 1: Add arion input after the hermes-agent entry in flake.nix**

Open `flake.nix`. In the `inputs = { ... }` block, after the `hermes-agent` entry, add:

```nix
    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: Lock the new input**

```bash
cd /home/vino/src/nixos-config
nix flake lock --update-input arion
```

Expected: `flake.lock` updated, no errors. You should see a new `arion` entry in `flake.lock`.

- [ ] **Step 3: Verify flake evaluates**

```bash
nix flake show 2>&1 | head -20
```

Expected: Output lists packages, apps, nixosConfigurations etc. No `error:` lines.

- [ ] **Step 4: Commit**

```bash
git add flake.nix flake.lock
git commit -m "chore(flake): add arion input for declarative container orchestration"
```

---

### Task 2: Wire arion into the homelab NixOS config

arion's NixOS module must be imported explicitly; it is not auto-loaded by ez-configs.
Podman needs its Docker-compatible socket enabled so arion's `podman-socket` backend
can reach it.

**Files:**
- Modify: `nixos-configurations/homelab/default.nix`

- [ ] **Step 1: Add arion module to homelab imports**

In `nixos-configurations/homelab/default.nix`, change the imports block from:

```nix
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
    ./hardware-configuration.nix
  ];
```

to:

```nix
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
    inputs.arion.nixosModules.arion
    ./hardware-configuration.nix
  ];
```

- [ ] **Step 2: Enable the Podman Docker socket and set arion backend**

In `nixos-configurations/homelab/default.nix`, add the following at the top level of
the module (outside the `features = { ... }` block, alongside `networking.hostName`):

```nix
  # arion uses the Docker-compatible Podman socket as its container backend
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.arion.backend = "podman-socket";
```

- [ ] **Step 3: Verify the homelab config evaluates**

```bash
nix build .#nixosConfigurations.homelab.config.system.build.toplevel --dry-run 2>&1 | tail -5
```

Expected: Either `these N derivations will be built:` or `these paths will be fetched:`.
No `error:` lines. (Full build is not required — dry-run is enough.)

- [ ] **Step 4: Run QA**

```bash
just qa 2>&1 | tail -5
```

Expected: `all checks passed!`

- [ ] **Step 5: Commit**

```bash
git add nixos-configurations/homelab/default.nix
git commit -m "feat(homelab): import arion NixOS module, enable podman Docker socket"
```

---

### Task 3: Write Phase 1 Caddyfile and Caddy arion project

Phase 1 Caddyfile is a placeholder that returns 200 for all requests. Phase 2 will
replace the `environment.etc` entry with per-domain reverse_proxy blocks. The Caddy
container mounts the Caddyfile read-only from `/etc/caddy/Caddyfile`.

**Files:**
- Modify: `nixos-configurations/homelab/default.nix`

- [ ] **Step 1: Add the Caddyfile to /etc via environment.etc**

In `nixos-configurations/homelab/default.nix`, add at the top level (alongside
`networking.hostName`):

```nix
  # Phase 1 placeholder Caddyfile — replaced in Phase 2 with per-domain blocks
  environment.etc."caddy/Caddyfile".text = ''
    {
      admin off
    }

    :80 {
      respond "homelab phase 1 ready" 200
    }
  '';
```

- [ ] **Step 2: Add the arion web project with the Caddy container**

In the same file, add at the top level:

```nix
  virtualisation.arion.projects.web.settings = {
    services.caddy.service = {
      image = "caddy:2-alpine";
      ports = [ "127.0.0.1:80:80" ];
      volumes = [
        "/var/lib/caddy/data:/data"
        "/var/lib/caddy/config:/config"
        "/etc/caddy/Caddyfile:/etc/caddy/Caddyfile:ro"
      ];
      restart = "unless-stopped";
    };
  };
```

- [ ] **Step 3: Create the Caddy data directory via tmpfiles**

```nix
  systemd.tmpfiles.rules = [
    "d /var/lib/caddy/data   0750 root root -"
    "d /var/lib/caddy/config 0750 root root -"
  ];
```

- [ ] **Step 4: Run QA**

```bash
just qa 2>&1 | tail -5
```

Expected: `all checks passed!`

- [ ] **Step 5: Commit**

```bash
git add nixos-configurations/homelab/default.nix
git commit -m "feat(homelab/phase1): arion Caddy project with placeholder Caddyfile"
```

---

### Task 4: Create the cloudflared feature module

The NixOS `services.cloudflared` module only supports locally-managed tunnels (requires a
credentials JSON file). For a remotely-managed tunnel (Cloudflare dashboard token),
cloudflared uses the `TUNNEL_TOKEN` environment variable. This module writes a custom
systemd service that reads the token from a sops secret file at runtime.

**Files:**
- Create: `nixos-modules/features/services/cloudflared.nix`
- Modify: `nixos-modules/features/services/default.nix`

- [ ] **Step 1: Create `nixos-modules/features/services/cloudflared.nix`**

```nix
# Feature: Cloudflare Tunnel
# Provides: CGNAT-safe inbound traffic via cloudflared remote-managed tunnel
# Dependencies: sops-nix (tokenFile must be a sops secret path), Caddy on upstream
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.services.cloudflared;
in
{
  options.features.services.cloudflared = {
    enable = lib.mkEnableOption "Cloudflare Tunnel ingress via cloudflared";

    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file whose sole content is the Cloudflare Tunnel token
        (plain string, no trailing newline needed). Typically a sops secret path:
          config.sops.secrets.cloudflare_tunnel_token.path
      '';
    };

    upstream = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:80";
      description = "Internal upstream URL. All tunnel traffic is forwarded here (Caddy).";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.cloudflared = {
      isSystemUser = true;
      group = "cloudflared";
      description = "Cloudflare Tunnel daemon";
    };
    users.groups.cloudflared = { };

    systemd.services.cloudflared = {
      description = "Cloudflare Tunnel";
      after = [
        "network-online.target"
        "sops-nix.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = "cloudflared";
        Group = "cloudflared";
        # Read token from sops secret file; export as TUNNEL_TOKEN env var.
        # cloudflared remote-managed tunnels accept TUNNEL_TOKEN instead of a
        # credentials JSON file. Cannot use EnvironmentFile because sops writes
        # the raw token value (not KEY=VALUE dotenv format) to the secret path.
        ExecStart =
          let
            startScript = pkgs.writeShellScript "cloudflared-start" ''
              export TUNNEL_TOKEN=$(< ${lib.escapeShellArg (toString cfg.tokenFile)})
              exec ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run
            '';
          in
          "${startScript}";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        RuntimeDirectory = "cloudflared";
      };
    };
  };
}
```

- [ ] **Step 2: Add cloudflared.nix to the services aggregator**

In `nixos-modules/features/services/default.nix`, add `./cloudflared.nix` to the imports
list:

```nix
{ ... }:
{
  imports = [
    ./cloudflared.nix
    ./tailscale.nix
    ./monitoring.nix
    ./auto-update.nix
    ./openssh.nix
    ./trezord.nix
  ];
}
```

- [ ] **Step 3: Run QA — verify module parses cleanly**

```bash
just qa 2>&1 | tail -5
```

Expected: `all checks passed!`
If statix complains about unused bindings, remove the offending line.
If deadnix flags an unused import, check for stray `let` bindings.

- [ ] **Step 4: Commit**

```bash
git add nixos-modules/features/services/cloudflared.nix \
        nixos-modules/features/services/default.nix
git commit -m "feat: cloudflared feature module for remote-managed tunnel token auth"
```

---

### Task 5: Push Pass 1 and deploy to homelab (Pass 1 deploy)

Pass 1 brings arion + Caddy to homelab. cloudflared and secrets are NOT enabled yet.

**Files:** none (deployment step)

- [ ] **Step 1: Push Pass 1 changes**

```bash
git push
```

- [ ] **Step 2: Deploy Pass 1 to homelab via SSH (from bandit)**

SSH into homelab over Tailscale, then:

```bash
sudo nixos-rebuild switch --flake github:6FaNcY9/nixos-config#homelab
```

Or if the repo is checked out locally on homelab:

```bash
sudo nixos-rebuild switch --flake /path/to/nixos-config#homelab
```

- [ ] **Step 3: Verify arion Caddy container is running**

On homelab:

```bash
systemctl status arion-web.service
# Expected: active (running)

docker ps
# Expected: one container named 'web_caddy_1' or similar, image caddy:2-alpine

curl -s http://127.0.0.1:80
# Expected: homelab phase 1 ready
```

- [ ] **Step 4: Confirm cloudflared is NOT running (expected)**

```bash
systemctl status cloudflared.service 2>&1 | head -3
# Expected: Unit cloudflared.service could not be found.
# (features.services.cloudflared.enable is false — correct)
```

---

## First-boot bootstrap procedure

Run these steps from homelab (SSH via Tailscale) before proceeding to Pass 2.

### Task 6: Extract homelab age keys

**Files:** none (key extraction only; keys are written into `.sops.yaml` in Task 7)

- [ ] **Step 1: Extract the sops-nix age public key**

On homelab:

```bash
sudo nix-shell -p age --run "age-keygen -y /var/lib/sops-nix/key.txt"
```

Expected output: a single line like `age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

Save this — it becomes `&host_homelab_age` in `.sops.yaml`.

- [ ] **Step 2: Convert the SSH host key to an age public key**

On homelab:

```bash
nix-shell -p ssh-to-age --run "ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub"
```

Expected output: a single line like `age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy`

Save this — it becomes `&host_homelab_ssh` in `.sops.yaml`.

---

## Pass 2 — post-first-boot

### Task 7: Update `.sops.yaml` and create `secrets/homelab.yaml`

Back on bandit (which has the user private age key at `~/.config/sops/age/keys.txt`).

**Files:**
- Modify: `.sops.yaml`
- Create: `secrets/homelab.yaml`

- [ ] **Step 1: Add homelab keys to `.sops.yaml`**

Open `.sops.yaml`. Under the `keys:` block, add the two new anchors after `&host_bandit`
(replace the placeholder values with the real keys extracted in Task 6):

```yaml
  - &host_homelab_age age1<REPLACE-WITH-OUTPUT-OF-STEP-1-IN-TASK-6>
  - &host_homelab_ssh age1<REPLACE-WITH-OUTPUT-OF-STEP-2-IN-TASK-6>
```

- [ ] **Step 2: Add the homelab creation rule BEFORE the existing catch-all rule**

The catch-all is `path_regex: secrets/.*\.ya?ml`. Insert the homelab-specific rule
immediately before it. The full updated `creation_rules:` section becomes:

```yaml
creation_rules:
  - path_regex: secrets/homelab\.ya?ml
    key_groups:
      - age:
          - *user
          - *host_homelab_age
          - *host_homelab_ssh
        pgp:
          - *gpg_user
  - path_regex: secrets/.*\.ya?ml
    key_groups:
      - age:
          - *user
          - *host_bandit
        pgp:
          - *gpg_user
```

- [ ] **Step 3: Commit the `.sops.yaml` changes (public keys only — safe to commit)**

```bash
git add .sops.yaml
git commit -m "chore(sops): add homelab age and SSH host keys as recipients"
```

- [ ] **Step 4: Create `secrets/homelab.yaml` with the Cloudflare Tunnel token**

Get the tunnel token from the Cloudflare Zero Trust dashboard:
→ Networks → Tunnels → select your tunnel → Configure → Tunnel token (copy the token string)

Then:

```bash
sops secrets/homelab.yaml
```

This opens `$EDITOR`. Enter the following YAML content (replace `<TOKEN>` with the actual
Cloudflare Tunnel token string):

```yaml
cloudflare_tunnel_token: "<TOKEN>"
# Phase 2 — populate before Phase 2 deploy:
# wordpress_db_password_business1: ""
# wordpress_db_password_business2: ""
# Phase 3 — populate before Phase 3 deploy:
# nextcloud_db_password: ""
# nextcloud_admin_password: ""
```

Save and exit. sops encrypts the file automatically using the homelab creation rule.

- [ ] **Step 5: Verify the secret is encrypted and readable**

```bash
# Should show ciphertext (NOT the plaintext token)
head -3 secrets/homelab.yaml

# Should decrypt and show the token (requires your private age key)
sops --decrypt --extract '["cloudflare_tunnel_token"]' secrets/homelab.yaml
```

- [ ] **Step 6: Commit the encrypted secret**

```bash
git add secrets/homelab.yaml
git commit -m "chore(secrets): add homelab.yaml with cloudflare tunnel token (encrypted)"
```

---

### Task 8: Enable secrets and cloudflared in homelab config (Pass 2)

**Files:**
- Modify: `nixos-configurations/homelab/default.nix`

- [ ] **Step 1: Override sops age config to include the SSH host key**

The `features.security.secrets` module sets `sops.age.sshKeyPaths = []` via `lib.mkDefault`.
For homelab we need both keys. Add the following to `homelab/default.nix` at the top
level (alongside `networking.hostName`):

```nix
  # Override sops age config: use both the auto-generated age key and the SSH
  # host key as decryption paths. This lets the host decrypt its own secrets
  # using either key, and allows re-encryption from the host via SSH access.
  sops.age = {
    keyFile = "/var/lib/sops-nix/key.txt";
    sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    generateKey = true;
  };
```

- [ ] **Step 2: Declare the cloudflare_tunnel_token sops secret**

Add the following to `homelab/default.nix` at the top level:

```nix
  sops.secrets.cloudflare_tunnel_token = {
    sopsFile = "${inputs.self}/secrets/homelab.yaml";
    mode = "0440";
    owner = "root";
    group = "cloudflared";
  };
```

Note: `group = "cloudflared"` matches the user created by the cloudflared feature module.
The `mode = "0440"` means root + cloudflared group can read it; the start script runs as
the `cloudflared` user.

- [ ] **Step 3: Add `config` to homelab/default.nix function arguments**

`homelab/default.nix` currently has `{ inputs, lib, username, ... }:`. The cloudflared
feature needs `config.sops.secrets.cloudflare_tunnel_token.path`, which requires `config`
in scope. Change the function signature from:

```nix
{
  inputs,
  lib,
  username,
  ...
}:
```

to:

```nix
{
  inputs,
  config,
  lib,
  username,
  ...
}:
```

- [ ] **Step 4: Enable secrets and cloudflared in the features block**

In the `features = { ... }` block in `homelab/default.nix`, change:

```nix
    security = {
      server-hardening = {
        enable = true;
        ssh.allowUsers = [ username ];
      };
      secrets.enable = false;
    };
```

to:

```nix
    security = {
      server-hardening = {
        enable = true;
        ssh.allowUsers = [ username ];
      };
      secrets.enable = true;
    };
```

And add cloudflared to the services block (alongside tailscale, monitoring, etc.):

```nix
      cloudflared = {
        enable = true;
        tokenFile = config.sops.secrets.cloudflare_tunnel_token.path;
      };
```

- [ ] **Step 5: Run QA — secrets/homelab.yaml must exist for this to pass**

```bash
just qa 2>&1 | tail -5
```

Expected: `all checks passed!`

If you see `error: path '/path/to/secrets/homelab.yaml' does not exist`, ensure the file
was committed in Task 7 and the repo is up to date (`git pull`).

- [ ] **Step 6: Commit Pass 2 config**

```bash
git add nixos-configurations/homelab/default.nix
git commit -m "feat(homelab/phase1): Pass 2 — enable secrets and cloudflared"
```

---

### Task 9: Pass 2 rebuild and end-to-end verification

**Files:** none (deployment and verification)

- [ ] **Step 1: Push Pass 2 changes**

```bash
git push
```

- [ ] **Step 2: Rebuild homelab**

On homelab (SSH via Tailscale):

```bash
sudo nixos-rebuild switch --flake github:6FaNcY9/nixos-config#homelab
```

- [ ] **Step 3: Verify sops-nix decrypted the secret**

```bash
sudo journalctl -u sops-nix.service -n 20 --no-pager
# Expected: no errors; secret paths listed as activated

sudo ls -la /run/secrets/
# Expected: cloudflare_tunnel_token present, owned root:cloudflared, mode 440
```

- [ ] **Step 4: Verify cloudflared connected to Cloudflare**

```bash
systemctl status cloudflared.service
# Expected: active (running)

sudo journalctl -u cloudflared.service -n 30 --no-pager
# Expected: lines like "Registered tunnel connection" with connIndex 0-3
# No "Authentication failed" or "Invalid token" errors
```

- [ ] **Step 5: Verify arion Caddy is running and reachable**

```bash
systemctl status arion-web.service
# Expected: active (running)

docker ps
# Expected: one caddy:2-alpine container

curl -s http://127.0.0.1:80
# Expected: homelab phase 1 ready
```

- [ ] **Step 6: Verify end-to-end via Cloudflare**

From bandit (or any device with internet access):

```bash
curl -s https://<your-configured-cloudflare-tunnel-hostname>/
# Expected: homelab phase 1 ready
```

Replace `<your-configured-cloudflare-tunnel-hostname>` with the hostname you set in the
Cloudflare Zero Trust tunnel ingress rules (e.g., `home.mrija.org` or a test subdomain).

- [ ] **Step 7: Confirm the Phase 2 dependency contract is intact**

```bash
# Caddy container reachable from host at 127.0.0.1:80
curl -s http://127.0.0.1:80 | grep "phase 1 ready"

# Caddyfile is at the expected declarative path
cat /etc/caddy/Caddyfile

# arion project name is 'web' (Phase 2 adds containers to this project)
systemctl list-units 'arion-*'
# Expected: arion-web.service active

# sops secrets file path is stable
ls /run/secrets/cloudflare_tunnel_token
```

Phase 1 is complete. Proceed to Phase 2 (web hosting + Homepage dashboard) once these
checks pass.
