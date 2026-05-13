# Custom package overlays — package overrides and custom builds.
{ inputs }:
final: prev: {
  # tree-sitter-cli: Pinned to 0.26.5 for nixvim treesitter compatibility.
  # Note: Separate from the tree-sitter library that neovim links against.
  # Neovim 0.11.6 requires tree-sitter library 0.25.x (API compatibility),
  # but neovim checkhealth wants tree-sitter CLI 0.26.1+ for parsing features.
  tree-sitter-cli =
    let
      version = "0.26.5";
    in
    prev.rustPlatform.buildRustPackage {
      pname = "tree-sitter-cli";
      inherit version;

      src = prev.fetchFromGitHub {
        owner = "tree-sitter";
        repo = "tree-sitter";
        rev = "v${version}";
        hash = "sha256-tnZ8VllRRYPL8UhNmrda7IjKSeFmmOnW/2/VqgJFLgU=";
        fetchSubmodules = true;
      };

      cargoHash = "sha256-EU8kdG2NT3NvrZ1AqvaJPLpDQQwUhYG3Gj5TAjPYRsY=";

      nativeBuildInputs = [ prev.llvmPackages.libclang.lib ];
      buildInputs = [ ];

      # Disable tests (they fail when building just the CLI)
      doCheck = false;

      LIBCLANG_PATH = "${prev.llvmPackages.libclang.lib}/lib";
      BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${prev.llvmPackages.libclang.lib}/lib/clang/${prev.llvmPackages.libclang.version}/include -isystem ${prev.stdenv.cc.libc.dev}/include";

      meta = {
        description = "Tree-sitter CLI tool for parser generation and testing";
        homepage = "https://tree-sitter.github.io/tree-sitter/";
        license = prev.lib.licenses.mit;
        mainProgram = "tree-sitter";
      };
    };

  # hermes-agent: Nous Research self-improving AI agent.
  # Pulled directly from upstream flake package output (x86_64-linux default).
  hermes-agent = inputs.hermes-agent.packages.${final.stdenv.hostPlatform.system}.default;

  # mistral-vibe: Official flake package (uv2nix Python venv wrapper).
  mistral-vibe = inputs.mistral-vibe.packages.${final.stdenv.hostPlatform.system}.default;

  # opencode: anomalyco/opencode fork has correct hashes.json baked in for the current release.
  # prettier is a root devDep excluded by --filter '!./' in node_modules.nix; inject from nixpkgs.
  opencode =
    let
      inherit (final.stdenv.hostPlatform) system;
      base = inputs.opencode.packages.${system}.default;
    in
    base.overrideAttrs (old: {
      postConfigure = (old.postConfigure or "") + ''
        chmod -R u+w packages/opencode/node_modules
        mkdir -p packages/opencode/node_modules/prettier
        cp -r ${final.prettier}/lib/node_modules/prettier/. packages/opencode/node_modules/prettier/
      '';
    });

  # strip-json-comments-cli: thin npx wrapper — avoids vendoring a package-lock.json.
  # IMPURE: `npx --yes` fetches from the npm registry at runtime (not sandboxed).
  # Accepted trade-off: vendoring would require a package-lock.json + FOD hash update on every bump.
  strip-json-comments-cli = prev.writeShellApplication {
    name = "strip-json-comments";
    runtimeInputs = [ prev.nodejs ];
    text = ''exec npx --yes strip-json-comments-cli "$@"'';
  };

  # opencode-bun: Bun global-install wrapper for latest opencode-ai from npm.
  # IMPURE: installs opencode-ai@latest into $BUN_INSTALL/bin at runtime.
  # Use this alongside pkgs.opencode when you need the very latest upstream release
  # without waiting for a Nix package bump.
  # Respects BUN_INSTALL from home-modules/core/package-managers.nix (XDG-compliant).
  "opencode-bun" = prev.writeShellApplication {
    name = "opencode-bun";
    runtimeInputs = [ prev.bun ];
    text = ''
      BUN_BIN="''${BUN_INSTALL:-$HOME/.bun}/bin"
      if [ ! -x "$BUN_BIN/opencode" ]; then
        echo "opencode-bun: installing opencode-ai@latest via bun..." >&2
        bun install -g opencode-ai@latest
      fi
      exec "$BUN_BIN/opencode" "$@"
    '';
  };

  # agentsys: thin npx wrapper — avoids vendoring a package-lock.json and EACCES patch.
  # IMPURE: `npx --yes` fetches from the npm registry at runtime (not sandboxed).
  # Accepted trade-off: vendoring would require a package-lock.json + FOD hash update on every bump.
  agentsys = prev.writeShellApplication {
    name = "agentsys";
    runtimeInputs = [ prev.nodejs ];
    text = ''exec npx --yes agentsys "$@"'';
  };
}
