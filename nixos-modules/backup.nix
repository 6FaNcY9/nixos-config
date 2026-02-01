# Automated backup configuration with Restic
# Provides encrypted, incremental backups to various backends
{
  lib,
  config,
  pkgs,
  ...
}: let
  # Interactive backup prompt script with Gruvbox styling
  backupPromptScript = pkgs.writeShellScript "backup-prompt.sh" ''
    set -euo pipefail
    
    # Set PATH for common utilities
    export PATH="${pkgs.util-linux}/bin:${pkgs.systemd}/bin:${pkgs.coreutils}/bin:$PATH"
    
    # Gruvbox Dark Pale colors (RGB values from Stylix base16)
    GREEN='\033[38;2;175;175;0m'      # base0B
    BLUE='\033[38;2;131;173;173m'     # base0D
    YELLOW='\033[38;2;255;175;0m'     # base0A
    RED='\033[38;2;215;95;95m'        # base08
    FG='\033[38;2;218;185;151m'       # base05
    BOLD='\033[1m'
    RESET='\033[0m'
    
    # Wait for mount to be ready
    MAX_WAIT=10
    WAIT_COUNT=0
    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
      if mountpoint -q /mnt/backup; then
        break
      fi
      sleep 1
      WAIT_COUNT=$((WAIT_COUNT + 1))
    done
    
    if ! mountpoint -q /mnt/backup; then
      echo -e "''${RED}''${BOLD}ERROR:''${RESET} ''${RED}Backup USB detected but mount failed''${RESET}"
      echo -e "''${FG}Please check the USB connection and try again''${RESET}"
      echo ""
      echo -e "''${FG}Press any key to close...''${RESET}"
      read -n 1 -s
      exit 1
    fi
    
    # Display prompt
    clear
    echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
    echo -e "''${YELLOW}''${BOLD}  Restic Backup System''${RESET}"
    echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
    echo ""
    echo -e "''${GREEN}✓''${RESET} ''${FG}Backup USB detected and mounted''${RESET}"
    echo -e "''${FG}  Repository: ''${BLUE}/mnt/backup/restic''${RESET}"
    echo -e "''${FG}  Backup paths: ''${BLUE}/home''${RESET}"
    echo ""
    echo -e "''${YELLOW}''${BOLD}Start backup now?''${RESET} ''${FG}[Y/n]''${RESET}"
    echo -e "''${FG}(auto-starting in 30 seconds...)''${RESET}"
    echo ""
    
    # Read with timeout (30 seconds)
    RESPONSE=""
    if read -t 30 -n 1 RESPONSE; then
      echo ""
    else
      echo ""
      echo -e "''${YELLOW}Timeout reached, starting backup automatically...''${RESET}"
      RESPONSE="y"
    fi
    
    # Check response
    if [[ "$RESPONSE" =~ ^[Nn]$ ]]; then
      echo ""
      echo -e "''${YELLOW}Backup cancelled''${RESET}"
      echo ""
      echo -e "''${FG}Press any key to close...''${RESET}"
      read -n 1 -s
      exit 0
    fi
    
    # Start backup
    echo ""
    echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
    echo -e "''${GREEN}''${BOLD}  Starting Backup''${RESET}"
    echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
    echo ""
    
    # Run backup and capture status
    if systemctl start restic-backups-home.service 2>&1; then
      # Follow logs until service stops
      journalctl -u restic-backups-home.service -f -n 0 --no-hostname &
      LOG_PID=$!
      
      # Wait for service to complete
      while systemctl is-active --quiet restic-backups-home.service; do
        sleep 1
      done
      
      # Kill log tail
      kill $LOG_PID 2>/dev/null || true
      wait $LOG_PID 2>/dev/null || true
      
      # Check final status
      if systemctl is-failed --quiet restic-backups-home.service; then
        echo ""
        echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
        echo -e "''${RED}''${BOLD}  Backup Failed''${RESET}"
        echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
        echo ""
        echo -e "''${RED}See logs above for details''${RESET}"
      else
        echo ""
        echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
        echo -e "''${GREEN}''${BOLD}  Backup Completed Successfully''${RESET}"
        echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
        echo ""
        echo -e "''${FG}Your data has been safely backed up to the USB drive''${RESET}"
      fi
    else
      echo ""
      echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
      echo -e "''${RED}''${BOLD}  Failed to Start Backup''${RESET}"
      echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${RESET}"
      echo ""
      echo -e "''${RED}Could not start the backup service''${RESET}"
    fi
    
    echo ""
    echo -e "''${FG}Press any key to close...''${RESET}"
    read -n 1 -s
  '';
  
  # Launcher script that user clicks from notification
  backupLauncherScript = pkgs.writeShellScript "backup-launcher.sh" ''
    ${pkgs.alacritty}/bin/alacritty \
      --title "Backup Progress" \
      --option window.dimensions.columns=100 \
      --option window.dimensions.lines=35 \
      -e ${backupPromptScript}
  '';
