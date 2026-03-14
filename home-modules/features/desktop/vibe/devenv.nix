{ pkgs, ... }:

{
  # Enable .env loading in devenv (requested)
  dotenv.enable = true;

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.fd
    pkgs.ripgrep
    pkgs.fzf
    pkgs.github-mcp-server # binary: github-mcp-server + mcpcurl, needs GITHUB_TOKEN
    pkgs.playwright-mcp # binary: mcp-server-playwright
    pkgs.nodejs # npx for @modelcontextprotocol/server-memory
  ];

  # Python venv — pip-managed MCP servers not yet in nixpkgs
  languages.python = {
    enable = true;
    venv = {
      enable = true;
      requirements = ''
        fastmcp
        mcp-server-git
        mcp-server-fetch
        mcp-server-sqlite
      '';
    };
  };

  enterShell = ''
    echo "vibe devenv shell ready"
  '';

  # https://devenv.sh/tests/
  enterTest = ''
    set -euo pipefail
    git --version | grep -q "${pkgs.git.version}"
    fd --version >/dev/null
    rg --version >/dev/null
    python -c "import fastmcp"
    github-mcp-server --help >/dev/null 2>&1 || true
    mcp-server-playwright --help >/dev/null 2>&1 || true
    npx --version >/dev/null
  '';
}
