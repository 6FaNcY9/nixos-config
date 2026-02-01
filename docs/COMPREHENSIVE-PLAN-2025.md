# Comprehensive Improvement Plan 2025 - NixOS Configuration

**Repository**: nixos-config  
**Generated**: February 1, 2025  
**Current Status**: Phase 4 Complete (Documentation)  
**System**: Framework 13 AMD (bandit)  
**NixOS Version**: unstable (26.05)

---

## Executive Summary

This document provides a comprehensive strategic plan for evolving your NixOS configuration from its current production-ready state to a world-class, cutting-edge system. Based on analysis of 9 high-quality community configurations (4,000+ stars), extensive documentation review, and emerging NixOS patterns, this plan outlines 10 strategic phases spanning immediate priorities through long-term goals.

### Current State Assessment

**Strengths** ✅:
- **Solid Foundation**: flake-parts + ez-configs + Home Manager
- **Modern Tooling**: Stylix theming, nixvim editor, sops-nix secrets
- **Production Ready**: Phase 4 documentation complete (4,274 lines, 96 KB)
- **Well-Organized**: 43 module files, 2,097 lines of configuration
- **CI/CD Automated**: GitHub Actions for validation and weekly updates
- **Hardware Optimized**: Framework 13 AMD specific tuning

**Completed Work**:
- ✅ Phase 1: Community best practices (binary cache, unstable-primary, Framework 13 optimizations)
- ✅ Phase 2: Code quality refactoring (split monolithic modules)
- ✅ Phase 3: CI/CD automation (GitHub Actions workflows)
- ✅ Phase 4: Comprehensive documentation (troubleshooting, disaster recovery, architecture, module dev)

**Gaps Identified** 🎯:
1. No automated testing infrastructure
2. Limited security hardening (no AppArmor/SELinux profiles)
3. Single-host configuration (no multi-machine support yet)
4. No impermanence (stateful root filesystem)
5. X11-only (no Wayland support)
6. Local-only backups (no off-site disaster recovery)
7. Manual secret rotation
8. Limited monitoring (currently disabled for battery life)

---

## Strategic Roadmap Overview

| Phase | Focus Area | Timeline | Effort | Priority | Status |
|-------|------------|----------|--------|----------|--------|
| **Phase 5** | Testing Infrastructure | Week 1-2 | High | Critical | 🔜 Next |
| **Phase 6** | Security Hardening | Week 3-4 | High | Critical | Planned |
| **Phase 7** | Multi-Host Support | Week 5-6 | Medium | High | Planned |
| **Phase 8** | Backup Enhancements | Week 7-8 | Medium | High | Planned |
| **Phase 9** | Desktop Modernization | Month 3 | High | Medium | Future |
| **Phase 10** | Impermanence | Month 3-4 | High | Medium | Future |
| **Phase 11** | Advanced Monitoring | Month 4 | Medium | Low | Future |
| **Phase 12** | Performance Tuning | Month 5 | Low | Low | Future |
| **Phase 13** | Developer Experience | Month 5-6 | Medium | Medium | Future |
| **Phase 14** | Community Contribution | Ongoing | Low | Low | Future |

---

## Phase 5: Testing Infrastructure (IMMEDIATE PRIORITY)

### 🎯 Goal
Implement automated testing to catch configuration errors before deployment, ensure system reliability, and enable confident experimentation.

### 📊 Current Gap
- No integration tests
- Manual verification after changes
- Build failures only caught at deployment time
- No regression testing

### 🔬 Research Findings

**NixOS Test Framework**: Built-in virtualized testing
```nix
# tests/bandit.nix
import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "bandit-system-test";
  
  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../nixos-configurations/bandit/default.nix ];
  };
  
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("systemctl status auto-cpufreq")
    machine.succeed("systemctl status fprintd")
    machine.wait_for_file("/run/current-system")
  '';
}
```

**Community Examples**:
- **Mic92/dotfiles**: Extensive test suite with CI integration
- **Misterio77/nix-config**: Per-host NixOS tests
- **NixOS Examples**: Official test examples in nixpkgs

### 📋 Implementation Plan

#### 5.1 Unit Tests for Modules
**File**: `tests/unit/` directory

**What to Test**:
- Module option validation
- Helper functions in `lib/default.nix`
- Secret validation logic
- Configuration generation (i3 bindings, polybar modules)

**Example Test**:
```nix
# tests/unit/lib-helpers.nix
let
  lib = import ../../lib { inherit (pkgs) lib; };
  
  testWorkspaceBindings = lib.mkWorkspaceBindings {
    mod = "Mod4";
    workspaces = [ "1" "2" "3" ];
    commandPrefix = "workspace";
  };
in
pkgs.runCommand "test-workspace-bindings" {} ''
  ${pkgs.lib.assertMsg 
    (builtins.length (builtins.attrNames testWorkspaceBindings) == 3)
    "Expected 3 workspace bindings"}
  touch $out
''
```

#### 5.2 Integration Tests
**File**: `tests/integration/` directory

**Test Scenarios**:
1. **System Boot Test**: Verify system boots to multi-user.target
2. **Desktop Test**: X11 starts, i3 launches, Stylix applies theme
3. **Services Test**: All enabled systemd services start successfully
4. **Secrets Test**: sops-nix decrypts secrets correctly
5. **Backup Test**: Restic backup runs without errors
6. **Hardware Test**: Framework 13 specific features (fprintd, auto-cpufreq)

**Example**:
```nix
# tests/integration/desktop.nix
{
  name = "desktop-environment";
  
  nodes.machine = { ... }: {
    imports = [ ../../nixos-configurations/bandit/default.nix ];
  };
  
  testScript = ''
    machine.start()
    machine.wait_for_x()
    machine.wait_for_window("i3")
    machine.screenshot("desktop")
    
    # Test i3 keybinding
    machine.send_key("alt-ret")  # Open terminal
    machine.wait_for_window("Alacritty")
    
    # Test Stylix colors
    machine.succeed("xrdb -query | grep -i gruvbox")
  '';
}
```

#### 5.3 CI Integration
**File**: `.github/workflows/test.yml`

```yaml
name: NixOS Tests

on:
  pull_request:
  push:
    branches: [main, dev]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - name: Run unit tests
        run: nix build .#checks.x86_64-linux.unit-tests
  
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - name: Run integration tests
        run: nix build .#checks.x86_64-linux.integration-tests
```

#### 5.4 Test Helpers & Utilities
**File**: `tests/lib.nix`

```nix
{ pkgs, lib }: {
  # Assertion helper
  assertModuleOption = module: option: expected:
    let
      actual = (evalModules { modules = [ module ]; }).config.${option};
    in
      lib.assertMsg (actual == expected)
        "Expected ${option} to be ${expected}, got ${actual}";
  
  # Secret validation helper
  assertSecretExists = path:
    lib.assertMsg (builtins.pathExists path)
      "Secret file not found: ${path}";
  
  # Service test helper
  waitForService = service: ''
    machine.wait_for_unit("${service}.service")
    machine.succeed("systemctl is-active ${service}")
  '';
}
```

### 📈 Success Metrics
- [ ] 100% of critical modules have unit tests
- [ ] Integration tests cover all system roles (desktop, laptop, server)
- [ ] CI runs tests on every PR/push
- [ ] Test suite completes in <10 minutes
- [ ] Zero false positives (flaky tests)

