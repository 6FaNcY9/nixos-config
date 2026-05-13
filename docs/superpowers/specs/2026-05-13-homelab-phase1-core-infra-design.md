# Homelab Phase 1 — Core Infrastructure Design

**Date:** 2026-05-13
**Status:** Approved — ready for implementation plan
**Hostname placeholder:** `homelab` (replace once `hardware-configuration.nix` has real UUIDs)

---

## 1. Goal

Wire up the foundational service layer that every subsequent phase depends on:
- **arion** (NixOS-native declarative container orchestration via Podman)
- **Caddy** reverse proxy (routes inbound traffic to upstream services by hostname)
- **cloudflared** (Cloudflare Tunnel — bypasses CGNAT, no open ports required)
- **sops-nix secrets scaffolding** (secrets layer for all phases, bootstrapped from Phase 1)

Nothing in Phase 2–5 can deploy cleanly without this layer being stable.

---

## 2. Network topology

```
Internet user
    │
    ▼  HTTPS (TLS terminated at Cloudflare edge, DDoS protection included)
Cloudflare edge
    │
    │  Cloudflare Tunnel (mutual TLS, encrypted — no open ports on homelab)
    ▼
cloudflared   (NixOS systemd service, host network)
    │
    │  HTTP  →  127.0.0.1:80
    ▼
Caddy         (arion container, ports = ["127.0.0.1:80:80"])
    │
    │  routes by hostname  →  upstream container
    ▼
Service containers (Phase 2+: WordPress, Homepage, Nextcloud, Grafana)

────────────────────────────────────────────────────────
Remote administration:
  Tailscale → SSH → homelab host
  (exit-node already enabled via useRoutingFeatures = "server")
```

**Key constraint:** Caddy binds only to `127.0.0.1:80`, never `0.0.0.0`. Services are
unreachable from the LAN except through Cloudflare — there is no direct inbound path.
`network_mode = "host"` is explicitly NOT used on the Caddy container; port binding is
sufficient because cloudflared is a host process.

**TLS:** Cloudflare terminates HTTPS at the edge. The Tunnel leg is mutually authenticated
by cloudflared. Caddy speaks plain HTTP internally. No Let's Encrypt, no ACME, no cert
management in Phase 1.

---

## 3. Component specifications

### 3.1 arion

arion provides a `virtualisation.arion.projects` NixOS option that expresses
multi-container setups in Nix syntax, backed by Podman. Each project becomes a systemd
service (`arion-<name>.service`).

- **NixOS option:** `virtualisation.arion.projects.web`
- **Backend:** `podman-socket` — uses the existing `virtualisation.podman.enable = true`
  (already set in `homelab/default.nix` via `features.development.base.virtualization.podman`)
- **Phase 1 project:** `web` — contains only Caddy in Phase 1; Phase 2 adds WordPress,
  Homepage, and app containers to the same project
- **Systemd service:** `arion-web.service` — managed by NixOS; restarts on config change

### 3.2 Caddy container

- **Image:** `caddy:2-alpine`
- **Ports:** `["127.0.0.1:80:80"]` — host loopback only
- **Volumes:**
  - `/var/lib/caddy/data:/data` — Caddy persistent state (plugins, runtime data)
  - `/var/lib/caddy/config:/config` — runtime config
  - `/etc/caddy/Caddyfile:/etc/caddy/Caddyfile:ro` — managed by NixOS, read-only mount
- **Restart:** `unless-stopped`
- **Network:** default arion project bridge network (`arion-web_default`)

**Phase 1 Caddyfile** (placeholder — replaced in Phase 2 with per-domain reverse_proxy blocks):

```caddyfile
{
  admin off
}

:80 {
  respond "homelab phase 1 ready" 200
}
```

The Caddyfile is written to `/etc/caddy/Caddyfile` by NixOS (`environment.etc` or a
`systemd.tmpfiles` rule) so it is declaratively managed and survives rebuilds.

### 3.3 cloudflared NixOS service

- **NixOS option:** `services.cloudflared`
- **Feature module:** `nixos-modules/features/services/cloudflared.nix` (new, follows
  existing `features.services.*` pattern)
- **Tunnel type:** Remotely-managed tunnel (created via Cloudflare dashboard); uses
  `TUNNEL_TOKEN` environment variable — simpler than credentials-JSON and compatible
  with sops secret injection via `EnvironmentFile`
