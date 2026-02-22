{ lib }:
let
  # Workspace helpers
  mkWorkspaceName =
    ws:
    let
      number = toString ws.number;
      icon = ws.icon or "";
    in
    if icon == "" then number else "${number}:${icon}";

  # Validation helpers
  # Validate that a secret file exists
  validateSecretExists =
    secretPath:
    assert builtins.pathExists secretPath || throw "Secret file not found: ${toString secretPath}";
    true;

  # Validate that a secret file is encrypted (basic check: not plaintext YAML/JSON)
  validateSecretEncrypted =
    secretPath:
    let
      exists = builtins.pathExists secretPath;
      content = if exists then builtins.readFile secretPath else "";
      # Check if file contains sops metadata (encrypted files have this)
      isEncrypted =
        exists
        && (lib.hasInfix "sops" content)
        && (lib.hasInfix "mac" content || lib.hasInfix "enc" content);
    in
    assert
      isEncrypted
      || throw ''
        Validation failed: Secret file appears to be unencrypted
          File: ${secretPath}
          Hint: Use 'sops -e ${secretPath}' to encrypt it
      '';
    true;

  # Validate a list of secret files: all must exist and be encrypted
  # Returns { valid = bool; assertions = [{ assertion, message }]; }
  mkSecretValidation =
    {
      secrets,
      label ? "secrets",
    }:
    let
      missing = builtins.filter (p: !(builtins.pathExists p)) secrets;
      valid = builtins.all (path: (validateSecretExists path) && (validateSecretEncrypted path)) secrets;
    in
    {
      inherit valid;
      assertions = [
        {
          assertion = valid;
          message =
            "${label}: one or more secret files are missing or unencrypted."
            + lib.optionalString (
              missing != [ ]
            ) " Missing: ${lib.concatStringsSep ", " (map toString missing)}";
        }
      ];
    };

  # Devshell helpers
  # Create a formatted MOTD (message of the day) for devshells
  mkDevshellMotd =
    {
      title,
      emoji ? "🔨",
      description ? "",
    }:
    ''
      {202}${emoji} ${title}{reset}
      ${description}
    '';

  # Shell script helpers
  # Create a shell script with standard error handling
  # Note: For scripts with runtime dependencies, use pkgs.writeShellApplication instead
  mkShellScript =
    {
      pkgs,
      name,
      body,
    }:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail
      ${body}
    '';

  # Color helpers
  # Darken a "#rrggbb" hex color by a fraction (0.0 – 1.0).
  # darkenColor 0.30 "#ff8700" => "#b25e00"
  darkenColor =
    fraction: hex:
    let
      hexDigits = "0123456789abcdef";
      hexToInt =
        c:
        let
          lower = lib.toLower c;
          idx = lib.lists.findFirstIndex (x: x == lower) null (lib.stringToCharacters hexDigits);
        in
        if idx != null then idx else 0;
      parseChannel = a: b: hexToInt a * 16 + hexToInt b;
      clamp =
        v:
        if v < 0 then
          0
        else if v > 255 then
          255
        else
          v;
      toHex =
        n:
        let
          hi = builtins.elemAt (lib.stringToCharacters hexDigits) (n / 16);
          lo = builtins.elemAt (lib.stringToCharacters hexDigits) (lib.mod n 16);
        in
        "${hi}${lo}";
    in
    assert
      (builtins.stringLength hex == 7 && builtins.substring 0 1 hex == "#")
      || throw "darkenColor: expected '#rrggbb' (7 chars), got '${hex}'";
    let
      chars = lib.stringToCharacters hex;
      r = parseChannel (builtins.elemAt chars 1) (builtins.elemAt chars 2);
      g = parseChannel (builtins.elemAt chars 3) (builtins.elemAt chars 4);
      b = parseChannel (builtins.elemAt chars 5) (builtins.elemAt chars 6);
      factor = 1.0 - fraction;
      newR = clamp (builtins.floor (r * factor + 0.5));
      newG = clamp (builtins.floor (g * factor + 0.5));
      newB = clamp (builtins.floor (b * factor + 0.5));
    in
    "#${toHex newR}${toHex newG}${toHex newB}";

  # Replace color placeholders in a string with actual color values
  # Example: mkColorReplacer {colors = {base00 = "#282828"; base01 = "#3c3836";}} "@@base00@@"
  mkColorReplacer =
    {
      colors,
      prefix ? "@@",
      suffix ? "@@",
    }:
    let
      keys = builtins.attrNames colors;
      oldStrs = map (k: "${prefix}${k}${suffix}") keys;
      newStrs = map (k: colors.${k}) keys;
    in
    builtins.replaceStrings oldStrs newStrs;

  # Profile helpers
  mkProfile =
    name: default:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      description = "Enable ${name} package set.";
    };

  # Polybar helpers
  # Two-tone module style: icon block (dark color) + label block (bright variant)
  mkPolybarTwoTone =
    {
      icon,
      color,
      colorAlt ? "${color}-alt",
      fg ? "black",
    }:
    {
      format-prefix = "  ${icon} ";
      format-prefix-foreground = "\${colors.${fg}}";
      format-prefix-background = "\${colors.${color}}";
      label-foreground = "\${colors.${fg}}";
      label-background = "\${colors.${colorAlt}}";
      label-padding-left = 1;
      label-padding-right = 1;
    };

  # Two-tone style for a named state (e.g. format-volume, format-charging)
  mkPolybarTwoToneState =
    {
      state,
      icon,
      color,
      colorAlt ? "${color}-alt",
      fg ? "black",
    }:
    {
      "format-${state}-prefix" = "  ${icon} ";
      "format-${state}-prefix-foreground" = "\${colors.${fg}}";
      "format-${state}-prefix-background" = "\${colors.${color}}";
      "format-${state}" = "<label-${state}>";
      "label-${state}-foreground" = "\${colors.${fg}}";
      "label-${state}-background" = "\${colors.${colorAlt}}";
      "label-${state}-padding-left" = 1;
      "label-${state}-padding-right" = 1;
    };
in
{
  # Workspace helpers
  inherit mkWorkspaceName;

  mkWorkspaceBindings =
    {
      mod,
      workspaces,
      commandPrefix,
      shift ? false,
    }:
    let
      keyPrefix = if shift then "${mod}+Shift+" else "${mod}+";
    in
    builtins.listToAttrs (
      map (ws: {
        name = "${keyPrefix}${toString ws.number}";
        value = "${commandPrefix} \"${mkWorkspaceName ws}\"";
      }) workspaces
    );

  # Validation helpers
  inherit
    validateSecretExists
    validateSecretEncrypted
    mkSecretValidation
    ;

  # Devshell helpers
  inherit mkDevshellMotd mkShellScript;

  # Color helpers
  inherit darkenColor mkColorReplacer;

  # Profile helpers
  inherit mkProfile;

  # Polybar helpers
  inherit mkPolybarTwoTone mkPolybarTwoToneState;
}
