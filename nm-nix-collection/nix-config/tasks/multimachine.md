# Plan: Add Multi-Machine Support to Single Flake

## Overview
Extend your current single-file flake.nix to support both your MacBook Pro (Darwin) and a Linux Ubuntu VPS while maintaining the simple, single-file approach.

## Changes Required

### 1. Update Flake Description
- Change from "Darwin configuration" to "Multi-machine configuration"

### 2. Add NixOS Support to Inputs
- No new inputs needed (nixpkgs already supports Linux)
- Current inputs (nixpkgs, darwin, home-manager) are sufficient

### 3. Add System Variables
- Define both `darwinSystem` and `linuxSystem` variables
- Update the `let` block to handle multiple systems

### 4. Add nixosConfigurations Section
- Create `nixosConfigurations.ubuntu-vps` for your Linux VPS
- Configure base Linux system packages
- Set up home-manager for Linux user

### 5. Extend devShells
- Add `x86_64-linux` development shells
- Mirror existing Darwin dev environments for Linux

### 6. Create Shared Configuration
- Extract common packages/settings that both machines should have
- Define machine-specific differences (GUI apps only on macOS, server tools on Linux)

## Structure
```
outputs = {
  darwinConfigurations = {
    nikhilmaddirala-mbp = ... (existing)
  };
  
  nixosConfigurations = {
    ubuntu-vps = ... (new)
  };
  
  devShells = {
    aarch64-darwin = ... (existing)
    x86_64-linux = ... (new)
  };
}
```

## Benefits
- Single flake manages both machines
- Shared configuration reduces duplication
- Easy to deploy to either machine
- Consistent development environments

This approach keeps your simple single-file structure while adding multi-machine support.