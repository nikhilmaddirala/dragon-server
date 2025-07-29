# Fixing nix-darwin linux-builder SSH Connection Issues

## Problem Summary

When using nix-darwin's `linux-builder` feature on macOS with corporate SSH configuration, Nix's remote builder fails with:

```
cannot build on 'ssh-ng://builder@linux-builder': error: failed to start SSH connection to 'builder@linux-builder'
```

## Root Causes

1. **Corporate SSH Config**: Chef-managed `/etc/ssh/ssh_config` doesn't include `ssh_config.d` directory, so nix-darwin's automatic SSH configuration in `/etc/ssh/ssh_config.d/100-linux-builder.conf` is ignored.

2. **Hostname Resolution**: The hostname `linux-builder` cannot be resolved by DNS.

3. **SSH Key Permissions**: The linux-builder SSH key `/etc/nix/builder_ed25519` has restricted permissions that prevent user access.

4. **Nix SSH Client**: Nix's `ssh-ng://` protocol uses its own SSH client that doesn't read user SSH configuration.

## Failed Solutions Attempted

1. **User SSH Config**: Added linux-builder config to `~/.ssh/config` - works for `ssh` command but not for Nix's `ssh-ng://` protocol.

2. **System SSH Config via nix-darwin**: Using `programs.ssh` module fails because corporate SSH config overrides it.

3. **SSH Key Copying**: Copying key to user directory works for manual SSH but not for Nix builds.

4. **Group Membership**: Adding user to `nixbld` group has complications with existing build users.

## Attempted Solution That Failed

Tried to configure SSH options directly in the linux-builder configuration:

```nix
nix.linux-builder = {
  enable = true;
  systems = [ "aarch64-linux" "x86_64-linux" ];
  config = {
    sshOptions = [  # ❌ This option doesn't exist
      "-p" "31022"
      "-l" "builder"
      "-i" "/etc/nix/builder_ed25519"
      "-o" "HostName=localhost"
      "-o" "StrictHostKeyChecking=no"
      "-o" "UserKnownHostsFile=/dev/null"
    ];
  };
};
```

**Error**: `The option 'sshOptions' does not exist`

## Key Learnings

1. **nix-darwin SSH Integration**: The `programs.ssh` module in nix-darwin can be overridden by corporate SSH management.

2. **Nix Remote Builder SSH**: Nix's remote builder uses its own SSH client that bypasses user SSH configuration.

3. **Limited Configuration Options**: The nix-darwin linux-builder module doesn't expose SSH configuration options like `sshOptions`.

4. **Corporate Environment Challenges**: Chef/corporate management blocks standard nix-darwin SSH configuration mechanisms.

5. **Configuration Inflexibility**: No apparent way to customize SSH behavior for the linux-builder within nix-darwin.

## Status: POTENTIAL SOLUTIONS IDENTIFIED

The issue remains unresolved, but several promising approaches have been identified based on nix-darwin documentation and community solutions.

## Recommended Solutions

### 1. Switch to SSH Protocol (Highest Success Rate)

**Problem**: `ssh-ng://` protocol bypasses user SSH configuration entirely
**Solution**: Configure linux-builder to use system SSH client instead of Nix's builtin

```nix
nix.linux-builder = {
  enable = true;  
  protocol = "ssh";  # Use system SSH client instead of ssh-ng
  systems = [ "aarch64-linux" "x86_64-linux" ];
};
```

**Why it works**: Makes Nix use your system SSH client which reads `~/.ssh/config`
**Prerequisites**: Requires existing user SSH config with linux-builder host definition

### 2. Hostname Resolution via /etc/hosts (Simple & Direct)

**Problem**: `linux-builder` hostname cannot be resolved by DNS
**Solution**: Add direct hostname mapping

```bash
sudo sh -c 'echo "127.0.0.1 linux-builder" >> /etc/hosts'
```

**Why it works**: Direct hostname resolution bypass; `/etc/hosts` typically not Chef-managed
**Combines well with**: Solution #1 for complete SSH + hostname resolution

### 3. Custom Remote Builder Configuration (Full Control)

**Problem**: nix-darwin's linux-builder module lacks configuration flexibility  
**Solution**: Replace with manual remote builder configuration

```nix
nix.buildMachines = [{
  hostName = "localhost";
  systems = [ "aarch64-linux" "x86_64-linux" ];
  maxJobs = 1;
  sshUser = "builder";
  sshKey = "/etc/nix/builder_ed25519";
  protocol = "ssh";  # or "ssh-ng"
  supportedFeatures = [ "benchmark" "big-parallel" "kvm" ];
}];
# Disable the automatic linux-builder
nix.linux-builder.enable = false;
```

**Why it works**: Bypasses nix-darwin module limitations entirely
**Trade-off**: Requires manual VM management (or use existing nix-darwin VM)

### 4. Embedded Host Key for ssh-ng (Pure Declarative)

**Problem**: Host key verification fails with ssh-ng protocol
**Solution**: Embed host key directly in configuration

```bash
# First, extract the public key
ssh-keyscan -p 31022 localhost | awk '/ssh-ed25519/ {print $2}' > builder_key.pub
```

```nix
nix.linux-builder = {
  enable = true;
  publicHostKey = builtins.readFile ./builder_key.pub;
  systems = [ "aarch64-linux" "x86_64-linux" ];
};
```

**Why it works**: Embeds host key directly, no external SSH config files needed
**Benefits**: Completely declarative, works with ssh-ng protocol

### 5. Disable SSH Config Generation (Prevent Conflicts)

**Problem**: nix-darwin tries to write to Chef-protected `/etc/ssh/` paths
**Solution**: Disable automatic SSH configuration generation

```nix
environment.etc."ssh/ssh_config.d/100-linux-builder.conf".enable = false;
```

**Why it works**: Prevents any Chef conflicts by stopping nix-darwin SSH config writes
**Combines with**: Other solutions that provide alternative SSH configuration

## Implementation Strategy

**Phase 1**: Try solutions #1 + #2 (highest success probability)
**Phase 2**: Add solution #5 if Chef conflicts occur  
**Phase 3**: Fallback to solution #3 if nix-darwin module proves insufficient
**Phase 4**: Add solution #4 for completely declarative setup

## Testing Command

After implementing solutions, test with:

```bash
darwin-rebuild switch
nix build --expr '(with import <nixpkgs> { system="x86_64-linux"; }; runCommand "test" {} "uname -a > $out")'
cat result  # Should show Linux output
```