Quickstart Guide for NixOS Anywhere Setup: https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md

- Copy `flake.nix` example: https://github.com/nix-community/nixos-anywhere-examples/blob/main/flake.nix

- Copy `configuration.nix` example: https://github.com/nix-community/nixos-anywhere-examples/blob/main/configuration.nix
  - Add SSH key

- Copy `disk-config.nix` example: https://github.com/nix-community/nixos-anywhere-examples/blob/main/disk-config.nix


- Run the following command to initialize the NixOS Anywhere setup:
```bash
nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --flake .#generic --target-host root@91.99.176.80
```