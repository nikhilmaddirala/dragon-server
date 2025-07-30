# Self Host Blocks Setup Guide

Self Host Blocks is a NixOS-based server management framework that provides building blocks for self-hosting services with built-in security, monitoring, and automation.

**Documentation**: https://shb.skarabox.com/ | **Services**: https://shb.skarabox.com/services.html | **Usage**: https://shb.skarabox.com/usage.html

## Quick Start (TL;DR)

**For experienced users who want to get started quickly:**

```bash
# 1. Set up project
cd selfhostblocks-collection/ && mkdir -p my-selfhostblocks && cd my-selfhostblocks

# 2. Copy templates
cp ../selfhostblocks/demo/nextcloud/{flake.nix,configuration.nix,secrets.yaml,sops.yaml} ./

# 3. Install NixOS (skip if already have NixOS)
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  --flake .#install --target-host root@YOUR-SERVER-IP

# 4. Set up secrets
nix run nixpkgs#age-keygen > sops.key
# Edit secrets.yaml and add your domain/passwords

# 5. Deploy services
nixos-rebuild switch --flake .#myserver --target-host root@YOUR-SERVER-IP
```

**Details for each step below ↓**

---

## Step-by-Step Guide

### Step 1: Prerequisites & Setup

#### System Requirements
- **Development machine**: Any system with Nix installed
- **Target server**: VPS, bare metal, or cloud instance with SSH access
- **Minimum server specs**: 2GB RAM, 20GB storage
- **Domain name**: For SSL certificates and proper service access

#### Install Required Tools

If you don't have Nix installed:
```bash
# Install Nix (multi-user installation)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Enable flakes
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

#### Set Up Project Directory

```bash
cd selfhostblocks-collection/
mkdir -p my-selfhostblocks
cd my-selfhostblocks
```

### Step 2: Choose Your Path

Choose based on your server's current state:

**Path A: Fresh Server** (Ubuntu, Debian, other Linux, or bare metal)
- Requires installing NixOS first using nixos-anywhere
- Follow the complete workflow below

**Path B: Existing NixOS System**
- Skip to [Step 4: Configuration](#step-4-configuration)
- Assumes you already have NixOS running with SSH access

### Step 3: Server Provisioning (Path A Only)

**Skip this step if you already have NixOS installed (Path B)**

#### 3.1: Copy Base Templates

```bash
# Copy configuration templates
cp ../selfhostblocks/demo/nextcloud/flake.nix ./
cp ../selfhostblocks/demo/nextcloud/configuration.nix ./
cp ../selfhostblocks/demo/nextcloud/secrets.yaml ./
cp ../selfhostblocks/demo/nextcloud/sops.yaml ./
```

#### 3.2: Create Installation Files

**Create `disk-config.nix`** (adjust `/dev/sda` for your server):

```nix
{ lib, ... }: {
  disko.devices = {
    disk.main = {
      device = lib.mkDefault "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            name = "ESP";
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "system";
            };
          };
        };
      };
    };
    lvm_vg.system = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = "50G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        data = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/var/lib";
          };
        };
      };
    };
  };
}
```

#### 3.3: Update Flake for Installation

**Edit `flake.nix`** to add installation configuration:

```nix
{
  description = "Self Host Blocks Server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    selfhostblocks.url = "github:ibizaman/selfhostblocks";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs@{ self, nixpkgs, disko, selfhostblocks, sops-nix }: {
    nixosConfigurations = {
      # Basic NixOS installation
      install = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./configuration.nix
          ./disk-config.nix
          ./hardware-configuration.nix
        ];
      };

      # Full Self Host Blocks server
      myserver = selfhostblocks.lib.x86_64-linux.patchedNixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./configuration.nix
          ./disk-config.nix
          ./hardware-configuration.nix
          selfhostblocks.nixosModules.x86_64-linux.default
          sops-nix.nixosModules.default
          {
            # Services will be configured in Step 4
            sops.defaultSopsFile = ./secrets.yaml;
          }
        ];
      };
    };
  };
}
```

#### 3.4: Update Configuration

**Edit `configuration.nix`** - replace the SSH key with yours:

```nix
{ modulesPath, lib, pkgs, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk-config.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh.enable = true;
  
  environment.systemPackages = with pkgs; [ curl git htop vim ];

  # REPLACE WITH YOUR SSH PUBLIC KEY
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-public-key-here"
  ];

  networking.hostName = "myserver";
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  system.stateVersion = "24.05";
}
```

#### 3.5: Install NixOS

```bash
# Install NixOS on your server
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  --flake .#install \
  --target-host root@YOUR-SERVER-IP
