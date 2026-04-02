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

  # claude-desktop: Electron wrapper for Claude (k3d3/claude-desktop-linux-flake).
  # Uses the FHS variant for NixOS compatibility.
  claude-desktop =
    inputs.claude-desktop.packages.${final.stdenv.hostPlatform.system}.claude-desktop-with-fhs;

  # mistral-vibe: Official flake package (uv2nix Python venv wrapper).
  # Source: inputs.mistral-vibe.packages.${system}.default
  # Exposed in home-modules via mistralVibePkg, but also available as pkgs.mistral-vibe.
  mistral-vibe = inputs.mistral-vibe.packages.${final.stdenv.hostPlatform.system}.default;

  # strip-json-comments-cli: CLI tool to strip JSON comments (used by some dev tools).
  # Upstream has no package-lock.json; we vendor a generated one in overlays/npm-locks/.
  strip-json-comments-cli =
    let
      version = "3.0.0";
    in
    prev.buildNpmPackage {
      pname = "strip-json-comments-cli";
      inherit version;
      src = prev.fetchFromGitHub {
        owner = "sindresorhus";
        repo = "strip-json-comments-cli";
        rev = "v${version}";
        hash = "sha256-aMp/1/TpEed6eHU7FCXMjAkX/2EcOyhR1cPDHek4Noc=";
      };
      npmDepsHash = "sha256-XVUiaKWGX6ucnSq4G2puSjKLZukIpHscaMoVSiKvXtA=";
      dontNpmBuild = true;
      dontNpmPrune = true;
      # Upstream ships no package-lock.json; inject our vendored one.
      postPatch = ''
        cp ${./npm-locks/strip-json-comments-cli-3.0.0-lock.json} ./package-lock.json
      '';
      meta.mainProgram = "strip-json-comments";
    };

  # agentsys: AI agent orchestration CLI (used with Claude).
  # Upstream has no package-lock.json; we vendor a generated one in overlays/npm-locks/.
  agentsys =
    let
      version = "5.1.0";
    in
    prev.buildNpmPackage {
      pname = "agentsys";
      inherit version;
      src = prev.fetchFromGitHub {
        owner = "avifenesh";
        repo = "agentsys";
        rev = "v${version}";
        hash = "sha256-Ms58KSlCa1zee4yUQzXqwEmdYLjV+wYPy0Dg4jXEwB8=";
      };
      npmDepsHash = "sha256-Au15dCG96Ond/y7XisnuN9nKo/5COsdJ4feBW8fe7z0=";
      dontNpmBuild = true;
      dontNpmPrune = true;
      # Upstream ships no package-lock.json; inject our vendored one.
      # Also patch cli.js: fs.cpSync from the nix store preserves read-only permissions,
      # so ~/.agentsys ends up unwritable and npm install inside it fails with EACCES.
      # Fix: chmod -R u+w the install dir right before npm install runs.
      postPatch = ''
        cp ${./npm-locks/agentsys-5.1.0-lock.json} ./package-lock.json
        sed -i "s|execSync('npm install --production'|execSync('chmod -R u+w ' + installDir); execSync('npm install --production'|" bin/cli.js
      '';
      meta.mainProgram = "agentsys";
    };
}
