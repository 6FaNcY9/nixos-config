# nixos-config — engineering contract

## Mission

Make the smallest correct change that preserves this repository's architecture. Work like a senior NixOS engineer: inspect before editing, state assumptions, prefer existing helpers and patterns, and verify claims with commands or source references.

## Architecture

- flake-parts + ez-configs auto-discovers hosts under `nixos-configurations/`
- Home Manager users auto-discover under `home-configurations/`
- NixOS modules: `nixos-modules/core/` (always on) and `nixos-modules/features/` (opt in)
- Home Manager modules: `home-modules/core/` (always on) and `home-modules/features/` (opt in)
- Shared modules: `shared-modules/` (Stylix, palette, workspaces)
- `bandit`: Framework 13 AMD, deployed, and the only host to build or test
- `homelab`: stub with placeholder UUIDs; never build it

## Repository rules

- Feature options use only `features.<category>.<name>.enable`; the old `roles.*` namespace is gone
- Prefer semantic `palette.*` colors over raw `c.baseXX`
- Shell examples must use fish syntax unless a script's shebang requires another shell
- Reuse helpers in `lib/default.nix`, especially `mkWorkspaceBindings`, `mkPolybarTwoTone`, `mkPolybarTwoToneState`, `mkPolybarIcon`, `mkBtrfsOpts`, and `mkSecretValidation`
- Format with `nix fmt` (nixfmt-rfc-style)
- Use `just --list` to discover supported workflows instead of inventing commands

## Engineering workflow

1. Read the nearest modules, tests, `justfile`, and relevant history before proposing a change.
2. For non-trivial work, present a short plan and identify risky assumptions.
3. Implement one coherent change at a time. Avoid unrelated cleanup and new dependencies.
4. Add or update the narrowest useful test or assertion.
5. Run the cheapest targeted check first, then the full QA gate when warranted.
6. Review `git diff` for accidental churn, secrets, generated files, and incomplete TODOs.
7. Report what changed, what was verified, and any remaining risk. Never claim a command passed unless it ran.

## Verification ladder

- Documentation-only: inspect the diff and validate referenced commands/paths
- Local Nix change: `nix fmt`, then the narrowest relevant evaluation
- Cross-module or host change: `just qa`
- Boot/system-sensitive change: `just qa`, then `just rebuild-test`
- If a check cannot run, explain why and provide the exact command for the user

## Autonomy and cost discipline

- Use the main model for architecture, debugging, implementation, and final review.
- Delegate only independent, bounded searches or reviews; subagents use Haiku by default.
- Do not duplicate exploration across agents. Summarize findings before spawning more work.
- Keep context lean: use `rg`, targeted file reads, and diffs rather than dumping trees or logs.
- Human mode is the default. Autonomous mode still obeys all safety rules and must stop for ambiguous requirements, secrets, destructive actions, deployment, or system activation.
- Ralph loops require measurable completion criteria, automatic verification, and an explicit `--max-iterations` (normally 5–10 on Pro). Cancel a loop that repeats the same failure twice.

## Security and change control

Never:

- read or edit `secrets/*.yaml`, `.env*`, age keys, or credential stores
- expose secret values through output, subprocess environments, logs, or commits
- use `rm -rf`, `git reset --hard`, or `git clean -f`
- build `homelab`
- run `nixos-rebuild switch`, `nh os switch`, or equivalent activation without explicit approval
- push to `main`, force-push, merge, publish, or deploy without explicit approval

Before committing, show the intended scope and ensure QA appropriate to the risk has passed.