```

**Note**: The server will reboot during installation. SSH host keys will change.

### Step 4: Configuration

#### 4.1: Configure Services

**Edit your `flake.nix`** to add Self Host Blocks services to the `myserver` configuration:

```nix
# Inside the myserver configuration modules list, add:
{
  # Nextcloud file sharing
  shb.nextcloud = {
    enable = true;
    domain = "example.com";  # CHANGE TO YOUR DOMAIN
    subdomain = "nextcloud";
    adminPass.result = config.shb.sops.secret."nextcloud/adminpass".result;
  };

  # SSL certificates
  shb.certs.certs.letsencrypt.example = {  # CHANGE TO YOUR DOMAIN
    domain = "*.example.com";
    group = "nginx";
    adminEmail = "admin@example.com";  # CHANGE TO YOUR EMAIL
  };

  # Connect SSL to Nextcloud
  shb.nextcloud.ssl = config.shb.certs.certs.letsencrypt.example;

  # SOPS secrets configuration
  sops.defaultSopsFile = ./secrets.yaml;
  shb.sops.secret."nextcloud/adminpass".request = config.shb.nextcloud.adminPass.request;
}
```

#### 4.2: Add More Services (Optional)

You can add multiple services to the same server:

```nix
# Password manager
shb.vaultwarden = {
  enable = true;
  domain = "example.com";
  subdomain = "vault";
  ssl = config.shb.certs.certs.letsencrypt.example;
};

# LDAP user directory
shb.lldap = {
  enable = true;
  domain = "example.com";
  subdomain = "ldap";
  ssl = config.shb.certs.certs.letsencrypt.example;
  ldapUserPassword.result = config.shb.sops.secret."lldap/password".result;
  jwtSecret.result = config.shb.sops.secret."lldap/jwt".result;
};

# Remember to add corresponding secrets to Step 5
```

### Step 5: Secrets Management

#### 5.1: Generate Encryption Key

```bash
# Generate age key for encrypting secrets
nix run nixpkgs#age-keygen > sops.key
```

#### 5.2: Configure SOPS

**Edit `sops.yaml`** to use your key:

```yaml
keys:
  - &admin_key your-age-public-key-here  # Get from sops.key file
creation_rules:
  - path_regex: secrets.yaml$
    key_groups:
    - age:
      - *admin_key
```

#### 5.3: Create Secrets

**Edit secrets (encrypted file)**:

```bash
SOPS_AGE_KEY_FILE=sops.key nix run nixpkgs#sops -- --config sops.yaml secrets.yaml
```

**Add your secrets** (adjust for your services):

```yaml
nextcloud:
  adminpass: your-secure-admin-password-here

# If using LLDAP
lldap:
  password: your-ldap-admin-password
  jwt: your-jwt-secret-here

