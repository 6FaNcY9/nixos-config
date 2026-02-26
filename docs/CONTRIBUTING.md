CONTRIBUTING
============

Quick start
-----------
1. Fork this repository on GitHub and clone your fork:
   git clone <your-fork-url>
2. Enter the repo and run checks:
   nix flake check

What this repo expects
----------------------
- Username and host are auto-derived at runtime from environment variables.
  - NIXOS_CONFIG_USER overrides the local username used by the repo tools
  - NIXOS_CONFIG_HOST overrides the host name used by the repo tools
  - If not set, the repo uses your shell's $USER and the system hostname

Forking and personalization
---------------------------
To make the repository work with your own system after forking:

1. Add a new host configuration
   - Create a new directory under `home-configurations/` named after your host.
     For example: `home-configurations/my-laptop/`.
   - Copy an existing host's configuration as a starting point and edit as
     needed.

2. Adjust username / paths
   - If your login username differs from the upstream author's, set
     NIXOS_CONFIG_USER in your environment or export it in your shell profile:
       export NIXOS_CONFIG_USER="alice"

3. Configure the host name used by tooling
   - If you want the repo tools to target a different host name, set
     NIXOS_CONFIG_HOST:
       export NIXOS_CONFIG_HOST="my-laptop"
   - Or run a one-off: `NIXOS_CONFIG_HOST=my-laptop just rebuild`

Running checks
- Run `nix flake check` to run the project's flake checks and QA checks.

Secrets
-------
- Secrets live under the `secrets/` directory and are managed with sops-nix.
- Do NOT commit plaintext secrets to the repository.
- To add secrets for your host, create `secrets/<your-host>/` and follow
  sops-nix guidance to encrypt them. See sops-nix docs for formats and keys.

Architecture and deeper dive
----------------------------
- For an architectural overview and explanation of how configurations are
  structured, see `docs/architecture/`.

Notes for contributors
----------------------
- Keep changes minimal and document important decisions in commits.
- Run `nix flake check` before opening a PR.

Contact
-------
- Open issues or PRs on your fork and submit a PR back to the upstream when
  you're ready to contribute improvements.