- **Token injection:** `systemd.services.cloudflared.serviceConfig.EnvironmentFile` points
  to the sops-decrypted secret path; the secret is stored in dotenv format:
  `TUNNEL_TOKEN=<token>`
- **Upstream:** All traffic forwarded to `http://127.0.0.1:80` (Caddy); all hostname
  routing logic lives in Caddy, not in cloudflared config

**Feature module options:**

```nix
options.features.services.cloudflared = {
  enable = lib.mkEnableOption "Cloudflare Tunnel ingress via cloudflared";
  tokenFile = lib.mkOption {
    type    = lib.types.path;
    description = "Path to dotenv file containing TUNNEL_TOKEN (sops secret path)";
  };
  upstream = lib.mkOption {
    type    = lib.types.str;
    default = "http://127.0.0.1:80";
    description = "Internal upstream URL (Caddy)";
  };
};
```

### 3.4 sops-nix secrets scaffolding

#### Secrets file: `secrets/homelab.yaml`

```yaml
# Managed by sops. Edit with: sops secrets/homelab.yaml
#
# Phase 1 active secrets:
cloudflare_tunnel_token: ENC[...]    # dotenv: TUNNEL_TOKEN=<token>
#
# Phase 2 placeholders (uncomment and populate before Phase 2 deploy):
# wordpress_db_password_business1: ENC[...]
# wordpress_db_password_business2: ENC[...]
#
# Phase 3 placeholders:
# nextcloud_db_password: ENC[...]
# nextcloud_admin_password: ENC[...]
```

The file cannot be created until the homelab age key exists (first-boot dependency —
see Section 5).

#### `.sops.yaml` additions

Two new keys are added:

| Anchor | Key type | Source | Purpose |
|--------|----------|--------|---------|
| `&host_homelab_age` | age public key | `/var/lib/sops-nix/key.txt` on homelab | Primary — used by sops-nix to decrypt at activation |
| `&host_homelab_ssh` | age public key (ssh-to-age) | `/etc/ssh/ssh_host_ed25519_key.pub` on homelab | Secondary — allows manual re-encryption from the homelab host without shipping the private age key |

Both require first boot to extract (neither key exists before the machine runs NixOS for
the first time).

New creation rule for `secrets/homelab.yaml` (inserted **before** the existing catch-all
rule — sops evaluates rules in order):

```yaml
  - path_regex: secrets/homelab\.ya?ml
    key_groups:
      - age:
          - *user           # bandit user age key (can re-encrypt from bandit)
          - *host_homelab_age  # homelab sops-nix key (decrypts at activation)
          - *host_homelab_ssh  # homelab SSH host key (re-encrypt from homelab host)
        pgp:
          - *gpg_user       # GPG fallback
```

The existing catch-all rule (`path_regex: secrets/.*\.ya?ml`) is unchanged and continues
to cover all other secrets.

#### sops-nix NixOS config for homelab

The `features.security.secrets` module sets `sops.age.sshKeyPaths = []` (explicit, to
avoid SSH-key-derived decryption on bandit). For homelab, both keys are needed:

```nix
# In nixos-configurations/homelab/default.nix (post first-boot):
sops.age = {
  keyFile      = "/var/lib/sops-nix/key.txt";   # primary age key (auto-generated)
  sshKeyPaths  = [ "/etc/ssh/ssh_host_ed25519_key" ];  # secondary — enables re-keying from host
  generateKey  = true;
};
```

This overrides the `lib.mkDefault` values in `features.security.secrets` without
conflicting with bandit's `sshKeyPaths = []` (each host's config is independent).

---

## 4. Repository file changes

### New files

| File | Description |
|------|-------------|
| `nixos-modules/features/services/cloudflared.nix` | Feature module wrapping `services.cloudflared` |
| `secrets/homelab.yaml` | Encrypted secrets for homelab (created post first-boot) |

### Modified files

| File | Change |
|------|--------|
| `nixos-modules/features/services/default.nix` | Add `./cloudflared.nix` import |
| `nixos-configurations/homelab/default.nix` | Add cloudflared feature, arion project, sops age config; set `secrets.enable = true` post first-boot |
| `.sops.yaml` | Add `&host_homelab_age`, `&host_homelab_ssh`, homelab creation rule |

### No changes in Phase 1

| File | Reason |
|------|--------|
| `home-configurations/vino/hosts/homelab.nix` | No HM changes needed |
| `nixos-modules/features/security/secrets.nix` | Used as-is; homelab config overrides age settings directly |
| Any existing secrets (`*.yaml` in `secrets/`) | Not re-encrypted; homelab secrets are a new file |