# Generate random secrets with:
# nix run nixpkgs#openssl -- rand -hex 32
```

#### 5.4: Add Server Key (For Remote Deployment)

```bash
# Add your server's SSH key to secrets for remote deployment
SOPS_AGE_KEY_FILE=sops.key nix run nixpkgs#sops -- --config sops.yaml -r -i \
  --add-age $(ssh-keyscan -t ed25519 YOUR-SERVER-IP 2>/dev/null | nix run nixpkgs#ssh-to-age --) \
  secrets.yaml
```

### Step 6: Deployment

#### 6.1: Test Configuration (Recommended)

Test your configuration locally first:

```bash
# Build and test in VM
nixos-rebuild build-vm --flake .#myserver

# Start VM with port forwarding
QEMU_NET_OPTS="hostfwd=tcp::2222-:2222,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443" ./result/bin/run-nixos-vm

# Add to /etc/hosts for testing:
# 127.0.0.1 example.com nextcloud.example.com vault.example.com

# Visit: http://nextcloud.example.com:8080
```

#### 6.2: Deploy to Production

**For existing NixOS systems (Path B) or after Step 3 installation:**

```bash
# Deploy your services
nixos-rebuild switch --flake .#myserver --target-host root@YOUR-SERVER-IP
```

**Alternative: Colmena deployment** (for advanced users):

Add to `flake.nix`:
```nix
colmena = {
  meta = {
    nixpkgs = import selfhostblocks.lib.x86_64-linux.patchedNixpkgs {
      system = "x86_64-linux";
    };
  };
  myserver = {
    imports = [ ./configuration.nix ./hardware-configuration.nix /* your modules */ ];
    deployment = {
      targetHost = "YOUR-SERVER-IP";
      targetUser = "root";
    };
  };
};
```

Deploy:
```bash
nix run nixpkgs#colmena -- apply --on myserver
```

#### 6.3: Verify Deployment

1. **Check services**: `ssh root@YOUR-SERVER-IP systemctl status nextcloud-phpfpm`
2. **Test access**: Visit `https://nextcloud.example.com` (replace with your domain)
3. **Check logs**: `ssh root@YOUR-SERVER-IP journalctl -f -u nextcloud-phpfpm`

### Step 7: DNS & Access

#### 7.1: Configure DNS

Point your domain to your server:
```
A    example.com           → YOUR-SERVER-IP  
A    nextcloud.example.com → YOUR-SERVER-IP
A    vault.example.com     → YOUR-SERVER-IP
```

#### 7.2: Access Your Services

- **Nextcloud**: https://nextcloud.example.com
- **Vaultwarden**: https://vault.example.com (if configured)
- **Admin login**: Use the password from your secrets.yaml

---

## Reference

### Available Services

Self Host Blocks provides these services:

- **Nextcloud**: File sharing, calendar, contacts
- **Vaultwarden**: Bitwarden-compatible password manager  
- **Jellyfin**: Media server for movies and music
- **Home Assistant**: Home automation platform
- **Forgejo**: Git repository hosting
- **Audiobookshelf**: Audiobook and podcast server
- **Deluge + *arr**: Torrent client with automation
- **Grocy**: Grocery and household management

### Building Blocks

These components work together across services:

- **SSL/TLS**: Automatic Let's Encrypt certificates
- **LDAP**: User directory with LLDAP
- **SSO**: Single sign-on with Authelia
- **Monitoring**: Grafana + Prometheus + Loki
- **Backup**: Automated backups with BorgBackup/Restic
- **Database**: PostgreSQL with automatic management
- **Reverse Proxy**: Nginx with automatic configuration

### Common Configurations

#### LDAP Integration

```nix
# Add LDAP to any service
shb.nextcloud.apps.ldap = {
  enable = true;
  host = "127.0.0.1";
  port = config.shb.lldap.ldapPort;
  dcdomain = config.shb.lldap.dcdomain;
  adminPassword.result = config.shb.sops.secret."lldap/password".result;
};
```

#### SSO with Authelia

```nix
# Add SSO to any service  
shb.nextcloud.apps.sso = {
  enable = true;
  endpoint = "https://auth.example.com";
  secret.result = config.shb.sops.secret."nextcloud/sso_secret".result;
};
```

#### Monitoring

```nix
# Enable monitoring stack
shb.monitoring = {
  enable = true;
  domain = "example.com";
  subdomain = "monitoring";
  ssl = config.shb.certs.certs.letsencrypt.example;
};
```

### Troubleshooting

#### Common Issues

1. **Service won't start**: Check `journalctl -u service-name`
2. **SSL certificate errors**: Verify DNS and domain configuration
3. **Secrets not decrypted**: Ensure server's age key is in secrets.yaml
4. **Permission errors**: Check file ownership and SELinux/AppArmor

#### Debug Commands

```bash
# Check service status
systemctl status nextcloud-phpfpm

# View recent logs
journalctl -f -u nextcloud-phpfpm

# Test SSL
openssl s_client -connect example.com:443

# Check secrets
ls -la /run/secrets/

# Test network connectivity
curl -I https://nextcloud.example.com
```

#### Getting Help

- **Documentation**: https://shb.skarabox.com/
- **Matrix Chat**: https://matrix.to/#/#selfhostblocks:matrix.org
- **Issues**: https://github.com/ibizaman/selfhostblocks/issues

### Next Steps

1. **Explore services**: Try different services from the catalog
2. **Set up monitoring**: Add the monitoring stack for observability  
3. **Configure backups**: Set up automated data protection
4. **Add users**: Configure LDAP for multi-user access
5. **Enable SSO**: Set up Authelia for unified authentication

For advanced configurations and service-specific options, see the [complete documentation](https://shb.skarabox.com/services.html).