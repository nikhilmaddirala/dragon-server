# Self Host Blocks Setup Guide

Self Host Blocks is a NixOS-based server management framework for self-hosting using building blocks and promoting best practices. This guide shows how to initialize configurations from the selfhostblocks framework and deploy to servers.

## Quick Setup Guide

**Main Documentation**: https://shb.skarabox.com/  
**Services Documentation**: https://shb.skarabox.com/services.html  
**Usage Manual**: https://shb.skarabox.com/usage.html

## Overview

Self Host Blocks provides:
- **Pre-configured Services**: Nextcloud, Vaultwarden, Jellyfin, Home Assistant, Forgejo, and more
- **Unified Configuration**: Consistent interface for LDAP, SSO, SSL, monitoring, and backups
- **Building Blocks**: Reusable components (Authelia, PostgreSQL, Nginx, monitoring stack)
- **Deployment Tools**: Support for Colmena, deploy-rs, and nixos-rebuild
- **Security**: Built-in SOPS secrets management and SSL automation

## Initialization Steps

### 1. Set up your project directory

Navigate to the `my-selfhostblocks/` directory (create it if it doesn't exist):

```bash
cd selfhostblocks-collection/
mkdir -p my-selfhostblocks
cd my-selfhostblocks
```

### 2. Copy example configuration files

Choose a service example from the demos to start with. For Nextcloud:

```bash
# Copy basic configuration files
cp ../selfhostblocks/demo/nextcloud/flake.nix ./
cp ../selfhostblocks/demo/nextcloud/configuration.nix ./
cp ../selfhostblocks/demo/nextcloud/hardware-configuration.nix ./

# Copy secrets and SSH setup
cp ../selfhostblocks/demo/nextcloud/secrets.yaml ./
cp ../selfhostblocks/demo/nextcloud/sops.yaml ./
cp ../selfhostblocks/demo/nextcloud/keys.txt ./
cp ../selfhostblocks/demo/nextcloud/ssh_config ./
```

### 3. Generate SSH keys for deployment

```bash
# Generate SSH key pair for deployment
ssh-keygen -t ed25519 -f sshkey -N ""

# Set proper permissions
chmod 600 sshkey
chmod 644 sshkey.pub
```

### 4. Generate hardware configuration (for real servers)

For deployment to actual servers, generate hardware configuration:

```bash
# SSH into your target server and run:
nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

## Configuration

### Basic Service Setup

Edit `flake.nix` to configure your services. Here's a basic Nextcloud example:

```nix
{
  description = "My Self Host Blocks Server";

  inputs = {
    selfhostblocks.url = "github:ibizaman/selfhostblocks";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs@{ self, selfhostblocks, sops-nix }: {
    nixosConfigurations.myserver = selfhostblocks.lib.x86_64-linux.patchedNixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix
        selfhostblocks.nixosModules.x86_64-linux.default
        sops-nix.nixosModules.default
        {
          # Basic Nextcloud setup
          shb.nextcloud = {
            enable = true;
            domain = "yourdomain.com";
            subdomain = "nextcloud";
            adminPass.result = config.shb.sops.secret."nextcloud/adminpass".result;
          };

          # SSL configuration
          shb.certs.certs.letsencrypt.yourdomain = {
            domain = "*.yourdomain.com";
            group = "nginx";
            adminEmail = "admin@yourdomain.com";
          };

          # SOPS secrets
          sops.defaultSopsFile = ./secrets.yaml;
          shb.sops.secret."nextcloud/adminpass".request = config.shb.nextcloud.adminPass.request;
        }
      ];
    };
  };
}
```

### Adding More Services

You can easily add more services to the same configuration:

```nix
# Add Vaultwarden
shb.vaultwarden = {
  enable = true;
  domain = "yourdomain.com";
  subdomain = "vault";
  ssl = config.shb.certs.certs.letsencrypt.yourdomain;
};

# Add LDAP integration
shb.lldap = {
  enable = true;
  domain = "yourdomain.com";
  subdomain = "ldap";
  ssl = config.shb.certs.certs.letsencrypt.yourdomain;
  ldapUserPassword.result = config.shb.sops.secret."lldap/user_password".result;
  jwtSecret.result = config.shb.sops.secret."lldap/jwt_secret".result;
};

# Add SSO with Authelia
shb.authelia = {
  enable = true;
  domain = "yourdomain.com";
  subdomain = "auth";
  ssl = config.shb.certs.certs.letsencrypt.yourdomain;
  # ... additional Authelia configuration
};
```

## Secrets Management

### 1. Generate SOPS key

```bash
# Generate age key for secrets encryption
nix run nixpkgs#age-keygen > sops.key

