# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The m3tam3re-collection is a personal NixOS configuration collection focused on self-hosted services and infrastructure. It contains configurations for multiple hosts running various containerized applications and services, managed through NixOS flakes.

## Repository Architecture

### Core Structure
- **nixos-config/**: Main NixOS flake configuration
- **hosts/**: Host-specific configurations organized by hostname (m3-ares, m3-atlas, m3-helios, m3-kratos)
- **pkgs/**: Custom package definitions and derivations
- **secrets/**: Age-encrypted secrets managed by agenix
- **home/**: Home Manager configurations for user environments
- **modules/**: Custom NixOS and Home Manager modules
- **overlays/**: Nixpkgs overlays for package modifications

### Host Architecture
Each host follows a consistent structure:
- `default.nix`: Main host configuration entry point
- `configuration.nix`: System-level configuration
- `hardware-configuration.nix`: Hardware-specific settings
- `disko-config.nix`: Disk partitioning (where applicable)
- `services/`: Service-specific configurations
- `secrets.nix`: Age-encrypted secrets configuration

### Service Organization
Services are organized into two categories:
- **Native NixOS services**: Direct NixOS service configurations (gitea, postgres, traefik, etc.)
- **Container services**: Podman-based containerized applications in `containers/` subdirectories

## Essential Commands

### Flake Operations
```bash
# Navigate to nixos-config directory first
cd nixos-config/

# Show available configurations and packages
nix flake show

# Build specific host configuration
nix build .#nixosConfigurations.m3-atlas.config.system.build.toplevel

# Build custom packages
nix build .#packages.x86_64-linux.msty
nix build .#packages.x86_64-linux.zellij-ps
nix build .#packages.x86_64-linux.code2prompt

# Build Proxmox image for m3-hermes
nix build .#packages.x86_64-linux.proxmox-hermes-image
```

### Development Environment
```bash
# Enter infrastructure management shell
nix develop .#infraShell
```

### Host Management
```bash
# Rebuild host configuration (run on target host)
sudo nixos-rebuild switch --flake .#<hostname>

# Test configuration without switching
sudo nixos-rebuild test --flake .#<hostname>

# Build configuration remotely
nixos-rebuild switch --flake .#<hostname> --target-host <hostname>
```

### Secret Management
Secrets are managed using agenix with age encryption:
```bash
# Edit secrets (requires age key)
agenix -e secrets/<secret-file>.age

# Rekey all secrets after key changes
agenix -r
```

## Key Technologies

### Service Stack
- **Traefik**: Reverse proxy and load balancer with automatic HTTPS
- **PostgreSQL/MySQL**: Database backends for various applications
- **Podman**: Container runtime for containerized services
- **Tailscale/Headscale**: VPN networking between hosts
- **MinIO**: S3-compatible object storage
- **Various self-hosted apps**: Gitea, Vaultwarden, Paperless, N8N, etc.

### Infrastructure Components
- **Disko**: Declarative disk partitioning
- **Home Manager**: User environment management
- **Agenix**: Secret management with age encryption
- **Multiple Nixpkgs channels**: Stable, unstable, and pinned versions for different packages

### Custom Packages
The repository includes several custom packages:
- **msty**: Custom application
- **zellij-ps**: Process monitoring for Zellij terminal multiplexer
- **code2prompt**: Code extraction utility
- **pomodoro-timer**: Productivity timer
- **aider-chat-env**: AI coding assistant environment

## Host Configurations

### m3-atlas (Primary Services Host)
Runs the majority of self-hosted services including:
- Web applications (Ghost, Baserow, Outline)
- Development tools (Gitea, N8N, Kestra)
- Analytics and monitoring (Matomo)
- Media services (Restreamer)

### m3-helios (Network Services)
Focused on network infrastructure:
- AdGuard DNS filtering
- Traefik reverse proxy
- Dashboard services (Homarr)

### m3-ares & m3-kratos (Development/Testing)
Lighter configurations for development and testing purposes with basic services like N8N and PostgreSQL.

## Development Workflow

### Adding New Services
1. Create service configuration in appropriate `hosts/<hostname>/services/` directory
2. Add import to `services/default.nix`
3. Configure secrets in `secrets.nix` if needed
4. Test configuration with `nixos-rebuild test`
5. Apply with `nixos-rebuild switch`

### Managing Containers
Container services use Podman with a shared `web` network (10.89.0.0/24) for internal communication. Services are configured with:
- Environment files for secrets
- Volume mounts for persistent data
- Network configuration for Traefik integration

### Secret Management Workflow
1. Generate age keys for new hosts
2. Add public keys to `.agenix.nix`
3. Create encrypted secret files in `secrets/`
4. Reference secrets in host configurations
5. Rekey when adding new hosts or rotating keys