in {
  options.backup = {
    enable = lib.mkEnableOption "automated backup with Restic";

    repositories = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          repository = lib.mkOption {
            type = lib.types.str;
            description = ''
              Repository URL (e.g., "s3:s3.amazonaws.com/bucket", "/mnt/backup", "sftp:user@host:/path")
            '';
          };

          passwordFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to file containing repository password";
          };

          paths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["/home"];
            description = "Paths to backup";
          };

          exclude = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              ".cache"
              "*.tmp"
              "*/node_modules"
              "*/.direnv"
              "*/target" # Rust build artifacts
              "*/dist" # JS build artifacts
              "*/build" # General build artifacts
            ];
            description = "Patterns to exclude from backup";
          };

          timerConfig = lib.mkOption {
            type = lib.types.attrs;
            default = {
              OnCalendar = "daily";
              Persistent = true;
              RandomizedDelaySec = "1h";
            };
            description = "Systemd timer configuration (when to run backups)";
          };

          pruneOpts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 6"
              "--keep-yearly 3"
            ];
            description = "Prune options for old backups";
          };

          checkOpts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["--read-data-subset=5%"];
            description = "Repository check options (verification)";
          };

          initialize = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Initialize repository on first run (WARNING: only enable for new repositories)";
          };

          environmentFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
              Environment file for backend credentials (e.g., AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
              Example: /run/secrets/restic-env
            '';
          };
        };
      });
      default = {};
      description = "Backup repositories configuration";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User to run backups as (must have access to backup paths)";
    };
  };

  config = lib.mkIf config.backup.enable {
    # Install Restic and backup launcher script
    environment.systemPackages = [
      pkgs.restic
      (pkgs.writeScriptBin "backup-usb" ''
        ${backupLauncherScript}
      '')
    ];

    # USB detection and desktop notification
    services.udev.extraRules = ''
      # Send notification when ResticBackup USB is inserted
      SUBSYSTEM=="block", ENV{ID_FS_LABEL}=="ResticBackup", ACTION=="add", \
      RUN+="${pkgs.systemd}/bin/systemctl start backup-usb-notify.service"
    '';

    systemd.services.backup-usb-notify = {
      description = "Notify user when backup USB is inserted";
      after = ["mnt-backup.mount"];
      
      serviceConfig = {
        Type = "oneshot";
      };
      
      script = ''
        # Set PATH for utilities
        export PATH="${pkgs.util-linux}/bin:${pkgs.systemd}/bin:${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:${pkgs.shadow}/bin:$PATH"
        
        # Ensure the mount point exists
        if [ ! -d /mnt/backup ]; then
          mkdir -p /mnt/backup
        fi
        
        # Try to mount the USB drive if not already mounted
        if ! mountpoint -q /mnt/backup; then
          systemctl start mnt-backup.mount || true
          sleep 2
        fi
        
        # Get user info
        USER_ID=$(id -u ${config.backup.user})
        
        # Send notification using runuser (part of util-linux)
        runuser -u ${config.backup.user} -- env \
          DISPLAY=:0 \
          DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
          ${pkgs.libnotify}/bin/notify-send \
            --urgency=normal \
            --icon=drive-removable-media \
            --app-name="Backup System" \
            "Backup USB Detected" \
            "Run 'backup-usb' to start backup"
      '';
    };

    # Create backup services for each repository (without timers - USB-trigger only)
    services.restic.backups =
      lib.mapAttrs (name: cfg: {
        inherit (cfg) repository passwordFile paths exclude pruneOpts initialize environmentFile;
        inherit (config.backup) user;

        # Disable automatic timer - only run via USB trigger
        timerConfig = null;

        # Backup script hooks
        backupPrepareCommand = ''
          # Set PATH for utilities
          export PATH="${pkgs.util-linux}/bin:${pkgs.systemd}/bin:${pkgs.coreutils}/bin:${pkgs.gawk}/bin:${pkgs.gnused}/bin:${pkgs.gnugrep}/bin:$PATH"
          
          # Safety check: Verify backup mount is actually mounted (not just a directory)
          BACKUP_DIR=$(dirname "${cfg.repository}")

          if ! mountpoint -q "$BACKUP_DIR"; then
            echo "ERROR: $BACKUP_DIR is not mounted"
            echo "Expected USB drive is not connected or not mounted"
            echo "Aborting backup to prevent writing to internal disk"
            exit 1
          fi

          # Extra safety: Verify it's a USB device (not internal disk)
          MOUNT_DEV=$(df "$BACKUP_DIR" | tail -1 | awk '{print $1}')
          DEV_NAME=$(basename "$MOUNT_DEV")
          # Extract base device name (e.g., sda from sda1, nvme0n1 from nvme0n1p1)
          BASE_DEV=$(echo "$DEV_NAME" | sed -E 's/p?[0-9]+$//')
          
          # Check if it's a USB device by looking at sysfs path
          if [ -e "/sys/block/$BASE_DEV" ]; then
            DEV_PATH=$(readlink -f "/sys/block/$BASE_DEV")
            if ! echo "$DEV_PATH" | grep -q '/usb'; then
              echo "ERROR: $BACKUP_DIR is on non-USB device ($MOUNT_DEV)"
              echo "Device path: $DEV_PATH"
              echo "Expected external USB drive, aborting backup"
              exit 1
            fi
          fi

          echo "✓ Backup mount verified: $MOUNT_DEV mounted at $BACKUP_DIR"
          echo "Starting backup: ${name}"
          echo "Repository: ${cfg.repository}"
          echo "Paths: ${lib.concatStringsSep ", " cfg.paths}"
        '';

        backupCleanupCommand = ''
          echo "Backup completed: ${name}"
          echo "Running prune to clean old backups..."
        '';

        # Verify backups periodically (weekly)
        inherit (cfg) checkOpts;

        # Additional restic options
        extraOptions = [
          "verbose=2" # Show more detailed progress (files being processed)
          "compression=auto"
        ];
      })
      config.backup.repositories;

    # Maintenance: Run repository checks weekly
    systemd.timers = lib.mapAttrs' (name: _:
      lib.nameValuePair "restic-check-${name}" {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          RandomizedDelaySec = "2h";
        };
      })
    config.backup.repositories;

    # Warnings for common issues
    warnings =
      lib.optionals (config.backup.repositories == {}) [
        "backup.enable is true but no repositories are configured"
      ]
      ++ (lib.concatLists (lib.mapAttrsToList (name: cfg:
        lib.optional (cfg.initialize && cfg.passwordFile == null) ''
          Repository "${name}" has initialize=true but no passwordFile set
        '')
      config.backup.repositories));
  };
}
