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

  # mistral-vibe: Official flake package (uv2nix Python venv wrapper).
  # Source: inputs.mistral-vibe.packages.${system}.default
  # Exposed in home-modules via mistralVibePkg, but also available as pkgs.mistral-vibe.
  mistral-vibe = inputs.mistral-vibe.packages.${final.stdenv.hostPlatform.system}.default;

  # opencode: Pinned to specific release for timely updates (nixpkgs lags fast opencode cadence).
  # The upstream hashes.json FOD hash doesn't match what local bun produces.
  # Override node_modules hash using node_modules_updater as the chain-override base.
  opencode =
    let
      inherit (final.stdenv.hostPlatform) system;
      # node_modules_updater = node_modules.override { hash = fakeHash; };
      # Chain-override with the actual hash our local bun produces.
      localNodeModules = inputs.opencode.packages.${system}.node_modules_updater.override {
        hash = "sha256-gFbo3B6TFAmin2marXlwUyfchTX6ogsaUFEzBIl4zaI=";
      };
    in
    inputs.opencode.packages.${system}.default.override {
      node_modules = localNodeModules;
    };

  # strip-json-comments-cli: thin npx wrapper — avoids vendoring a package-lock.json.
  # IMPURE: `npx --yes` fetches from the npm registry at runtime (not sandboxed).
  # Accepted trade-off: vendoring would require a package-lock.json + FOD hash update on every bump.
  strip-json-comments-cli = prev.writeShellApplication {
    name = "strip-json-comments";
    runtimeInputs = [ prev.nodejs ];
    text = ''exec npx --yes strip-json-comments-cli "$@"'';
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
