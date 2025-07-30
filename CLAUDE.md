# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dragon-server is a collection-based repository for experimenting with NixOS server deployment frameworks. It contains multiple approaches for setting up NixOS servers on cloud VPS platforms, organized into distinct collections that can be used independently or together.

## Repository Architecture

The repository is structured as a **collection-based architecture** with four main collections:

### 1. Skarabox Collection (`skarabox-collection/`)
- **Core Framework**: Git submodule of forked Skarabox - a NixOS server installation framework
- **Key Features**: Bootable beacon ISOs, ZFS encryption, remote unlock, deployment automation
- **Configuration**: `my-skarabox/` contains generated configuration and state
- **Primary Use**: Headless NixOS installation with batteries-included security

### 2. NixOS Anywhere Collection (`nixos-anywhere-collection/`)  
- **Core Framework**: Git submodule of nixos-anywhere project
- **Key Features**: Remote NixOS installation, disk partitioning, configuration deployment
- **Configuration**: `my-nixos-anywhere/` contains installation configuration
- **Primary Use**: Direct remote installation without custom ISOs

### 3. Self-host Blocks Collection (`selfhostblocks-collection/`)
- **Core Framework**: Git submodule of selfhostblocks - modular NixOS service blocks
- **Key Features**: Pre-configured service modules (Nextcloud, Vaultwarden, monitoring, etc.)
- **Configuration**: `my-selfhostblocks/` for service configurations  
- **Primary Use**: Composable self-hosted services with built-in best practices

### 4. NM Nix Collection (`nm-nix-collection/`)
- **Personal Configurations**: Nikhil's Nix configurations and experiments
- **Submodules**: `nix-config/` (Nix Darwin), `dragon-test-project/`, `selfhostblocks-test/`
- **Primary Use**: Development environments and configuration templates

## Essential Commands

### Skarabox Commands (Primary Framework)
Navigate to `skarabox-collection/skarabox/` for all Skarabox operations:

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
nix run /Users/nikhilmaddirala/repos/dragon-server/skarabox-collection/skarabox#init -- -p /Users/nikhilmaddirala/repos/dragon-server/skarabox-collection/skarabox

# Manual alternatives for cross-platform compatibility
echo "[$(cat ./myskarabox/ip)]:22 $(cat ./myskarabox/host_key.pub | cut -d' ' -f1-2)" > ./myskarabox/known_hosts
ssh -o StrictHostKeyChecking=no -p 22 root@$(cat ./myskarabox/ip) sudo nixos-facter > ./myskarabox/facter.json
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
1. Navigate to appropriate collection directory
2. Run initialization command for chosen framework
3. Configure host-specific settings (IP, SSH keys, modules)
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

## Tasks and Documentation

The `tasks/` directory contains detailed implementation notes and solutions:
- Cross-platform compatibility fixes
- SSH configuration and troubleshooting
- Known issues and their resolutions
- Implementation journey documentation

Each task file provides comprehensive analysis, root cause identification, and step-by-step solutions for complex technical challenges encountered during development.