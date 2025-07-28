# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This project includes a git submodule called Skarabaox (forked version), which is the core of the project. The rest of the directory contains various experiments with the Skarabaox framework and related tools.


## Skarabox Overview

Skarabox is a NixOS server installation framework that provides a streamlined way to install NixOS on servers with batteries-included security and automation features. It combines three main components:

1. **Beacon** - A bootable ISO for server installation that creates WiFi hotspots and assigns static IPs
2. **Flake Module** - Manages one or more servers under the `skarabox.hosts` option with automated commands and packages
3. **NixOS Module** - Provides headless installation via nixos-anywhere, ZFS encryption, remote root pool decryption, and deployment tools

## Essential Commands

### Development and Testing
- `nix flake show` - Display all available packages and checks
- `nix run .#init` - Initialize a new Skarabox template (interactive setup)
- `nix run .#checks.x86_64-linux.<test-name>` - Run specific tests (oneOSnoData, oneOStwoData, twoOSnoData, twoOStwoData, staticIP)
- `nix build .#checks.x86_64-linux.lib` - Build library tests

### Host Management (replace `<hostname>` with actual host name)
- `nix run .#<hostname>-beacon-vm` - Start beacon VM for testing
- `nix run .#<hostname>-install-on-beacon` - Install NixOS on target host
- `nix run .#<hostname>-ssh` - SSH into the host
- `nix run .#<hostname>-boot-ssh` - SSH into host during boot (for decryption)
- `nix run .#<hostname>-unlock` - Decrypt root partition remotely
- `nix run .#<hostname>-gen-knownhosts-file` - Generate known hosts file
- `nix run .#<hostname>-get-facter` - Generate hardware configuration

### Secret Management
- `nix run .#sops <secrets-file>` - Edit SOPS encrypted secrets file
- `nix run .#sops-create-main-key` - Create main SOPS encryption key
- `nix run .#gen-new-host <hostname>` - Generate new host configuration with secrets

### Deployment
- `nix run .#deploy-rs` - Deploy using deploy-rs
- `nix run .#colmena apply` - Deploy using colmena

## Architecture Overview

### Core Components

**Flake Structure**: The project uses flake-parts for modular flake management. The main flake exports:
- `flakeModules.default` - The core flake module for host management
- `nixosModules.skarabox` - NixOS modules for target hosts  
- `templates.skarabox` - Template for new projects

**Host Configuration**: Each host is managed under `skarabox.hosts.<name>` with configuration including:
- SSH keys and network settings (IP, ports)
- SOPS secrets file paths and encryption keys
- System architecture and NixOS modules
- Hardware configuration via nixos-facter

### Key Technologies

**ZFS with Encryption**: 
- Root pool uses native ZFS encryption with remote unlock capability
- Data pool encrypted separately, auto-unlocked after root pool decryption
- Implements "Erase your darlings" pattern - root filesystem reset on each boot

**SOPS Integration**:
- Secrets encrypted with age using main key + host SSH key
- One secrets file per host to avoid cross-host secret leakage
- Automated key generation and SOPS configuration management

**Networking**:
- Supports both DHCP and static IP configuration
- Boot-time SSH server in initrd for remote root pool decryption
- WiFi hotspot creation on beacon for network-independent access

### Module Structure

- `modules/configuration.nix` - Main host configuration (users, networking, SSH)
- `modules/disks.nix` - ZFS pool setup and encryption configuration  
- `modules/bootssh.nix` - Boot-time SSH for remote decryption
- `modules/beacon.nix` - Beacon ISO configuration
- `modules/hotspot.nix` - WiFi hotspot setup for beacon
- `lib/` - Utility scripts for initialization, host generation, SOPS management
- `tests/` - Comprehensive test suite for different disk configurations

### Testing Strategy

The test suite validates complete installation workflows:
- Different disk layouts (1-2 OS disks, 0-2 data disks)
- Full beacon VM → installation → reboot → deployment cycle
- Both deploy-rs and colmena deployment methods
- Static IP configuration testing

Tests run in CI using KVM-enabled GitHub runners and test the complete end-to-end installation process including beacon creation, nixos-anywhere installation, ZFS encryption/decryption, and deployment.

## Cross-Platform Compatibility

### macOS Issues and Solutions

**Problem**: Host-specific commands (e.g., `nix run .#<hostname>-gen-knownhosts-file`, `nix run .#<hostname>-get-facter`) fail on macOS with error:
```
Cannot build '/nix/store/...-nixpkgs-patched.drv'. Reason: required system or feature not available
```

**Root Cause**: The `mkHostPackages` function in `flakeModule.nix` was using target system packages (x86_64-linux) for host-side commands on macOS (aarch64-darwin).

**Fix Applied**: Modified `flakeModule.nix` to use host system packages (`hostPkgs`) instead of target packages (`cfg'.pkgs`) for local command execution:
```nix
mkHostPackages = hostPkgs: name: cfg': let
  # Commands now use hostPkgs (host system) instead of cfg'.pkgs (target system)
```

### Manual Alternatives for Cross-Platform Compatibility

When automated commands fail, use these manual alternatives:

#### Generate Known Hosts File
```bash
# Manual method (universal)
echo "[$(cat ./myskarabox/ip)]:22 $(cat ./myskarabox/host_key.pub | cut -d' ' -f1-2)" > ./myskarabox/known_hosts
echo "[$(cat ./myskarabox/ip)]:2222 $(cat ./myskarabox/host_key.pub | cut -d' ' -f1-2)" >> ./myskarabox/known_hosts
```

#### Hardware Detection
```bash
# Manual SSH method (universal)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=./myskarabox/known_hosts -p 22 root@$(cat ./myskarabox/ip) sudo nixos-facter > ./myskarabox/facter.json
```

**Note**: `nixos-facter` is pre-installed in Skarabox beacon but not in Hetzner recovery mode. For recovery mode, install Nix and nixos-facter first.

## SSH Key Architecture

**Host Keys vs Client Keys**:
- **Host Keys** (`myskarabox/host_key.pub`): Authenticate the server to prevent man-in-the-middle attacks
- **Client Keys** (`myskarabox/ssh.pub`): Authenticate the user to the server for login

Host keys are generated during setup and used in known_hosts files to verify server identity during SSH connections.

## Troubleshooting

### Common Error Patterns

1. **Cross-platform build failures**: Use manual commands or run on Linux system
2. **nixos-facter not found**: Ensure server is running Skarabox beacon, not recovery mode
3. **SSH connection timeouts**: Verify server is accessible and SSH keys are correct
4. **Missing host-specific commands**: Commands only exist after configuring hosts in flake