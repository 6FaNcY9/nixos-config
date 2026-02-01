{lib}: let
  # Workspace helpers
  mkWorkspaceName = ws: let
    number = builtins.toString ws.number;
    icon = ws.icon or "";
  in
    if icon == ""
    then number
    else "${number}:${icon}";

  # Validation helpers
  # Check if a file exists and is readable
  validateFileExists = path: message:
    assert builtins.pathExists path
    || builtins.throw "Validation failed: ${message}\n  File not found: ${path}"; true;

  # Check if a file has correct permissions
  # Note: This is a compile-time check, so it checks the source file in the nix store
  validateFileReadable = path: message:
    validateFileExists path message;

  # Validate that a secret file exists
  validateSecretExists = secretPath:
    validateFileExists secretPath "Secret file not found: ${secretPath}";

  # Validate that a secret file is encrypted (basic check: not plaintext YAML/JSON)
  validateSecretEncrypted = secretPath: let
    content = builtins.readFile secretPath;
    # Check if file contains sops metadata (encrypted files have this)
    isEncrypted =
      (lib.hasInfix "sops" content)
      && (lib.hasInfix "mac" content || lib.hasInfix "enc" content);
  in
    assert isEncrypted
    || builtins.throw ''
      Validation failed: Secret file appears to be unencrypted
        File: ${secretPath}
        Hint: Use 'sops -e ${secretPath}' to encrypt it
    ''; true;

  # Validate multiple secrets at once
  validateSecrets = secretPaths:
    builtins.all (path:
      (validateSecretExists path)
      && (validateSecretEncrypted path))
    secretPaths;

  # Devshell helpers
  # Create a formatted MOTD (message of the day) for devshells
  mkDevshellMotd = {
    title,
    emoji ? "🔨",
    description ? "",
  }: ''
    {202}${emoji} ${title}{reset}
    ${description}
  '';

  # Shell script helpers
  # Create a shell script with standard error handling
  # Note: For scripts with runtime dependencies, use pkgs.writeShellApplication instead
  mkShellScript = {
    pkgs,
    name,
    body,
  }:
    pkgs.writeShellScriptBin name ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      ${body}
    '';

  # Color helpers
  # Replace color placeholders in a string with actual color values
  # Example: mkColorReplacer {colors = {base00 = "#282828"; base01 = "#3c3836";}} "@@base00@@"
  mkColorReplacer = {
    colors,
    prefix ? "@@",
    suffix ? "@@",
  }: let
    keys = builtins.attrNames colors;
    oldStrs = map (k: "${prefix}${k}${suffix}") keys;
    newStrs = map (k: colors.${k}) keys;
  in
    builtins.replaceStrings oldStrs newStrs;

  # Polybar helpers
  # Create a polybar module with standard formatting
  mkPolybarModule = {
    type,
    format,
    foreground ? null,
    background ? null,
    padding ? 1,
    extraConfig ? {},
  }:
    {
      inherit type format;
      format-padding = padding;
    }
    // (lib.optionalAttrs (foreground != null) {
      format-foreground = "\${colors.${foreground}}";
    })
    // (lib.optionalAttrs (background != null) {
      format-background = "\${colors.${background}}";
    })
    // extraConfig;
in {
  # Workspace helpers
  inherit mkWorkspaceName;

  mkWorkspaceBindings = {
    mod,
    workspaces,
    commandPrefix,
    shift ? false,
  }: let
    keyPrefix =
      if shift
      then "${mod}+Shift+"
      else "${mod}+";
  in
    builtins.listToAttrs (
      map (ws: {
        name = "${keyPrefix}${builtins.toString ws.number}";
        value = "${commandPrefix} \"${mkWorkspaceName ws}\"";
      })
      workspaces
    );

  # Validation helpers
  inherit
    validateFileExists
    validateFileReadable
    validateSecretExists
    validateSecretEncrypted
    validateSecrets
    ;

  # Devshell helpers
  inherit mkDevshellMotd mkShellScript;

  # Color helpers
  inherit mkColorReplacer;

  # Polybar helpers
  inherit mkPolybarModule;

  # i3 keybinding helpers
  # Generate directional keybindings for i3 (focus/move)
  mkDirectionalBindings = {
    mod,
    command, # "focus" or "move"
    shift ? false,
  }: let
    keyPrefix =
      if shift
      then "${mod}+Shift+"
      else "${mod}+";

    # Map vim-style keys to directions
    vimKeys = {
      "j" = "left";
      "k" = "down";
      "l" = "up";
      "semicolon" = "right";
    };

    # Map arrow keys to directions
    arrowKeys = {
      "Left" = "left";
      "Down" = "down";
      "Up" = "up";
      "Right" = "right";
    };

    # Generate bindings for both vim and arrow keys
    allKeys = vimKeys // arrowKeys;
  in
    builtins.listToAttrs (
      lib.mapAttrsToList (key: direction: {
        name = "${keyPrefix}${key}";
        value = "${command} ${direction}";
      })
      allKeys
    );
}
