# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dragon-server is a collection-based repository for experimenting with NixOS server deployment frameworks. It contains multiple approaches for setting up NixOS servers on cloud VPS platforms, organized into distinct collections that can be used independently or together.

## Repository Architecture

The repository is now structured with a clean, organized layout:

```
dragon-server/
├── nix-config/                    # Primary working Nix configuration (main development focus)
├── references/                    # All reference submodules with namespace prefixes
│   ├── @nikhilmaddirala-skarabox/           # Skarabox NixOS installation framework
│   ├── @nix-community-nixos-anywhere/       # nixos-anywhere remote installation
│   ├── @ibizaman-selfhostblocks/            # Self-hosted service blocks
│   ├── @nikhilmaddirala-selfhostblocks-test/ # Selfhostblocks experiments
│   ├── @nikhilmaddirala-dragon-test-project/ # Test project configurations
│   ├── @m3tam3re-nixos-config/              # m3tam3re's NixOS configurations
│   ├── @Misterio77-nix-starter-configs/     # Community starter configs
│   └── @mitchellh-nixos-config/             # Mitchell Hashimoto's configs
├── docs/                          # All documentation files
├── scratchpad/                    # Working/experiment directories
└── README.md                      # Main project documentation
```

### Primary Components

**Main Configuration (`nix-config/`)**:
- Primary development focus - Nikhil's Nix Darwin and NixOS configurations
- Located at root for easy access and development

**Reference Frameworks (`references/`)**:
- **Skarabox** (`@nikhilmaddirala-skarabox/`): NixOS server installation with ZFS encryption, beacon ISOs, remote unlock
- **nixos-anywhere** (`@nix-community-nixos-anywhere/`): Remote NixOS installation without custom ISOs  
- **Self-host Blocks** (`@ibizaman-selfhostblocks/`): Modular NixOS service blocks (Nextcloud, Vaultwarden, etc.)
- **Community Configs**: Various starter templates and example configurations

**Working Areas (`scratchpad/`)**:
- `my-skarabox/`: Skarabox instance configurations and state
- `my-nixos-anywhere/`: nixos-anywhere installation configurations  
- `my-selfhostblocks/`: Self-hosted service configurations

## Essential Commands

### Skarabox Commands (Primary Framework)
Navigate to `references/@nikhilmaddirala-skarabox/` for all Skarabox operations:

```bash
# Initialize new Skarabox instance
nix run .#init

# Host management (replace <hostname> with actual host)
nix run .#<hostname>-beacon-vm        # Start beacon VM for testing
nix run .#<hostname>-install-on-beacon # Install NixOS on target host
nix run .#<hostname>-ssh              # SSH into the host
nix run .#<hostname>-boot-ssh         # SSH during boot (for decryption)
nix run .#<hostname>-unlock           # Decrypt root partition remotely
nix run .#<hostname>-gen-knownhosts-file # Generate known hosts file
nix run .#<hostname>-get-facter       # Generate hardware configuration

# Secret management
nix run .#sops <secrets-file>         # Edit SOPS encrypted secrets
nix run .#sops-create-main-key       # Create main SOPS encryption key
nix run .#gen-new-host <hostname>    # Generate new host with secrets

# Deployment
nix run .#deploy-rs                  # Deploy using deploy-rs
nix run .#colmena apply              # Deploy using colmena

# Development and testing
nix flake show                       # Display available packages/checks
nix run .#checks.x86_64-linux.<test> # Run specific tests
```

### Cross-Platform Development

When working on macOS with Skarabox, be aware of cross-platform limitations:

```bash
# For local development commands that should work on both macOS and Linux
nix run /Users/nikhilmaddirala/repos/dragon-server/references/@nikhilmaddirala-skarabox#init -- -p /Users/nikhilmaddirala/repos/dragon-server/references/@nikhilmaddirala-skarabox

# Manual alternatives for cross-platform compatibility (run from scratchpad/my-skarabox/)
echo "[$(cat ./ip)]:22 $(cat ./host_key.pub | cut -d' ' -f1-2)" > ./known_hosts
ssh -o StrictHostKeyChecking=no -p 22 root@$(cat ./ip) sudo nixos-facter > ./facter.json
```

## Key Technologies and Architecture

### Skarabox Technical Stack
- **ZFS Encryption**: Native ZFS encryption with remote unlock capability
- **SOPS Secrets**: Age-based encryption with per-host key isolation  
- **Beacon System**: Custom bootable ISOs with WiFi hotspots for network-independent access
- **Deployment Tools**: Both deploy-rs and colmena supported
- **Testing Framework**: Comprehensive VM-based testing with multiple disk configurations

### Module Architecture
- **Flake Structure**: Uses flake-parts for modular flake management
- **Host Configuration**: Managed under `skarabox.hosts.<name>` options
- **NixOS Modules**: Separate modules for disks, SSH, beacon, hotspot functionality
- **Library Scripts**: Utility functions for initialization, host generation, SOPS management

### Cross-Platform Considerations
The repository includes known issues and solutions for macOS development:
- Host-specific commands may fail due to system architecture mismatches
- Manual alternatives provided for commands that require Linux-specific tools
- SSH key architecture distinguishes between host keys (server authentication) and client keys (user authentication)

## Development Workflow

### Setting Up a New Host
1. Navigate to appropriate reference directory (`references/@nikhilmaddirala-skarabox/`, etc.)
2. Run initialization command for chosen framework
3. Configure host-specific settings (IP, SSH keys, modules) in `scratchpad/my-<framework>/`
4. Generate secrets and hardware configuration
5. Test with beacon VM before production deployment
6. Deploy using chosen deployment tool

### Testing and Validation
- Use VM-based testing for safe experimentation
- Comprehensive test suite covers different disk layouts and deployment methods
- Manual SSH verification for connectivity testing
- Cross-platform testing on both macOS and Linux

### Troubleshooting Common Issues
- **Cross-platform build failures**: Use manual commands or Linux system
- **SSH connection issues**: Verify keys, known_hosts, and network accessibility  
- **Missing commands**: Ensure hosts are configured in flake before accessing host-specific commands
- **SOPS decryption**: Verify key paths and age key availability

## Documentation

The `docs/` directory contains comprehensive documentation:
- `skarabox.md`: Detailed Skarabox framework documentation and commands
- `m3tam3re.md`: m3tam3re's configuration documentation
- `selfhostblocks-collection-readme.md`: Self-host blocks collection overview
- `skarabox-fix-cross-platform-gen-knownhosts-file.md`: Cross-platform compatibility fixes
- `skarabox-nix-darwin-linux-builder-ssh-fix.md`: SSH configuration troubleshooting

Each documentation file provides comprehensive analysis, implementation details, and step-by-step solutions for complex technical challenges encountered during development.