---

## 5. First-boot bootstrap procedure

Phase 1 has a two-pass deployment due to secrets requiring the homelab age key, which
only exists after first boot.

### Pass 1 — Deploy without secrets

1. Complete hardware setup: replace placeholder UUIDs in `hardware-configuration.nix`,
   verify BTRFS subvolume layout, confirm `mainDisk` UUID in `homelab/default.nix`.
2. Ensure `features.security.secrets.enable = false` in `homelab/default.nix`
   (already the default in the stub).
3. Deploy: `just rebuild` or `nixos-rebuild switch --flake .#homelab` from bandit via SSH.
4. Verify: SSH into homelab via Tailscale. arion Caddy container and cloudflared will NOT
   start yet (missing token); this is expected.

### Pass 2 — Extract keys, create secrets, redeploy

On the homelab host (SSH via Tailscale):

```bash
# Step 1: Extract the sops-nix age public key (auto-generated on first activation)
sudo nix-shell -p age --run "age-keygen -y /var/lib/sops-nix/key.txt"
# → age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Save this value as &host_homelab_age in .sops.yaml

# Step 2: Convert SSH host key to age public key (for secondary recipient)
nix-shell -p ssh-to-age --run \
  "ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub"
# → age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
# Save this value as &host_homelab_ssh in .sops.yaml
```

Back on bandit (or any machine with access to the user age private key):

```bash
# Step 3: Update .sops.yaml with both new keys (see Section 3.4 for exact diff)
# Add &host_homelab_age and &host_homelab_ssh under keys:
# Add the homelab.yaml creation rule (before the catch-all rule)
$EDITOR .sops.yaml

# Step 4: Create and populate secrets/homelab.yaml
# sops will encrypt using all recipients in the homelab rule
sops secrets/homelab.yaml
# In the editor, set:
#   cloudflare_tunnel_token: "TUNNEL_TOKEN=<paste token from Cloudflare dashboard>"

# Step 5: Enable secrets and add arion/cloudflared config in homelab/default.nix
# (features.security.secrets.enable = true, sops.age.sshKeyPaths, cloudflared feature,
#  arion project — see implementation plan for exact Nix)

# Step 6: Commit and push
git add .sops.yaml secrets/homelab.yaml nixos-configurations/homelab/default.nix \
        nixos-modules/features/services/cloudflared.nix \
        nixos-modules/features/services/default.nix
git commit -m "feat(homelab): Phase 1 core infra — arion, Caddy, cloudflared, sops"
git push

# Step 7: Rebuild homelab with secrets enabled
# SSH into homelab via Tailscale, then:
sudo nixos-rebuild switch --flake github:6FaNcY9/nixos-config#homelab
# or pull locally and: just rebuild
```

### Pass 2 success criteria

- `systemctl status arion-web.service` → active (running)
- `docker ps` (podman dockerCompat) shows `caddy` container running
- `systemctl status cloudflared.service` → active (running), no auth errors in journal
- `curl -s https://<configured-domain>/` → `homelab phase 1 ready`
- `systemctl status sops-nix.service` → successful secret decryption in journal

---

## 6. Phase 2 dependency contract

Phase 1 creates these stable interfaces that Phase 2 must consume — do not change these
without versioning the contract:

| Interface | Value | Consumer |
|-----------|-------|----------|
| Caddy upstream address | `http://127.0.0.1:80` | cloudflared config |
| Caddy container name in arion | `caddy` in project `web` | Phase 2 adds services to same project |
| Caddy Caddyfile path on host | `/etc/caddy/Caddyfile` | Phase 2 rewrites this file |
| sops secrets file | `secrets/homelab.yaml` | Phase 2 adds `wordpress_db_password_*` keys |
| arion project name | `web` | Phase 2 adds containers to `virtualisation.arion.projects.web` |

---

## 7. Out of scope (explicit)

- **mrija.org** — stays on TheHost shared hosting; do not migrate or touch
- **Nextcloud** — Phase 3
- **Homepage dashboard** — Phase 2
- **QEMU/VFIO/Kali VM** — Phase 4, deferred until homelab hardware UUID is confirmed
- **Prometheus/Grafana** — Phase 5
- **SSL/TLS management** — handled by Cloudflare; no cert infrastructure on homelab
- **DDNS** — not needed; Cloudflare Tunnel is CGNAT-safe with static tunnel token