### 🎁 Benefits
- **Confidence**: Catch breaking changes before deployment
- **Documentation**: Tests serve as usage examples
- **Regression Prevention**: Ensure fixes stay fixed
- **Faster Development**: Quick feedback loop
- **Multi-host Support**: Test all configurations in CI

### 📚 Resources
- [NixOS Test Framework](https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests)
- [Mic92 Test Examples](https://github.com/Mic92/dotfiles/tree/main/tests)
- [NixOS Integration Tests](https://github.com/NixOS/nixpkgs/tree/master/nixos/tests)

---

## Phase 6: Security Hardening (HIGH PRIORITY)

### 🎯 Goal
Implement defense-in-depth security measures to protect against malware, unauthorized access, and data exfiltration.

### 📊 Current Gap
- No mandatory access control (AppArmor/SELinux)
- No application sandboxing (Firejail/Bubblewrap)
- No USB device restrictions
- No audit logging
- Weak sudo configuration (no 2FA)

### 🔬 Research Findings

**AppArmor on NixOS**:
```nix
security.apparmor = {
  enable = true;
  packages = [ pkgs.apparmor-profiles ];
};

# Custom profiles
environment.etc."apparmor.d/firefox".text = ''
  #include <tunables/global>
  
  /usr/lib/firefox/firefox {
    #include <abstractions/base>
    #include <abstractions/gnome>
    
    /home/*/.mozilla/** rw,
    /tmp/** rw,
    network inet stream,
    network inet6 stream,
  }
'';
```

**Community Examples**:
- **NixOS Wiki**: Security hardening guide
- **Misterio77/nix-config**: Full AppArmor profiles
- **Framework Community**: Hardware security recommendations

### 📋 Implementation Plan

#### 6.1 Mandatory Access Control (AppArmor)
**File**: `nixos-modules/security/apparmor.nix`

**Profiles to Create**:
1. **Firefox**: Restrict filesystem access, network only to HTTPS
2. **Thunar**: Limit to home directory and removable media
3. **Custom scripts**: Sandbox backup scripts, update scripts
4. **Development tools**: Restrict compiler access to project directories

**Example Profile**:
```nix
{ config, pkgs, lib, ... }: {
  options.security.hardenedProfiles = lib.mkEnableOption "hardened AppArmor profiles";
  
  config = lib.mkIf config.security.hardenedProfiles {
    security.apparmor = {
      enable = true;
      packages = [ pkgs.apparmor-profiles ];
      
      profiles = {
        firefox = {
          enable = true;
          profile = ''
            #include <tunables/global>
            
            profile firefox /usr/lib/firefox/firefox {
              #include <abstractions/base>
              #include <abstractions/fonts>
              #include <abstractions/X>
              
              # Allow home directory (read-only except .mozilla)
              owner /home/*/ r,
              owner /home/*/.mozilla/** rw,
              
              # Downloads
              owner /home/*/Downloads/** rw,
              
              # Deny sensitive files
              deny /home/*/.ssh/** rw,
              deny /home/*/.gnupg/** rw,
              deny /var/lib/sops-nix/** rw,
              
              # Network
              network inet stream,
              network inet6 stream,
            }
          '';
        };
      };
    };
  };
}
```

#### 6.2 Application Sandboxing
**File**: `nixos-modules/security/sandboxing.nix`

**Firejail Integration**:
```nix
{ config, pkgs, lib, ... }: {
  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      firefox = {
        executable = "${pkgs.firefox}/bin/firefox";
        profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
        extraArgs = [
          "--private-dev"
          "--private-tmp"
          "--nogroups"
        ];
      };
      
      thunderbird = {
        executable = "${pkgs.thunderbird}/bin/thunderbird";
        profile = "${pkgs.firejail}/etc/firejail/thunderbird.profile";
      };
      
      mpv = {
        executable = "${pkgs.mpv}/bin/mpv";
        profile = "${pkgs.firejail}/etc/firejail/mpv.profile";
      };
    };
  };
}
```

#### 6.3 USB Security
**File**: `nixos-modules/security/usb-guard.nix`

**USBGuard Configuration**:
```nix
{ config, lib, ... }: {
  services.usbguard = {
    enable = true;
    
    # Default policy: block unknown devices
    implicitPolicyTarget = "block";
    
    # Allow framework laptop built-in devices
    rules = ''
      allow id 32ac:0012 # Framework Laptop fingerprint reader
      allow id 32ac:0014 # Framework Laptop webcam
      allow with-interface 03:00:00 # USB HID devices (keyboard/mouse)
      allow with-interface 03:01:00 # USB keyboards
      allow with-interface 08:06:50 # USB mass storage (for backup drive)
    '';
    
    # Audit logging
    auditBackend = "LinuxAudit";
  };
  
  # User can authorize devices
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.usbguard.Policy1.listRules" &&
          subject.user == "vino") {
        return polkit.Result.YES;
      }
    });
  '';
}
```

#### 6.4 Audit Logging
**File**: `nixos-modules/security/audit.nix`

**Linux Audit Framework**:
```nix
{ config, pkgs, lib, ... }: {
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      # Monitor sudo usage
      "-a always,exit -F arch=b64 -S execve -F euid=0 -F key=sudo"
      
      # Monitor secret file access
      "-w /var/lib/sops-nix/key.txt -p rwa -k secrets"
      "-w /run/secrets/ -p rwa -k secrets"
      
      # Monitor configuration changes
      "-w /etc/nixos/ -p wa -k config"
      
      # Monitor user creation/deletion
      "-w /etc/passwd -p wa -k users"
      "-w /etc/group -p wa -k users"
      
      # Monitor network configuration
      "-w /etc/resolv.conf -p wa -k network"
    ];
  };
  
  # Rotation
  systemd.tmpfiles.rules = [
    "d /var/log/audit 0750 root root 30d"
  ];
}
```

#### 6.5 Enhanced Sudo Security
**File**: `nixos-modules/security/sudo.nix`

**2FA for Sudo** (Optional):
```nix
{ config, pkgs, lib, ... }: {
  options.security.sudo2fa = lib.mkEnableOption "require 2FA for sudo";
  
  config = lib.mkIf config.security.sudo2fa {
    security.pam.services.sudo = {
      googleAuthenticator.enable = true;
      text = ''
        auth required pam_google_authenticator.so
        auth include system-auth
        account include system-auth
        password include system-auth
        session include system-auth
      '';
    };
    
    # Install google-authenticator
    environment.systemPackages = [ pkgs.google-authenticator ];
  };
  
  # Sudo timeout reduction
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=5
    Defaults lecture = always
    Defaults logfile=/var/log/sudo.log
  '';
}
```

#### 6.6 Filesystem Encryption Enforcement
**File**: `nixos-modules/security/encryption.nix`

**LUKS Encryption Check**:
```nix
{ config, lib, ... }: {
  # Verify root is encrypted
  assertions = [
    {
      assertion = 
        builtins.any (fs: fs.encrypted or false) 
        (builtins.attrValues config.fileSystems);
      message = "Root filesystem must be encrypted (LUKS)";
    }
  ];
  
  # Enforce secure boot (if available)
  boot.loader.systemd-boot.editor = false;  # Disable boot editor
  
  # Kernel hardening
  boot.kernelParams = [
    "slab_nomerge"           # Prevent heap exploitation
    "init_on_alloc=1"        # Zero memory on allocation
    "init_on_free=1"         # Zero memory on free
    "page_alloc.shuffle=1"   # Randomize page allocator
  ];
}
```

### 📈 Success Metrics
- [ ] AppArmor profiles for 90% of user-facing applications
- [ ] USBGuard blocking unknown devices
- [ ] Audit logs capturing security events
- [ ] Zero unauthorized access in audit logs
- [ ] Firejail sandboxing critical applications

### 🎁 Benefits
- **Defense in Depth**: Multiple security layers
- **Malware Protection**: Sandboxing limits damage
- **Audit Trail**: Track security events
- **USB Security**: Prevent BadUSB attacks
- **Compliance**: Meet security best practices

### 📚 Resources
- [NixOS Security Hardening](https://nixos.wiki/wiki/Security)
- [AppArmor Profile Reference](https://gitlab.com/apparmor/apparmor/-/wikis/home)
- [USBGuard Documentation](https://usbguard.github.io/)
- [Linux Audit Framework](https://github.com/linux-audit/audit-documentation)

---

## Phase 7: Multi-Host Support (HIGH PRIORITY)

### 🎯 Goal
Transform single-host configuration into a scalable multi-machine setup supporting laptops, desktops, and servers from one repository.

### 📊 Current Gap
- Configuration tied to single host (bandit)
- No server role implementation
- No cross-host secret sharing
- No host-specific profiles beyond basic overrides

### 🔬 Research Findings

**Community Patterns**:
- **Misterio77/nix-config**: 7 hosts (laptops, desktops, servers, WSL)
- **Mic92/dotfiles**: 12+ hosts including Raspberry Pi, NixOS containers
- **Pattern**: Shared modules + host-specific overrides + role system

**Best Practices**:
1. Shared modules in `nixos-modules/` and `home-modules/`
2. Host-specific configs in `nixos-configurations/<hostname>/`
3. Role-based inclusion (`roles.desktop`, `roles.server`, `roles.laptop`)
4. Per-host secrets with sops-nix age keys
5. Network topology in `shared-modules/network.nix`

### 📋 Implementation Plan

#### 7.1 Host Templates
**Files**: `nixos-configurations/templates/`

**Laptop Template**:
```nix
# nixos-configurations/templates/laptop.nix
{ lib, ... }: {
  # Framework 13 AMD laptop defaults
  roles = {
    desktop = true;
    laptop = true;
    development = true;
  };
  
  # Power management
  services.auto-cpufreq.enable = true;
  services.fprintd.enable = true;
  
  # Hardware
  hardware.bluetooth.enable = true;
  hardware.cpu.amd.updateMicrocode = true;
  
  # Desktop variant
  desktop.variant = "i3-xfce";
  
  # Backup (local USB)
  backup.enable = true;
  backup.repositories.home.repository = "/mnt/backup/restic";
  
  # Monitoring (disabled for battery)
  monitoring.enable = false;
}
```

**Server Template**:
```nix
# nixos-configurations/templates/server.nix
{ lib, ... }: {
  # Headless server defaults
  roles = {
    desktop = false;
    laptop = false;
    server = true;
  };
  
  # Server base
  server.base.enable = true;
  server.ssh.allowUsers = [ "vino" ];
  server.fail2ban.enable = true;
  
  # Backup (cloud)
  backup.enable = true;
  backup.repositories.home.repository = "s3:s3.amazonaws.com/backups";
  
  # Monitoring (always on)
  monitoring.enable = true;
  monitoring.grafana.enable = true;
  
  # No GUI
  services.xserver.enable = lib.mkForce false;
}
```

**Desktop Template**:
```nix
# nixos-configurations/templates/desktop.nix
{ lib, ... }: {
  # Workstation defaults
  roles = {
    desktop = true;
    laptop = false;
    development = true;
  };
  
  # Full desktop environment
  desktop.variant = "i3-xfce";
  
  # Performance (no battery constraints)
  services.auto-cpufreq.enable = false;
  powerManagement.enable = false;
  
  # Monitoring (always on AC)
  monitoring.enable = true;
  
  # Enhanced dev tools
  profiles.dev = true;
  profiles.extras = true;
}
```

#### 7.2 Example Hosts

**Server Host**:
```nix
# nixos-configurations/server-home/default.nix
{ config, inputs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../templates/server.nix
  ];
  
  networking.hostName = "server-home";
  
  # Host-specific overrides
  server.ssh.allowUsers = [ username "admin" ];
  
  # Services
  services.postgresql.enable = true;
  services.nginx.enable = true;
  
  # Backup to cloud
  backup.repositories.home = {
    repository = "s3:s3.amazonaws.com/nixos-backups";
    environmentFile = "/run/secrets/aws-credentials";
    timerConfig.OnCalendar = "daily";
  };
}
```

**Second Laptop**:
```nix
# nixos-configurations/framework-work/default.nix
{ config, inputs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../templates/laptop.nix
  ];
  
  networking.hostName = "framework-work";
  
  # Different device names
  devices.networkInterface = "wlp2s0";
  devices.backlight = "amdgpu_bl1";
  
  # Work-specific packages
  profiles.dev = true;
  
  # VPN for work
  services.openvpn.servers.work = {
    config = "/run/secrets/work-vpn.ovpn";
    autoStart = true;
  };
}
```

#### 7.3 Network Topology
**File**: `shared-modules/network.nix`

```nix
{ lib, ... }: {
  # Define network topology
  options.networking.hostTopology = lib.mkOption {
    type = lib.types.attrs;
    default = {
      hosts = {
        bandit = {
          type = "laptop";
          ip = "192.168.1.100";
          location = "mobile";
        };
        server-home = {
          type = "server";
          ip = "192.168.1.10";
          location = "home";
        };
      };
      
      networks = {
        home = {
          subnet = "192.168.1.0/24";
          gateway = "192.168.1.1";
          dns = [ "1.1.1.1" "8.8.8.8" ];
        };
      };
    };
  };
}
```

#### 7.4 Per-Host Secrets
**File**: `secrets/hosts/` directory

**Age Key per Host**:
```bash
# Generate age key for each host
ssh-keyscan bandit > bandit-host-key.pub
nix shell nixpkgs#ssh-to-age -c ssh-to-age < bandit-host-key.pub > bandit.age.pub

ssh-keyscan server-home > server-home-host-key.pub
nix shell nixpkgs#ssh-to-age -c ssh-to-age < server-home-host-key.pub > server-home.age.pub
```

**SOPS Configuration**:
```yaml
# .sops.yaml
keys:
  - &admin age1qy4t... # Admin key
  - &bandit age1xyz... # Bandit host key
  - &server age1abc... # Server host key

creation_rules:
  # Shared secrets (all hosts)
  - path_regex: secrets/shared/.*\.yaml$
    key_groups:
      - age:
          - *admin
          - *bandit
          - *server
  
  # Host-specific secrets
  - path_regex: secrets/hosts/bandit/.*\.yaml$
    key_groups:
      - age:
          - *admin
          - *bandit
  
  - path_regex: secrets/hosts/server-home/.*\.yaml$
    key_groups:
      - age:
          - *admin
          - *server
```

#### 7.5 Flake Multi-Host Configuration
**File**: `flake.nix` (update)

```nix
# flake.nix
ezConfigs = {
  root = ./.;
  globalArgs = { inherit inputs username repoRoot; };
  
  nixos.hosts = {
    bandit = {
      userHomeModules = ["vino"];
      importDefault = true;
    };
    
    server-home = {
      userHomeModules = ["vino"];
      importDefault = true;
    };
    
    framework-work = {
      userHomeModules = ["vino"];
      importDefault = true;
    };
  };
};

# CI checks for all hosts
checks = {
  nixos-bandit = self.nixosConfigurations.bandit.config.system.build.toplevel;
  nixos-server = self.nixosConfigurations.server-home.config.system.build.toplevel;
  nixos-work = self.nixosConfigurations.framework-work.config.system.build.toplevel;
  
  home-bandit = self.homeConfigurations."vino@bandit".activationPackage;
  home-server = self.homeConfigurations."vino@server-home".activationPackage;
  home-work = self.homeConfigurations."vino@framework-work".activationPackage;
};
```

### 📈 Success Metrics
- [ ] 3+ hosts configured from single repository
- [ ] Shared modules work across all hosts
- [ ] Per-host secrets managed with sops-nix
- [ ] CI validates all host configurations
- [ ] Zero duplication between host configs

### 🎁 Benefits
- **Scalability**: Easy to add new machines
- **Consistency**: Shared configuration across fleet
- **Maintainability**: Change once, apply everywhere
- **Flexibility**: Per-host overrides when needed
- **Disaster Recovery**: Rebuild any host from git

### 📚 Resources
- [Misterio77 Multi-Host Setup](https://github.com/Misterio77/nix-config)
- [NixOS Manual: Multiple Configurations](https://nixos.org/manual/nixos/stable/#sec-multi-configurations)
- [SOPS-Nix Multi-Host](https://github.com/Mic92/sops-nix#multi-host-setup)

---

## Phase 8: Backup Enhancements (HIGH PRIORITY)

### 🎯 Goal
Implement robust 3-2-1 backup strategy: 3 copies, 2 different media types, 1 off-site location.

### 📊 Current Gap
- Only local USB backups (single point of failure)
- No off-site disaster recovery
- No backup verification automation
- No restore testing
- Limited retention policies

### 🔬 Research Findings

**3-2-1 Backup Rule**:
- **3 copies**: Original + 2 backups
- **2 media types**: Local USB + Cloud
- **1 off-site**: Cloud storage or remote NAS

**Restic Best Practices**:
- Multiple repositories (local + remote)
- Automated verification (`restic check`)
- Restore testing (monthly drills)
- Bandwidth limiting for cloud backups
- Backup health monitoring

**Cloud Options**:
1. **Backblaze B2**: $6/TB/month, S3-compatible
2. **Wasabi**: $7/TB/month, free egress
3. **AWS S3 Glacier**: $4/TB/month (slower retrieval)
4. **Self-hosted**: Synology/TrueNAS at friend's house

### 📋 Implementation Plan

#### 8.1 Multi-Repository Backup
**File**: `nixos-modules/backup.nix` (enhance)

```nix
{ config, lib, pkgs, ... }: {
  backup.repositories = {
    # Local USB (existing)
    local = {
      repository = "/mnt/backup/restic";
      passwordFile = config.sops.secrets.restic_password.path;
      initialize = true;
      
      paths = [ "/home" ];
      exclude = [
        ".cache"
        "node_modules"
        ".direnv"
        "target"
        ".snapshots"
        "Downloads/torrents"
      ];
      
      timerConfig.OnCalendar = "daily";
      timerConfig.RandomizedDelaySec = "1h";
      
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
      ];
    };
    
    # Cloud backup (NEW)
    cloud = {
      repository = "b2:nixos-backups:/home-backups";
      passwordFile = config.sops.secrets.restic_password.path;
      environmentFile = config.sops.secrets.backblaze_credentials.path;
      initialize = true;
      
      paths = [ "/home" ];
      exclude = [
        ".cache"
        "node_modules"
        ".direnv"
        "target"
        ".snapshots"
        "Downloads"  # Don't backup downloads to cloud
        "Videos"     # Large media files
      ];
      
      timerConfig.OnCalendar = "weekly";  # Less frequent for cloud
      timerConfig.RandomizedDelaySec = "6h";
      
      # Bandwidth limiting
      extraBackupArgs = [
        "--limit-upload 5000"  # 5 MB/s upload limit
      ];
      
      pruneOpts = [
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 5"
      ];
    };
  };
}
```

#### 8.2 Backup Verification
**File**: `nixos-modules/backup.nix` (add)

```nix
systemd.services.restic-check-local = {
  description = "Verify local restic backup integrity";
  
  serviceConfig = {
    Type = "oneshot";
    User = "root";
    EnvironmentFile = config.backup.repositories.local.passwordFile;
  };
  
  script = ''
    ${pkgs.restic}/bin/restic -r ${config.backup.repositories.local.repository} \
      check --read-data-subset=5%
    
    # Send notification on failure
    if [ $? -ne 0 ]; then
      ${pkgs.libnotify}/bin/notify-send -u critical \
        "Backup Verification Failed" \
        "Local restic repository check failed"
    fi
  '';
};

systemd.timers.restic-check-local = {
  description = "Verify local backups weekly";
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "Sun 03:00";  # Sunday 3am
    Persistent = true;
  };
};

# Cloud verification (monthly, less aggressive)
systemd.services.restic-check-cloud = {
  description = "Verify cloud restic backup integrity";
  
  serviceConfig = {
    Type = "oneshot";
    User = "root";
    EnvironmentFile = [
      config.backup.repositories.cloud.passwordFile
      config.backup.repositories.cloud.environmentFile
    ];
  };
  
  script = ''
    ${pkgs.restic}/bin/restic -r ${config.backup.repositories.cloud.repository} \
      check --read-data-subset=1%  # Less data to save bandwidth
  '';
};

systemd.timers.restic-check-cloud = {
  description = "Verify cloud backups monthly";
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "monthly";
    Persistent = true;
  };
};
```

#### 8.3 Restore Testing
**File**: `tests/backup-restore.sh`

```bash
#!/usr/bin/env bash
# Automated restore testing script

set -euo pipefail

RESTIC_REPOSITORY="${1:-/mnt/backup/restic}"
TEST_DIR="/tmp/restic-restore-test-$(date +%s)"
TEST_FILES=(
  "$HOME/.config/nixos"
  "$HOME/.ssh/config"
  "$HOME/Documents/important.txt"
)

echo "Starting restore test for repository: $RESTIC_REPOSITORY"

# Create test directory
mkdir -p "$TEST_DIR"

# Restore latest snapshot
restic -r "$RESTIC_REPOSITORY" restore latest --target "$TEST_DIR"

# Verify test files exist
for file in "${TEST_FILES[@]}"; do
  restored_file="$TEST_DIR$file"
  if [ ! -f "$restored_file" ]; then
    echo "ERROR: File not found in restore: $file"
    exit 1
  fi
  echo "✓ Verified: $file"
done

# Compare checksums
echo "Comparing checksums..."
for file in "${TEST_FILES[@]}"; do
  if [ -f "$file" ]; then
    original_sum=$(sha256sum "$file" | awk '{print $1}')
    restored_sum=$(sha256sum "$TEST_DIR$file" | awk '{print $1}')
    
    if [ "$original_sum" == "$restored_sum" ]; then
      echo "✓ Checksum match: $file"
    else
      echo "ERROR: Checksum mismatch: $file"
      exit 1
    fi
  fi
done

# Cleanup
rm -rf "$TEST_DIR"

echo "✓ Restore test passed!"
```

**Systemd Timer**:
```nix
systemd.services.restic-restore-test = {
  description = "Test restic backup restore";
  path = [ pkgs.restic pkgs.coreutils ];
  script = "${./tests/backup-restore.sh} /mnt/backup/restic";
};

systemd.timers.restic-restore-test = {
  description = "Monthly restore testing";
  wantedBy = [ "timers.target" ];
  timerConfig.OnCalendar = "monthly";
};
```

#### 8.4 Backup Health Monitoring
**File**: `nixos-modules/backup-monitoring.nix`

```nix
{ config, lib, pkgs, ... }: {
  # Prometheus exporter for restic
  services.prometheus.exporters.restic = {
    enable = true;
    port = 9753;
    repositories = [
      config.backup.repositories.local.repository
      config.backup.repositories.cloud.repository
    ];
    passwordFile = config.sops.secrets.restic_password.path;
  };
  
  # Grafana dashboard for backups
  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "Restic Backups";
      options.path = ./grafana-dashboards/restic.json;
    }
  ];
  
  # Alert if backup hasn't run in 48h
  services.prometheus.rules = [
    ''
      groups:
        - name: backup
          rules:
            - alert: BackupNotRun
              expr: time() - restic_backup_timestamp > 172800
              for: 1h
              annotations:
                summary: "Backup hasn't run in 48 hours"
                description: "Repository {{ $labels.repository }} last backup: {{ $value }}s ago"
    ''
  ];
}
```

#### 8.5 Backup Secrets
**File**: `secrets/backblaze.yaml`

```yaml
# Encrypted with sops
b2_account_id: ENC[AES256_GCM,data:...]
b2_account_key: ENC[AES256_GCM,data:...]
```

**SOPS Decryption**:
```nix
sops.secrets."backblaze_credentials" = {
  sopsFile = ../../secrets/backblaze.yaml;
  format = "yaml";
  owner = "root";
  mode = "0400";
  
  # Generate environment file for restic
  path = "/run/secrets/backblaze.env";
  restartUnits = [ "restic-backups-cloud.service" ];
};

# Transform YAML to env format
systemd.services.restic-backups-cloud.preStart = ''
  cat ${config.sops.secrets.backblaze_credentials.path} | \
    ${pkgs.yq-go}/bin/yq eval-all '.b2_account_id, .b2_account_key' - | \
    awk 'NR==1{print "B2_ACCOUNT_ID=" $0} NR==2{print "B2_ACCOUNT_KEY=" $0}' \
    > /run/secrets/backblaze.env
'';
```

### 📈 Success Metrics
- [ ] Local + cloud backups running automatically
- [ ] Backup verification runs weekly (local) and monthly (cloud)
- [ ] Restore testing passes monthly
- [ ] Backup monitoring in Grafana (when enabled)
- [ ] Zero data loss in disaster scenarios

### 🎁 Benefits
- **Disaster Recovery**: Off-site backups survive house fire/theft
- **Data Integrity**: Regular verification catches corruption
- **Confidence**: Monthly restore testing proves backups work
- **Automation**: Set it and forget it
- **Compliance**: Meet 3-2-1 backup best practice

### 💰 Cost Analysis
**Backblaze B2** (recommended):
- 500 GB backup: $3/month
- 1 TB backup: $6/month
- Free 10 GB/day download

**Wasabi**:
- 1 TB minimum: $7/month
- Unlimited egress

**Recommendation**: Start with Backblaze B2, upgrade to Wasabi if >1TB

### 📚 Resources
- [Restic Documentation](https://restic.readthedocs.io/)
- [Backblaze B2 + Restic Guide](https://help.backblaze.com/hc/en-us/articles/360048632512-Using-Restic-with-Backblaze-B2)
- [3-2-1 Backup Strategy](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/)

---

## Phase 9: Desktop Modernization (MEDIUM PRIORITY)

### 🎯 Goal
Migrate from X11 to Wayland compositor (Hyprland) for better performance, security, and modern features.

### 📊 Current Gap
- X11 (legacy, security concerns)
- No fractional scaling
- No mixed DPI support
- No per-monitor VRR (Variable Refresh Rate)
- Screen tearing on some applications

### 🔬 Research Findings

**Wayland Benefits**:
- Better security (app isolation)
- Smoother rendering (no tearing)
- Better multi-monitor support
- Modern features (fractional scaling, HDR)
- Lower latency input

**Hyprland vs Sway**:
- **Hyprland**: Eye candy, animations, extensive config
- **Sway**: Drop-in i3 replacement, stable, minimal

**NixOS Wayland Stack**:
- Compositor: Hyprland or Sway
- Status bar: Waybar (replaces Polybar)
- App launcher: rofi-wayland or fuzzel
- Screen locker: swaylock
- Notifications: mako or dunst
- Screenshot: grim + slurp
- Terminal: Still alacritty (already Wayland-native)

**Community Adoption**:
- **Misterio77/nix-config**: Full Hyprland setup
- **gpskwlkr/nixos-hyprland-flake**: Framework 13 + Hyprland
- **Adoption rate**: ~30% of new configs using Wayland

### 📋 Implementation Plan

#### 9.1 Parallel Installation (Safe Migration)
**File**: `nixos-modules/desktop-wayland.nix`

**Strategy**: Keep i3 + XFCE, add Hyprland as alternative session

```nix
{ config, lib, pkgs, ... }: {
  options.desktop.wayland.enable = lib.mkEnableOption "Wayland session (Hyprland)";
  
  config = lib.mkIf config.desktop.wayland.enable {
    # Install Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;  # For legacy apps
    };
    
    # XDG desktop portal for screensharing
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
    
    # Environment variables
    environment.sessionVariables = {
      # Force Wayland for apps that support it
      MOZ_ENABLE_WAYLAND = "1";  # Firefox
      NIXOS_OZONE_WL = "1";       # Chromium/Electron
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      GDK_BACKEND = "wayland";
    };
    
    # Packages
    environment.systemPackages = with pkgs; [
      # Wayland utilities
      wl-clipboard       # Clipboard manager
      wlr-randr          # Display configuration
      wayland-utils      # Wayland info tools
      
      # Screenshot/recording
      grim               # Screenshot
      slurp              # Region selector
      wf-recorder        # Screen recorder
    ];
  };
}
```

#### 9.2 Hyprland Configuration
**File**: `home-modules/features/desktop/hyprland/default.nix`

```nix
{ config, lib, pkgs, c, ... }: {
  wayland.windowManager.hyprland = {
    enable = true;
    
    settings = {
      # Monitor configuration
      monitor = [
        "eDP-1,2256x1504@60,0x0,1.25"  # Framework 13 display with fractional scaling
      ];
      
      # Input
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
        };
        sensitivity = 0;  # -1.0 to 1.0
      };
      
      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        
        # Gruvbox colors
        "col.active_border" = "rgb(${c.base0D})";
        "col.inactive_border" = "rgb(${c.base03})";
        
        layout = "dwindle";
      };
      
      # Decoration
      decoration = {
        rounding = 8;
        
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };
      
      # Animations
      animations = {
        enabled = true;
        
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
      
      # Dwindle layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      
      # Window rules
      windowrule = [
        "float, ^(pavucontrol)$"
        "float, ^(thunar)$"
        "workspace 2, ^(firefox)$"
        "workspace 3, ^(Code)$"
      ];
    };
    
    # Keybindings (i3-style)
    extraConfig = ''
      $mod = SUPER
      
      # Basic bindings
      bind = $mod, Return, exec, alacritty
      bind = $mod SHIFT, Q, killactive
      bind = $mod SHIFT, E, exit
      bind = $mod, D, exec, rofi -show drun
      
      # Movement
      bind = $mod, H, movefocus, l
      bind = $mod, L, movefocus, r
      bind = $mod, K, movefocus, u
      bind = $mod, J, movefocus, d
      
      # Workspaces
      ${lib.concatMapStringsSep "\n" (i: ''
        bind = $mod, ${toString i}, workspace, ${toString i}
        bind = $mod SHIFT, ${toString i}, movetoworkspace, ${toString i}
      '') (lib.range 1 9)}
      
      # Resize mode
      bind = $mod, R, submap, resize
      submap = resize
      binde = , H, resizeactive, -10 0
      binde = , L, resizeactive, 10 0
      binde = , K, resizeactive, 0 -10
      binde = , J, resizeactive, 0 10
      bind = , escape, submap, reset
      submap = reset
    '';
  };
}
```

#### 9.3 Waybar Configuration
**File**: `home-modules/features/desktop/waybar/default.nix`

```nix
{ config, lib, pkgs, c, ... }: {
  programs.waybar = {
    enable = true;
    
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ 
          "pulseaudio" 
          "network" 
          "cpu" 
          "memory" 
          "battery" 
          "tray" 
        ];
        
        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
          };
        };
        
        clock = {
          format = "{:%H:%M %Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-icons = ["" "" "" "" ""];
        };
        
        network = {
          format-wifi = " {essid}";
          format-ethernet = " {ifname}";
          format-disconnected = "⚠ Disconnected";
        };
        
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " Muted";
          format-icons = {
            default = ["" "" ""];
          };
        };
      };
    };
    
    style = ''
      * {
        font-family: ${config.stylix.fonts.sansSerif.name};
        font-size: 13px;
      }
      
      window#waybar {
        background-color: #${c.base00};
        color: #${c.base05};
      }
      
      #workspaces button {
        background-color: #${c.base01};
        color: #${c.base05};
        padding: 0 10px;
      }
      
      #workspaces button.active {
        background-color: #${c.base0D};
        color: #${c.base00};
      }
      
      #battery.critical {
        color: #${c.base08};
      }
    '';
  };
}
```

#### 9.4 XWayland Support
**File**: `nixos-modules/desktop-wayland.nix` (add)

```nix
# Ensure legacy X11 apps work
environment.systemPackages = with pkgs; [
  xwayland
  xorg.xeyes  # Test X11 support
];

# XWayland environment
programs.xwayland = {
  enable = true;
};

# Electron apps (VS Code, etc.)
environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";  # Force Wayland mode
};
```

#### 9.5 Migration Checklist
**File**: `docs/wayland-migration.md`

```markdown
# Wayland Migration Checklist

## Pre-Migration
- [ ] Backup current i3 configuration
- [ ] Test Hyprland in nested session: `Hyprland`
- [ ] Verify all applications work under XWayland
- [ ] Document i3 keybindings to replicate

## Migration Steps
1. [ ] Install Hyprland: `desktop.wayland.enable = true;`
2. [ ] Configure keybindings (match i3)
3. [ ] Set up Waybar
4. [ ] Test screen sharing (Firefox, Discord)
5. [ ] Test all applications
6. [ ] Configure autostart apps

## Rollback Plan
- Keep i3 session available in GDM/LightDM
- Switch back if issues: select "i3" session at login

## Known Issues
- Screen sharing requires XDG desktop portal
- Some legacy apps may have window positioning bugs
- VPN clients might need X11 (test in XWayland)
```

### 📈 Success Metrics
- [ ] Hyprland session available as login option
- [ ] All daily applications work under Wayland/XWayland
- [ ] Keybindings replicate i3 workflow
- [ ] Screen sharing works in Firefox/Discord
- [ ] Battery life unchanged or improved
- [ ] Zero screen tearing

### 🎁 Benefits
- **Security**: Wayland isolates applications
- **Performance**: No tearing, lower latency
- **Modern Features**: Fractional scaling, VRR, HDR (future)
- **Future-Proof**: X11 is being phased out
- **Better Multi-Monitor**: Per-monitor configuration

### ⚠️ Risks & Mitigations
**Risk**: Applications break under Wayland  
**Mitigation**: Keep i3 session, use XWayland for legacy apps

**Risk**: Different keybindings/workflow  
**Mitigation**: Replicate i3 bindings exactly in Hyprland

**Risk**: Loss of productivity during transition  
**Mitigation**: Parallel installation, switch at convenient time

### 📚 Resources
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Waybar Configuration](https://github.com/Alexays/Waybar/wiki)
- [NixOS Wayland Guide](https://nixos.wiki/wiki/Wayland)
- [Misterio77 Hyprland Config](https://github.com/Misterio77/nix-config/tree/main/home/misterio/features/desktop/hyprland)

---

## Phase 10: Impermanence (ADVANCED)

### 🎯 Goal
Implement ephemeral root filesystem that resets on every boot, keeping only explicitly declared state.

### 📊 Current Gap
- Stateful root filesystem accumulates cruft over time
- Manual configuration changes persist (configuration drift)
- Harder to debug (unknown state)
- No guarantee of reproducibility

### 🔬 Research Findings

**Impermanence Benefits**:
- Fresh system on every boot
- Forces declarative configuration (can't rely on manual changes)
- Easier debugging (always clean slate)
- Better security (malware doesn't persist across reboots)
- Reproducibility guarantee

**Implementation Patterns**:
1. **tmpfs root**: RAM-based root filesystem (fast, truly ephemeral)
2. **BTRFS rollback**: Snapshot-based reset (slower, more storage)
3. **Hybrid**: tmpfs + persistent `/nix` and `/home`

**Community Examples**:
- **Misterio77/nix-config**: Full impermanence with tmpfs root
- **nix-community/impermanence**: Official module
- **Pattern**: Persist only `/nix`, `/home`, `/var/lib/systemd`, machine-id

### 📋 Implementation Plan

#### 10.1 Impermanence Module
**File**: `nixos-modules/impermanence.nix`

```nix
{ config, lib, pkgs, inputs, ... }: {
  imports = [ inputs.impermanence.nixosModules.impermanence ];
  
  options.system.impermanence.enable = lib.mkEnableOption "ephemeral root filesystem";
  
  config = lib.mkIf config.system.impermanence.enable {
    # Persistent storage location
    environment.persistence."/persist" = {
      hideMounts = true;
      
      directories = [
        # System state
        "/etc/nixos"              # Configuration (git repo)
        "/var/lib/systemd"        # Systemd state
        "/var/lib/sops-nix"       # Age keys (CRITICAL!)
        "/var/log"                # Logs
        
        # Network
        "/etc/NetworkManager/system-connections"
        
        # Containers/VMs
        "/var/lib/docker"
        "/var/lib/libvirt"
      ];
      
      files = [
        "/etc/machine-id"         # Unique machine identifier
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
      
      # User-specific persistence
      users.vino = {
        directories = [
          # Home directory essentials
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Videos"
          "Projects"
          ".ssh"
          ".gnupg"
          
          # Application data
          ".mozilla"              # Firefox
          ".config/Code"          # VS Code
          ".local/share/fish"     # Fish shell history
          ".local/share/atuin"    # Atuin shell history
          ".config/gh"            # GitHub CLI
          
          # Development
          ".cargo"
          ".npm"
          ".local/share/nvim"     # Neovim plugins/state
        ];
        
        files = [
          ".config/fish/fish_variables"
        ];
      };
    };
    
    # Bind mounts for convenience
    fileSystems."/home/vino/nixos-config" = {
      device = "/persist/etc/nixos";
      options = [ "bind" "noatime" ];
    };
  };
}
```

#### 10.2 Filesystem Layout
**File**: `nixos-configurations/bandit/hardware-configuration.nix` (modify)

**BTRFS Subvolume Structure**:
```
/dev/nvme0n1p2 (BTRFS)
├── @root → /           # tmpfs (ephemeral, not mounted from disk)
├── @nix → /nix         # Persistent (Nix store)
├── @persist → /persist # Persistent (state)
├── @home → /home       # Persistent (user data) OR mount home under /persist
└── @swap → /swap       # Swapfile
```

**Mount Configuration**:
```nix
{ config, lib, ... }: {
  # Root is tmpfs (ephemeral)
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "defaults" "size=4G" "mode=755" ];
  };
  
  # Nix store (persistent)
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/...";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd:3" "noatime" ];
  };
  
  # Persistent state
  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/...";
    fsType = "btrfs";
    options = [ "subvol=@persist" "compress=zstd:3" "noatime" ];
    neededForBoot = true;  # CRITICAL: Mount before activation
  };
  
  # Home directory
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/...";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd:3" "noatime" ];
  };
  
  # Swap
  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/...";
    fsType = "btrfs";
    options = [ "subvol=@swap" "noatime" ];
  };
  
  swapDevices = [{ device = "/swap/swapfile"; }];
}
```

#### 10.3 Migration Procedure
**File**: `docs/impermanence-migration.md`

```markdown
# Impermanence Migration Guide

## Prerequisites
- Full system backup (restic + BTRFS snapshot)
- Recovery USB with NixOS installer
- Age key backed up offline

## Migration Steps

### 1. Backup Current State
```bash
# BTRFS snapshot
sudo snapper -c root create --description "Pre-impermanence"
sudo snapper -c home create --description "Pre-impermanence"

# Restic backup
sudo systemctl start restic-backups-local.service

# Export current file list
sudo find / -type f > /tmp/current-files.txt
```

### 2. Identify State to Persist
```bash
# Review directories in /var/lib
ls -la /var/lib/

# Review user dotfiles
ls -la ~/.*

# Check for application data
ls -la ~/.config/
ls -la ~/.local/share/
```

### 3. Create Persist Subvolume
```bash
# Boot from NixOS installer
sudo mkdir /mnt
sudo mount /dev/nvme0n1p2 /mnt

# Create persist subvolume
sudo btrfs subvolume create /mnt/@persist

# Copy critical state
sudo cp -a /mnt/@/etc/nixos /mnt/@persist/etc/
sudo cp -a /mnt/@/var/lib/sops-nix /mnt/@persist/var/lib/
sudo cp -a /mnt/@/etc/machine-id /mnt/@persist/etc/
```

### 4. Update Configuration
```nix
# Enable impermanence
system.impermanence.enable = true;

# Update hardware-configuration.nix (see above)
```

### 5. Rebuild and Reboot
```bash
sudo nixos-rebuild boot --flake .#bandit
sudo reboot
```

### 6. Verify Impermanence
```bash
# Check root is tmpfs
df -h /
# Should show tmpfs, not btrfs

# Check persistent mounts
findmnt -t btrfs

# Reboot and verify state persisted
sudo reboot

# After reboot, check critical state
ls -la ~/.ssh/
ls -la /var/lib/sops-nix/
```

## Rollback Plan
1. Boot from recovery USB
2. Mount BTRFS root
3. Delete @root subvolume (if exists)
4. Restore from snapshot:
   ```bash
   sudo btrfs subvolume snapshot /mnt/.snapshots/X/snapshot /mnt/@root
   ```
5. Update fstab to mount @root instead of tmpfs
6. Rebuild system

## Troubleshooting
- If boot fails, add `boot.debug.enable = true` to config
- If secrets don't decrypt, check `/persist/var/lib/sops-nix/key.txt`
- If network doesn't work, persist NetworkManager connections
```

#### 10.4 Testing Impermanence
**File**: `tests/impermanence-test.sh`

```bash
#!/usr/bin/env bash
# Test impermanence is working

set -euo pipefail

echo "Testing impermanence..."

# Check root is tmpfs
ROOT_FS=$(findmnt -n -o FSTYPE /)
if [ "$ROOT_FS" != "tmpfs" ]; then
  echo "ERROR: Root is not tmpfs (found: $ROOT_FS)"
  exit 1
fi
echo "✓ Root is tmpfs"

# Create test file in root
TEST_FILE="/test-impermanence-$(date +%s).txt"
echo "test data" | sudo tee "$TEST_FILE" > /dev/null
echo "✓ Created test file: $TEST_FILE"

# Create test file in persist
PERSIST_FILE="/persist/test-persist-$(date +%s).txt"
echo "persist data" | sudo tee "$PERSIST_FILE" > /dev/null
echo "✓ Created persist file: $PERSIST_FILE"

echo ""
echo "⚠️  REBOOT NOW"
echo "After reboot, run: $0 verify"

if [ "${1:-}" == "verify" ]; then
  echo ""
  echo "Verifying post-reboot..."
  
  # Check test file in root (should be gone)
  if [ -f "$TEST_FILE" ]; then
    echo "ERROR: Root file persisted (impermanence not working)"
    exit 1
  fi
  echo "✓ Root file cleared (ephemeral working)"
  
  # Check persist file (should exist)
  if [ ! -f "$PERSIST_FILE" ]; then
    echo "ERROR: Persist file missing"
    exit 1
  fi
  echo "✓ Persist file survived reboot"
  
  echo ""
  echo "✓ Impermanence verified!"
fi
```

### 📈 Success Metrics
- [ ] Root filesystem is tmpfs
- [ ] System boots successfully
- [ ] Secrets decrypt (age key persisted)
- [ ] User data persists (/home)
- [ ] Network configuration persists
- [ ] Test file in root disappears after reboot
- [ ] No configuration drift (forced declarative)

### 🎁 Benefits
- **Clean Slate**: Fresh system every boot
- **Debugging**: No accumulated state
- **Security**: Malware doesn't persist
- **Discipline**: Forces declarative configuration
- **Reproducibility**: True configuration as code

### ⚠️ Risks & Mitigations
**Risk**: Age key not persisted → secrets fail to decrypt  
**Mitigation**: Persist `/var/lib/sops-nix/` BEFORE enabling impermanence

**Risk**: Critical state not persisted → system broken after reboot  
**Mitigation**: Thorough testing, incremental rollout, maintain rollback path

**Risk**: Loss of logs  
**Mitigation**: Persist `/var/log/` or ship to remote syslog

**Risk**: Forgot to persist something  
**Mitigation**: Keep snapshots for 30 days, test thoroughly before production

### 📚 Resources
- [Impermanence Module](https://github.com/nix-community/impermanence)
- [Misterio77 Impermanence Setup](https://github.com/Misterio77/nix-config/blob/main/hosts/common/optional/ephemeral-btrfs.nix)
- [NixOS Wiki: Impermanence](https://nixos.wiki/wiki/Impermanence)
- [Erase Your Darlings](https://grahamc.com/blog/erase-your-darlings) (Original concept)

---

## Phases 11-14: Additional Improvements (SUMMARY)

### Phase 11: Advanced Monitoring
- **Goal**: Production-grade monitoring with alerts
- **Components**: Loki (logs), Prometheus (metrics), Grafana (dashboards), Alertmanager
- **Alerts**: Disk space, service failures, backup status, security events
- **Remote Access**: Tailscale VPN + Nginx reverse proxy

### Phase 12: Performance Tuning
- **Goal**: Optimize for Framework 13 AMD
- **Areas**: Kernel parameters, I/O scheduler, filesystem tuning, power management
- **Tools**: perf, iotop, powertop, s-tui
- **Target**: 10+ hour battery life, <20s boot time

### Phase 13: Developer Experience
- **Goal**: World-class development environment
- **Features**: 
  - Language-specific devShells with LSP
  - Pre-commit hooks for all projects
  - Container-based development (devenv, devcontainer)
  - Remote development (VS Code SSH, Tailscale)
- **Tools**: direnv, nix-direnv, devenv, cachix for project caches

### Phase 14: Community Contribution
- **Goal**: Give back to NixOS community
- **Activities**:
  - Document Framework 13 AMD setup
  - Contribute modules upstream (backup, monitoring)
  - Write blog posts about NixOS journey
  - Participate in NixOS Discourse/Reddit

---

## Implementation Timeline

### Immediate (Weeks 1-2) - CRITICAL
1. **Phase 5: Testing Infrastructure**
   - Set up NixOS test framework
   - Write integration tests for critical paths
   - Add CI test runs

2. **Phase 6: Security Hardening** (in parallel)
   - Enable AppArmor
   - Configure USBGuard
   - Set up audit logging

### Short-term (Weeks 3-8) - HIGH PRIORITY
3. **Phase 7: Multi-Host Support**
   - Create host templates
   - Add second host (server or work laptop)
   - Test shared modules

4. **Phase 8: Backup Enhancements**
   - Add cloud backup (Backblaze B2)
   - Implement verification automation
   - Set up restore testing

### Medium-term (Months 3-4) - MEDIUM PRIORITY
5. **Phase 9: Desktop Modernization**
   - Install Hyprland in parallel with i3
   - Test Wayland compatibility
   - Migrate when comfortable

6. **Phase 10: Impermanence**
   - Research and plan thoroughly
   - Test in VM first
   - Implement with robust rollback plan

### Long-term (Months 5-6) - NICE TO HAVE
7. **Phases 11-14**: Advanced features as time permits

---

## Risk Assessment

### High Risk / High Impact
1. **Impermanence Migration**: Can break system if age key not persisted
   - **Mitigation**: Full backups, test in VM, incremental rollout

2. **Multi-Host Secrets**: Accidental secret exposure to wrong host
   - **Mitigation**: Per-host age keys, SOPS creation rules, CI validation

### Medium Risk / High Impact
3. **Wayland Migration**: Application compatibility issues
   - **Mitigation**: Keep i3 session, extensive testing, XWayland fallback

4. **Security Hardening**: AppArmor profiles breaking applications
   - **Mitigation**: Start with permissive mode, gradual enforcement, logs

### Low Risk / High Impact
5. **Testing Infrastructure**: CI costs, test maintenance
   - **Mitigation**: Use GitHub Actions free tier, focus on critical tests

---

## Success Metrics (Overall)

### Technical Metrics
- **Build Time**: <5 minutes (from cache)
- **Boot Time**: <20 seconds to desktop
- **Battery Life**: 10+ hours light use
- **Test Coverage**: 90%+ of critical modules
- **Security Score**: AppArmor + USBGuard + Audit enabled
- **Backup RTO**: <4 hours for full restore

### Operational Metrics
- **Config Changes**: Deploy with confidence (automated testing)
- **Disaster Recovery**: Tested monthly, <4 hour RTO
- **Multi-Host**: 3+ hosts managed from single repo
- **Developer Productivity**: <5 min to start new project (devShells)

### Documentation Metrics
- **Completeness**: All phases documented
- **Accessibility**: New user can understand system in <1 hour
- **Maintainability**: Any change has clear guide

---

## Priority Matrix

| Phase | Impact | Effort | Risk | Priority | Start |
|-------|--------|--------|------|----------|-------|
| **Phase 5: Testing** | High | Medium | Low | **P0** | Week 1 |
| **Phase 6: Security** | High | High | Medium | **P0** | Week 1 |
| **Phase 7: Multi-Host** | Medium | Medium | Low | **P1** | Week 3 |
| **Phase 8: Backups** | High | Medium | Low | **P1** | Week 5 |
| **Phase 9: Wayland** | Medium | High | Medium | **P2** | Month 3 |
| **Phase 10: Impermanence** | Medium | High | High | **P3** | Month 4 |
| **Phase 11: Monitoring** | Low | Medium | Low | **P4** | Month 5 |
| **Phase 12: Performance** | Low | Low | Low | **P5** | As needed |
| **Phase 13: DevEx** | Medium | Low | Low | **P4** | Ongoing |
| **Phase 14: Community** | Low | Low | Low | **P5** | Ongoing |

**Legend**:
- **P0**: Critical - Start immediately
- **P1**: High - Start within 2 weeks
- **P2**: Medium - Start within 1-2 months
- **P3**: Low - Start within 3-4 months
- **P4**: Nice to have - Ongoing
- **P5**: Future - When time permits

---

## Resources & Learning

### Essential Reading
1. [NixOS Manual](https://nixos.org/manual/nixos/stable/)
2. [Nix Pills](https://nixos.org/guides/nix-pills/)
3. [Home Manager Manual](https://nix-community.github.io/home-manager/)
4. [Zero to Nix](https://zero-to-nix.com/)

### Community Configs to Study
1. **Misterio77/nix-config** - Master class in NixOS patterns
2. **Mic92/dotfiles** - Production CI/CD and testing
3. **badele/nix-homelab** - Stylix and theming
4. **gpskwlkr/nixos** - Framework 13 AMD twin

### Tools & Utilities
1. **nix-tree** - Visualize dependency trees
2. **nix-diff** - Compare derivations
3. **manix** - Search Nix documentation
4. **nixpkgs-review** - Review nixpkgs PRs

### Community Support
1. [NixOS Discourse](https://discourse.nixos.org/)
2. [NixOS Reddit](https://reddit.com/r/NixOS)
3. [NixOS Matrix Chat](https://matrix.to/#/#community:nixos.org)
4. [NixOS Wiki](https://nixos.wiki/)

---

## Conclusion

This comprehensive plan provides a roadmap from your current production-ready state to a world-class NixOS configuration. The phased approach allows for:

1. **Risk Management**: Test thoroughly before production
2. **Incremental Progress**: Deliver value continuously
3. **Flexibility**: Adapt priorities based on needs
4. **Learning**: Deep understanding through implementation

**Recommended Next Steps**:
1. Review this plan thoroughly
2. Choose immediate priorities (suggest Phase 5 + 6)
3. Create tracking issues for each phase
4. Start with Phase 5 (testing) as foundation
5. Document learnings along the way

**Key Principles**:
- **Backup First**: Before any major change
- **Test in VM**: Before production deployment
- **Document Everything**: Future you will thank you
- **Community Patterns**: Learn from proven solutions
- **Incremental Changes**: Small, tested steps

Your NixOS configuration is already excellent. This plan takes it to the next level while maintaining stability and reproducibility.

---

**Last Updated**: February 1, 2025  
**Author**: AI Assistant + Community Research  
**Status**: Comprehensive Plan v1.0  
**Next Review**: After Phase 6 Completion
