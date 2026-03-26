# Layer 8 Findings: overlays/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| `overlays/default.nix` | good-pattern | n/a | Single-entry re-export; no hostname or hardware references anywhere in overlays — fully portable to any host | Keep as-is |
| `overlays/custom-packages.nix` | good-pattern | n/a | `mistral-vibe` resolves its system string from `final.stdenv.hostPlatform.system` rather than a hardcoded arch string — correct cross-host pattern | Keep as-is |
| `overlays/custom-packages.nix` | good-pattern | n/a | `opencode` bun version guard uses `lib.versionAtLeast` rather than a pinned hash unconditionally — degrades gracefully when nixpkgs catches up | Keep as-is |
| `overlays/custom-packages.nix` | hardcoded-literal | minor | `bun_1_3_10` fallback contains a hardcoded `bun-linux-x64` URL; will silently produce a wrong binary on `aarch64-linux` if a second host uses that arch | Gate the fallback fetch URL on `final.stdenv.hostPlatform.system` (x86_64 vs aarch64) if ARM hosts are ever added |
| `overlays/custom-packages.nix` | hardcoded-literal | minor | `opencode` `postFixup` embeds `${final.stdenv.cc.cc.lib}/lib` as a literal `LD_LIBRARY_PATH` injection — correct for x86_64-linux glibc but would need review on musl or aarch64 | No action needed until a non-glibc/aarch64 host is added; add a comment flagging the assumption |
| `overlays/npm-locks/` | good-pattern | n/a | Vendored `package-lock.json` files for packages that lack one upstream are stored alongside the overlay, keeping reproducibility self-contained | Keep as-is |
| `overlays/custom-packages.nix` | good-pattern | n/a | `tree-sitter-cli` pin is explicitly motivated by a version compatibility comment (library vs CLI split) — future maintainers can evaluate whether the pin is still needed | Keep as-is |
