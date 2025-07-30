# Fix Cross-Platform Compatibility for gen-knownhosts-file

## Problem Analysis
The `myskarabox-gen-knownhosts-file` command fails on macOS because:
1. The current `mkHostPackages` function uses the same `pkgs` for both host-side and target-side commands
2. The `gen-knownhosts-file` lib function uses `${pkgs.coreutils}/bin/cut` which references Linux packages when running on macOS
3. The CLAUDE.md mentions this fix was applied but the current code doesn't reflect it

## Root Cause
- **Current signature**: `mkHostPackages = name: cfg':`
- **Should be**: `mkHostPackages = hostPkgs: name: cfg':`
- Commands that run on the host (like gen-knownhosts-file) need host system packages
- Commands that run on target servers can use target system packages

## Proposed Fix

### 1. Update mkHostPackages Function Signature
Change `mkHostPackages = name: cfg': let` to `mkHostPackages = hostPkgs: name: cfg': let`

### 2. Update Function Call Site
Change `(concatMapAttrs mkHostPackages cfg.hosts)` to `(concatMapAttrs (mkHostPackages pkgs) cfg.hosts)`

### 3. Fix gen-knownhosts-file Package
Update the `gen-knownhosts-file` definition to use `hostPkgs` instead of `pkgs` for host-side tools:
- `runtimeInputs` should reference a version of the lib that uses `hostPkgs`
- The lib function itself should be passed `hostPkgs` for `coreutils`

### 4. Update Other Host-Side Commands
Commands that run on the host (ssh, get-facter, unlock, etc.) should use `hostPkgs` instead of `pkgs`

### 5. Keep Target-Side Commands Using cfg'.pkgs
Commands that generate target system artifacts (like beacon ISO, install-on-beacon) should continue using target system packages

## Expected Outcome
- `nix run .#myskarabox-gen-knownhosts-file` will work on macOS
- No need for the explicit system specification workaround
- Manual bash alternatives will no longer be necessary
- Cross-platform compatibility for all host-side commands

## Files to Modify
- `skarabox/flakeModule.nix` (main changes)
- `skarabox/lib/gen-knownhosts-file.nix` (update to use hostPkgs)
- `skarabox/lib/ssh.nix` (update to use hostPkgs)
- Other lib files that should use host packages

## Testing
After implementation, test on macOS:
- `nix run .#myskarabox-gen-knownhosts-file`
- `nix run .#myskarabox-ssh`
- `nix run .#myskarabox-get-facter`
- Verify they work without explicit system specification