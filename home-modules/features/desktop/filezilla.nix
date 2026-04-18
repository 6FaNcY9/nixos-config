# FileZilla FTP/SFTP client configuration
#
# Manages two config files:
#   ~/.filezilla/fzdefaults.xml  — read-only Nix symlink; sets Kiosk mode 1
#                                  (no password saving) and disables update checks
#   ~/.config/filezilla/filezilla.xml — copied first-run via home.activation;
#                                       writable so FileZilla can save runtime state
#
# Theming: wxWidgets uses GTK3 as its backend, so Stylix's GTK theme applies automatically.
# No Stylix FileZilla target is needed.
#
# Reset to Nix defaults: rm ~/.config/filezilla/filezilla.xml && home-manager switch
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.features.desktop.filezilla;
in
{
  options.features.desktop.filezilla.enable =
    lib.mkEnableOption "FileZilla FTP/SFTP client configuration";

  config = lib.mkIf cfg.enable (
    let
      filezillaConfigFile = pkgs.writeText "filezilla.xml" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <FileZilla3 version="3.67.1" platform="linux">
          <Settings>
            <!-- Network -->
            <Setting name="Use Pasv mode">1</Setting>
            <Setting name="Timeout">20</Setting>
            <Setting name="Reconnect count">2</Setting>
            <Setting name="Reconnect delay">5</Setting>
            <Setting name="FTP Keep-alive commands">1</Setting>
            <!-- Transfers -->
            <Setting name="Number of Transfers">4</Setting>
            <Setting name="Concurrent download limit">4</Setting>
            <Setting name="Concurrent upload limit">2</Setting>
            <Setting name="Socket recv buffer size (v2)">4194304</Setting>
            <Setting name="Socket send buffer size (v2)">262144</Setting>
            <Setting name="Enable speed limits">0</Setting>
            <!-- File handling -->
            <Setting name="Ascii Binary mode">0</Setting>
            <Setting name="Auto Ascii no extension">1</Setting>
            <Setting name="Auto Ascii dotfiles">1</Setting>
            <Setting name="Allow transfermode fallback">1</Setting>
            <Setting name="Preserve timestamps">1</Setting>
            <Setting name="Enable invalid char filter">1</Setting>
            <Setting name="Invalid char replace">_</Setting>
            <Setting name="View hidden files">1</Setting>
            <!-- Interface -->
            <Setting name="File Pane Layout">0</Setting>
            <Setting name="File Pane Swap">0</Setting>
            <Setting name="Show Tree Local">1</Setting>
            <Setting name="Show Tree Remote">1</Setting>
            <Setting name="Show message log">1</Setting>
            <Setting name="Show queue">1</Setting>
            <Setting name="Show quickconnect bar">1</Setting>
            <Setting name="Filelist status bar">1</Setting>
            <Setting name="Queue successful autoclear">1</Setting>
            <Setting name="Minimize to tray">0</Setting>
            <Setting name="Show debug menu">0</Setting>
            <Setting name="Toolbar hidden">0</Setting>
            <!-- Column widths (local: name/size/type/modified, remote: +permissions/owner) -->
            <Setting name="Local filelist colwidths">220 80 110 130</Setting>
            <Setting name="Remote filelist colwidths">260 75 95 105 85 85</Setting>
            <Setting name="Queue column widths">200 65 200 90 65 160</Setting>
            <!-- Suppress first-run welcome dialog permanently (fake high version) -->
            <Setting name="Greeting version">9.9.9</Setting>
            <!-- Disable update check (belt-and-suspenders alongside fzdefaults.xml) -->
            <Setting name="Update Check">0</Setting>
          </Settings>
        </FileZilla3>
      '';
    in
    {
      home.packages = [ pkgs.filezilla ];

      # fzdefaults.xml — read-only administrative defaults.
      # FileZilla searches ~/.filezilla/ for this file (NOT ~/.config/filezilla/).
      # Kiosk mode 1: FileZilla saves all settings but never persists passwords.
      home.file.".filezilla/fzdefaults.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <FileZilla3>
          <Settings>
            <Setting name="Kiosk mode">1</Setting>
            <Setting name="Disable update check">1</Setting>
          </Settings>
        </FileZilla3>
      '';

      # filezilla.xml — main settings file, must be writable at runtime.
      # Copied once on first home-manager switch; never overwritten so runtime
      # state (trusted TLS certs, column widths, site manager entries) persists.
      home.activation.filezillaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.config/filezilla"
        if [ ! -f "$HOME/.config/filezilla/filezilla.xml" ]; then
          $DRY_RUN_CMD cp ${filezillaConfigFile} "$HOME/.config/filezilla/filezilla.xml"
          $DRY_RUN_CMD chmod 600 "$HOME/.config/filezilla/filezilla.xml"
        fi
      '';
    }
  );
}
