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

  # Validate a list of secret files: all must exist and be encrypted
  # Returns { valid = bool; assertions = [{ assertion, message }]; }
  mkSecretValidation = {
    secrets,
    label ? "secrets",
  }: let
    valid = builtins.all (path:
      (validateSecretExists path)
      && (validateSecretEncrypted path))
    secrets;
  in {
    inherit valid;
    assertions = [
      {
        assertion = valid;
        message = "${label}: one or more secret files are missing or unencrypted.";
      }
    ];
  };

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

  # Profile helpers
  mkProfile = name: default:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      description = "Enable ${name} package set.";
    };

  # Polybar helpers
  # Two-tone module style: icon block (dark color) + label block (bright variant)
  mkPolybarTwoTone = {
    icon,
    color,
    colorAlt ? "${color}-alt",
    fg ? "black",
  }: {
    format-prefix = "  ${icon} ";
    format-prefix-foreground = "\${colors.${fg}}";
    format-prefix-background = "\${colors.${color}}";
    label-foreground = "\${colors.${fg}}";
    label-background = "\${colors.${colorAlt}}";
    label-padding-left = 1;
    label-padding-right = 1;
  };

  # Two-tone style for a named state (e.g. format-volume, format-charging)
  mkPolybarTwoToneState = {
    state,
    icon,
    color,
    colorAlt ? "${color}-alt",
    fg ? "black",
  }: {
    "format-${state}-prefix" = "  ${icon} ";
    "format-${state}-prefix-foreground" = "\${colors.${fg}}";
    "format-${state}-prefix-background" = "\${colors.${color}}";
    "format-${state}" = "<label-${state}>";
    "label-${state}-foreground" = "\${colors.${fg}}";
    "label-${state}-background" = "\${colors.${colorAlt}}";
    "label-${state}-padding-left" = 1;
    "label-${state}-padding-right" = 1;
  };
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
    mkSecretValidation
    ;

  # Devshell helpers
  inherit mkDevshellMotd mkShellScript;

  # Color helpers
  inherit mkColorReplacer;

  # Profile helpers
  inherit mkProfile;

  # Polybar helpers
  inherit mkPolybarTwoTone mkPolybarTwoToneState;
}
