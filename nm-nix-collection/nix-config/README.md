# Introduction

This is a guide to set up Nix on macOS with Nix Darwin and Home Manager. Use cases:

- Use Nix Darwin to manage your macOS system configuration.
- Use Home Manager to manage user-specific configurations and packages.
- Multiple development environments with Nix Flake
- Customized config for nikhilmaddirala as well as reference configurations from other users.


# Installation

## Install Nix
- Recommended: Corporate-friendly installation (if you have access to internal tools)

```bash
# 1. Install Nix using determinate installer (but remember to not use the determinate flag - we use the installer to install vanilla Nix)
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# Alternate: Install Nix using standard installer
# sh <(curl -L https://nixos.org/nix/install)


# 2. Configure Chef compatibility (CRITICAL - prevents /nix from disappearing after reboot)
sudo feature install nix_prerequisites
# This takes 30+ minutes but ensures /nix persists after Chef runs

# 3. Add Nix binaries to PATH in ~/.zshrc (maybe not needed if you use Home Manager)
echo 'export PATH="/run/current-system/sw/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="/etc/profiles/per-user/$USER/bin:$PATH"' >> ~/.zshrc

# 4. Create symlinks for reliable access (works around corporate PATH restrictions)
ls /nix/var/nix/profiles/default/bin/ | xargs -I '{}' sudo ln -sf /nix/var/nix/profiles/default/bin/'{}' /usr/local/bin/'{}'
```

- Verify one of the flakes flake:
```bash
nix flake show ~/.config/nix/nm-nix-config
```

## Install Nix Darwin and set up a flake

- Follow the instructions here: https://github.com/nix-darwin/nix-darwin
```bash
# NM Nix Config
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#nikhilmaddirala-mbp
```


# Usage with nm-nix-config

- run nix darwin to rebuild the system:

```bash
sudo darwin-rebuild switch --flake ~/repos/nix-config#nikhilmaddirala-mbp

# May need to load the nix shell
exec /run/current-system/sw/bin/bash -l
```

- load custom dev shell:
```bash
nix develop ~/.config/nix#nodeEnv

# Debug
nix develop -v ~/.config/nix#nodeEnv
nix develop ~/.config/nix#nodeEnv --command bash --noprofile --norc
```

- create dev shell for development:
```bash
nix develop --flake ~/.config/nix
```

# Troubleshooting

### Nix doesn't start after reboot
- Restart the daemon:
```bash
sudo launchctl stop org.nixos.nix-daemon
sudo launchctl start org.nixos.nix-daemon
```

### Fixing corporate issues
- Run this command to fix issues with synthetic conf (note this is different from the initial setup command): `sudo feature install nix_synthetic_conf`

### Uninstalling Nix
- Uninstall nix - determinate nix - May need sudo
```bash
/nix/nix-installer uninstall
```

- vanilla nix uninstall: https://nix.dev/manual/nix/2.18/installation/uninstall



# Packages

Categories of packages:

- User packages (home manager)
- System packages (nix darwin)
- Brew packages (homebrew)
- Brew cask packages (homebrew-cask)
- Mac app store apps (mas)


| Package            | Category   | Notes     |
| -------------------- | ------------ | ----------- |
| 1password-cli      | nix-home   |           |
| ansible            | nix-home   |           |
| borders            | nix-home   |           |
| chezmoi            | nix-home   |           |
| ffmpeg             | nix-home   |           |
| gemini-cli         | nix-home   | npm global via Home Manager |
| gh                 | nix-home   |           |
| ncdu               | nix-home   |           |
| nodejs             | nix-home   |           |
| python3            | nix-home   |           |
| rclone             | nix-home   |           |
| tree               | nix-home   |           |
| docker             | nix-darwin |           |
| mas                | brew       |           |
| aerospace          | brew-cask  |           |
| blackhole-2ch      | brew-cask  |           |
| docker-desktop     | brew-cask  |           |
| handbrake          | brew-cask  |           |
| hammerspoon        | brew-cask  |           |
| iterm2             | brew-cask  |           |
| karabiner-elements | brew-cask  |           |
| notunes            | brew-cask  |           |
| obsidian           | brew-cask  |           |
| visual-studio-code | brew-cask  |           |
| finicky            | brew-cask  |           |
| Logic Pro          | MAS        |           |
| Final Cut Pro      | MAS        |           |


# Macos settings
- Auto hide dock
- Tap to click
- 


# TODOs
- Integration with chezmoi for dotfiles management
- More packages: lazy-vim

# Setup after nix
 - Edge: sign-in to sync bookmarks, history, and passwords. Need to re-download chrome extensions.
- 1Password: sign-in to sync passwords and other data.
- Google Drive: sign-in to sync file. 

## Appendix ## Test the example: dustinlyons/nixos-config

- Load reference flake configurations:
```bash
git clone https://github.com/dustinlyons/nixos-config.git
git clone https://github.com/AlexNabokikh/nix-config.git

# local dir
nm-nix-config
```

The dustinlyons config uses templates and apps (not direct configurations). To test:

```bash
# Install dependencies
xcode-select --install

# Initialize a starter template in a test directory
mkdir -p /tmp/nixos-config-test && cd /tmp/nixos-config-test && nix flake init -t ~/.config/nix/examples/nixos-config#starter

# Make apps executable
find apps/$(uname -m | sed 's/arm64/aarch64/')-darwin -type f \( -name apply -o -name build -o -name build-switch -o -name create-keys -o -name copy-keys -o -name check-keys -o -name rollback \) -exec chmod +x {} \;

# Apply user info and test build
nix run .#apply
nix run .#build

# Test the system configuration and Home Manager auto-activation
sudo nix run .#build-switch

# Check if Home Manager activated properly
ls -la ~/.bashrc ~/.bash_profile ~/.profile
grep "starship init" ~/.bashrc

# If Home Manager files exist and starship is configured, the issue is with your flake
# If not, the issue is with your nix installation
```

**Note**: The dustinlyons config generates system configurations dynamically using `genAttrs darwinSystems` which creates `aarch64-darwin` and `x86_64-darwin` configurations, not named configurations like `starter`.