# Update sops.yaml with your public key
SOPS_AGE_KEY_FILE=sops.key nix run nixpkgs#sops -- --config sops.yaml secrets.yaml
```

### 2. Edit secrets

```bash
# Edit encrypted secrets file
SOPS_AGE_KEY_FILE=sops.key nix run nixpkgs#sops -- --config sops.yaml secrets.yaml
```

### 3. Generate random secrets

```bash
# Generate secure random passwords
nix run nixpkgs#openssl -- rand -hex 32
```

## Deployment

### Method 1: VM Testing (Development)

For local testing with a VM:

```bash
# Build and start VM for testing
nixos-rebuild build-vm --flake .#myserver
QEMU_NET_OPTS="hostfwd=tcp::2222-:2222,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443" ./result/bin/run-nixos-vm

# Test access
# Add to /etc/hosts: 127.0.0.1 yourdomain.com nextcloud.yourdomain.com
# Visit: http://nextcloud.yourdomain.com:8080
```

### Method 2: Remote Deployment with Colmena

For production deployment to remote servers:

#### 1. Set up Colmena configuration

Add to your `flake.nix`:

```nix
outputs = inputs@{ self, selfhostblocks, sops-nix }: {
  # ... nixosConfigurations above

  colmena = {
    meta = {
      nixpkgs = import selfhostblocks.lib.x86_64-linux.patchedNixpkgs {
        system = "x86_64-linux";
      };
      specialArgs = inputs;
    };

    myserver = {
      imports = [ ./configuration.nix ./hardware-configuration.nix /* other modules */ ];
      
      deployment = {
        targetHost = "192.168.1.100";  # Your server IP
        targetUser = "nixos";
        targetPort = 22;
        sshOptions = [ "-i" "./sshkey" ];
      };
    };
  };
};
```

#### 2. Deploy to server

```bash
# Add server's SSH key to secrets (for remote servers)
SOPS_AGE_KEY_FILE=sops.key nix run nixpkgs#sops -- --config sops.yaml -r -i \
  --add-age $(ssh-keyscan -t ed25519 your-server-ip 2>/dev/null | nix run nixpkgs#ssh-to-age --) \
  secrets.yaml

# Deploy with Colmena
nix run nixpkgs#colmena -- apply --on myserver
```

### Method 3: Deploy-rs

If you prefer deploy-rs, add this to your `flake.nix`:

```nix
deploy.nodes.myserver = {
  hostname = "192.168.1.100";
  sshUser = "nixos";
  sshOpts = [ "-i" "./sshkey" ];
  profiles.system = {
    user = "root";
    path = selfhostblocks.lib.x86_64-linux.patchedNixpkgs.lib.deploy-rs.lib.activate.nixos 
      self.nixosConfigurations.myserver;
  };
};
```

Then deploy:

```bash
nix run nixpkgs#deploy-rs -- .#myserver
```

## Available Services

Self Host Blocks provides the following services:

- **Nextcloud**: File sharing and collaboration platform
- **Vaultwarden**: Password manager (Bitwarden-compatible)
- **Jellyfin**: Media server for movies, TV shows, music
- **Home Assistant**: Home automation platform
- **Forgejo**: Git forge (Gitea fork)
- **Audiobookshelf**: Audiobook and podcast server
- **Deluge + *arr**: Torrent client with Sonarr, Radarr, etc.
- **Grocy**: Grocery and household management
- **Hledger**: Plain-text accounting system

## Building Blocks

Common blocks available for custom configurations:

- **SSL/TLS**: Automatic certificate management with Let's Encrypt
- **LDAP**: User directory with LLDAP
- **SSO**: Single sign-on with Authelia
- **Monitoring**: Grafana + Prometheus + Loki stack
- **Backup**: Automated backups with BorgBackup or Restic
- **Database**: PostgreSQL with automatic database creation
- **Reverse Proxy**: Nginx with automatic virtual host configuration
- **VPN**: WireGuard integration for secure access

## Troubleshooting

### Common Issues

1. **Secrets not decrypted**: Ensure server's age key is added to `secrets.yaml`
2. **SSL certificate errors**: Check domain DNS and Let's Encrypt rate limits
3. **Service startup failures**: Check `journalctl -u <service-name>` for errors
4. **Permission issues**: Verify file ownership and directory permissions

### Debug Commands

```bash
# Check service status
systemctl status nextcloud-setup

# View service logs
journalctl -f -u nextcloud-phpfpm

# Test SSL certificates
nix run nixpkgs#openssl -- s_client -connect yourdomain.com:443

# Check secrets
ls -la /run/secrets/
```

## Next Steps

1. **Read the manual**: Visit https://shb.skarabox.com/ for detailed service configuration
2. **Join the community**: Matrix channel at https://matrix.to/#/#selfhostblocks:matrix.org
3. **Customize**: Add your own services and modify existing configurations
4. **Monitor**: Set up the monitoring stack for observability
5. **Backup**: Configure automated backups for data protection

For more advanced configurations and service-specific options, refer to the [complete documentation](https://shb.skarabox.com/services.html).