# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Nix configuration repository for macOS using Nix Darwin and Home Manager. It manages system-wide packages, user-specific configurations, and development environments through declarative configuration files.

## Key Files and Structure
- `nm-nix-config/flake.nix`: Main Nix flake configuration defining Darwin system, Home Manager, and development shells
- `nm-nix-config/flake.lock`: Lock file for reproducible builds
- `README.md`: Comprehensive setup and usage documentation (refer to this for installation and package details)

## Common Commands

### System Management
```bash
# Rebuild and switch to new Darwin configuration
darwin-rebuild switch --flake ~/.config/nix

# Show available flake outputs
nix flake show ~/.config/nix

# Update flake lock file
nix flake update ~/.config/nix
```

### Development Environments
```bash
# Enter default development shell
nix develop --flake ~/.config/nix

# Enter specific development environments
nix develop ~/.config/nix#pythonEnv
nix develop ~/.config/nix#nodeEnv
nix develop ~/.config/nix#tempEnv

# Debug development shell
nix develop -v ~/.config/nix#nodeEnv
nix develop ~/.config/nix#nodeEnv --command bash --noprofile --norc
```

### Installation and Setup
Refer to README.md for detailed installation instructions including Nix setup, corporate environment configuration, and troubleshooting.

## Architecture

### Configuration Structure
- **System Configuration**: Managed through `darwinConfigurations.nikhilmaddirala-mbp` in flake.nix
- **User Configuration**: Managed through Home Manager integration
- **Package Management**: Multi-layered approach using Nix packages, Homebrew, and Mac App Store
- **Development Shells**: Custom environments defined in `devShells` for different programming languages

### Package Categories
Refer to README.md for complete package categorization and list (nix-home, nix-darwin, brew, brew-cask, MAS).

### Corporate Environment Setup
Uses standard Nix installation with corporate compatibility layer. See README.md for full setup details.

## Development Shells
Three predefined development environments:
- `pythonEnv`: Python development with uv package manager
- `nodeEnv`: Node.js development with yarn
- `tempEnv`: Temporary shell with curl/wget utilities

Each shell includes custom `shellHook` scripts that run on activation.