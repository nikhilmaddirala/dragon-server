{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ nixpkgs, home-manager, darwin, ... }: let
    system = "aarch64-darwin";
    pkgs   = import nixpkgs { inherit system; };
  in {
    darwinConfigurations = {
      nikhilmaddirala-mbp = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          # Nix-Homebrew module
          inputs.nix-homebrew.darwinModules.nix-homebrew
          ({ pkgs, ... }: {

            ###############################################################################
            # System Configuration
            ###############################################################################

            nixpkgs.config.allowUnfree = true;

            environment.systemPackages = with pkgs; [
              podman
              qemu
            ];

            # nix.enable = false; # Required for determinate nix
            nixpkgs.hostPlatform = "aarch64-darwin";
            nix.settings.experimental-features = "nix-command flakes";
            nix.settings.trusted-users = [ "root" "nikhilmaddirala" "@admin" ];
            # Keep VM management but prevent duplicate builder registrations
            nix.linux-builder = {
              enable = true;
              protocol = "ssh";  # Use system SSH client instead of ssh-ng
              systems = [
                "aarch64-linux"   # the VM's native arch (default)
                "x86_64-linux"    # now also support Intel‑Linux builds
              ];
            };
            
            nix.settings.use-xdg-base-directories = true;
            system.primaryUser = "nikhilmaddirala";
            system.stateVersion = 4;
            ids = {
              gids.nixbld = 350;
            };

            # Fix linux-builder SSH key permissions and /etc/nix/machines configuration
            system.activationScripts.nixBuilderFix.text = ''
              # Copy SSH key to user-accessible location with proper permissions
              if [ -f /etc/nix/builder_ed25519 ]; then
                cp /etc/nix/builder_ed25519 /Users/nikhilmaddirala/.ssh/linux-builder_ed25519
                chown nikhilmaddirala:staff /Users/nikhilmaddirala/.ssh/linux-builder_ed25519
                chmod 600 /Users/nikhilmaddirala/.ssh/linux-builder_ed25519
              fi
              
              # Wait briefly for system to finish writing files, then override /etc/nix/machines
              # This ensures we override AFTER nix-darwin writes its configuration
              sleep 2
              
              # Override /etc/nix/machines to use user-accessible SSH key
              echo "ssh://builder@localhost aarch64-linux,x86_64-linux /Users/nikhilmaddirala/.ssh/linux-builder_ed25519 1 1 benchmark,big-parallel,kvm - -" > /etc/nix/machines
              chmod 644 /etc/nix/machines
            '';

            # Enable Touch ID for sudo
            security.pam.services.sudo_local.touchIdAuth = true;

            # Configure shell PATH order
            # programs.zsh.enable = true;
            programs.bash.enable = true;

            # Add Nix-managed bash to /etc/shells
            environment.shells = [ pkgs.bash ];

            # Silence bash deprecation warning
            environment.variables.BASH_SILENCE_DEPRECATION_WARNING = "1";

            users.users.nikhilmaddirala = {
              name = "nikhilmaddirala";
              home = "/Users/nikhilmaddirala";
              shell = pkgs.bash;
            };


            ###############################################################################
            # macOS System Defaults Configuration
            ###############################################################################

            system.defaults = {
              # Screen capture settings
              screencapture = {
                location = "~/Desktop";
                type = "png";
                disable-shadow = true;
              };

              # Finder settings
              finder = {
                NewWindowTarget = "Recents";
                AppleShowAllFiles = true;
                AppleShowAllExtensions = true;
                ShowStatusBar = true;
                _FXShowPosixPathInTitle = true;
                FXDefaultSearchScope = "SCcf";
                FXEnableExtensionChangeWarning = false;
                FXPreferredViewStyle = "Nlsv";
                ShowPathbar = true;
              };

              # Trackpad settings
              trackpad = {
                Clicking = true;
                FirstClickThreshold = 0;
                ActuationStrength = 0;
              };

              # Dock settings
              dock = { 
                autohide = true;
                showhidden = true;
                tilesize = 64;
              };

              # Activity Monitor settings
              ActivityMonitor = {
                OpenMainWindow = true;
                ShowCategory = 100;  # All Processes
              };

              # Keyboard settings
              NSGlobalDomain = {
                # Press-and-hold for accent characters; false = enable key repeat
                ApplePressAndHoldEnabled = false;
                # Set key repeat rate (lower = faster)
                KeyRepeat = 2;
                # Set initial delay before key repeat starts
                InitialKeyRepeat = 15;
              };
            };

              # Keyboard settings
              system.keyboard = {
                enableKeyMapping = true;
                remapCapsLockToEscape = true;
              };

            ###############################################################################
            # Package Management (Homebrew & Mac App Store)
            ###############################################################################

            # Configure nix-homebrew
            nix-homebrew = {
              enable = true;
              enableRosetta = true;  # For Apple Silicon Macs
              user = "nikhilmaddirala";
              autoMigrate = true;
            };

            homebrew.enable = true;
            homebrew.onActivation.autoUpdate = true;
            homebrew.onActivation.upgrade = true;
            homebrew.onActivation.cleanup = "zap";

            # Custom homebrew taps
            homebrew.taps = [
              "FelixKratz/formulae"
              "nikitabobko/tap"
            ];

            # List of formulae to install with `brew install`
            homebrew.brews = [
              "mas"
              "FelixKratz/formulae/borders"
              "FelixKratz/formulae/sketchybar"
            ];

            # List of GUI apps to install with `brew install --cask`
            homebrew.casks = [
              "nikitabobko/tap/aerospace"
              "blackhole-2ch"
              "finicky"
              "hammerspoon"
              "iterm2"
              "karabiner-elements"
              "notunes"
              "obsidian"
              "visual-studio-code"
              "ghostty"
              "microsoft-edge"
              "raycast"
              "1password"
              "1password-cli"
              "displaylink"
              "contexts"
              "google-drive"
              "todoist-app"
              # "docker"
              "monitorcontrol"
            ];

            # Mac App Store apps
            homebrew.masApps = {
              "Logic Pro" = 634148309;
              "Final Cut Pro" = 424389933;
            };

          })

          # Home Manager module
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs  = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.nikhilmaddirala = { config, pkgs, lib, ... }:
            let
              globalNpmPackages = [
                "@google/gemini-cli"
                "@anthropic-ai/claude-code"
                "ccusage"
                "opencode-ai"
              ];
            in {

              home.stateVersion = "23.05";
              home.homeDirectory = "/Users/nikhilmaddirala";
              home.username = "nikhilmaddirala";
              home.packages = with pkgs; [
                ansible
                chezmoi
                ffmpeg
                gh
                helix
                ncdu
                nodejs
                python3
                rclone
                tree
                htop
                home-manager
                sshs
                uv
                podman-compose
                todoist
                hcloud
                nh
                devenv
                lazygit
              ];

              # npm global package management
              home.file.".npmrc".text = ''
                prefix = ${config.home.homeDirectory}/.npm-global
              '';

              # Set PATH with nix-managed paths first to override system binaries
              home.sessionVariables = {
                NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
                PATH = "$HOME/.npm-global/bin:$HOME/.local/state/nix/profiles/home-manager/home-path/bin:/etc/profiles/per-user/nikhilmaddirala/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH";
                SSH_AUTH_SOCK = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
              };

              # Run `npm install -g` for each entry in that list, with proper env setup:
              home.activation.installGlobalNpmPackages =
                lib.hm.dag.entryAfter [ "writeBoundary" ] (
                  lib.concatStringsSep "
" (
                    [
                      ''PREFIX="${config.home.homeDirectory}/.npm-global"''
                      ''mkdir -p "$PREFIX"''
                      ''export NPM_CONFIG_PREFIX="$PREFIX"''
                      ''export PATH="$PREFIX/bin:${pkgs.nodejs}/bin:$PATH"''
                    ]
                    ++ map (pkg: ''${pkgs.nodejs}/bin/npm install -g ${pkg}'') globalNpmPackages
                  )
                );

              # Configure bash
              programs.bash = {
                enable = true;
                initExtra = ''
                  # Source Home Manager session variables from the actual location
                  if [ -f "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh" ]; then
                    source "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh"
                  fi
                '';
                shellAliases = {
                  darwin-rebuild = "sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake git+ssh://git@github.com/nikhilmaddirala/nix-config#nikhilmaddirala-mbp";
                  nh-rebuild = "sudo nh darwin switch ~/repos/nix-config#nikhilmaddirala-mbp";
                };
              };

              # Enable Starship prompt for bash only
              programs.starship = {
                enable               = true;
                enableBashIntegration = true;
                settings = {
                  username = {
                    show_always = true;
                  };
                  hostname = {
                    ssh_only = false;
                  };
                };
              };

              # Configure CLI tools with proper Home Manager modules
              programs.fzf = {
                enable = true;
                enableBashIntegration = true;
              };

              programs.zoxide = {
                enable = true;
                enableBashIntegration = true;
              };

              programs.bat = {
                enable = true;
              };

              programs.yazi = {
                enable = true;
                enableBashIntegration = true;
              };

              programs.git = {
                enable = true;
                delta = {
                  enable = true;
                  options = {
                    navigate = true;
                    line-numbers = true;
                  };
                };
              };

              programs.home-manager.enable = true;

              # SSH configuration for linux-builder localhost connection
              programs.ssh = {
                enable = true;
                matchBlocks."localhost" = {
                  port = 31022;
                  user = "builder";
                  identityFile = "/Users/nikhilmaddirala/.ssh/linux-builder_ed25519";
                  extraOptions = {
                    StrictHostKeyChecking = "no";
                    UserKnownHostsFile = "/dev/null";
                    LogLevel = "ERROR";
                  };
                };
                matchBlocks."hostingbydesign" = {
                  hostname = "15.lw.itsby.design";
                  user = "box_ring_fence";
                  forwardAgent = true;
                };
                matchBlocks."hetzner" = {
                  hostname = "91.99.176.80";
                  user = "nikhilmaddirala";
                  forwardAgent = true;
                };
                matchBlocks."hetzner-root" = {
                  hostname = "91.99.176.80";
                  user = "root";
                };
              };
            };
          }
        ];
      };
    };

    # Custom development shells
    devShells = {
      aarch64-darwin = let
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
      in {
        tempEnv = pkgs.mkShell {
          pname       = "temp-shell";
          buildInputs = with pkgs; [
            curl
            wget
          ];
          shellHook   = '' echo "🐍 Python shell ready" '';
        };

        pythonEnv = pkgs.mkShell {
          pname       = "python-dev-shell";
          buildInputs = with pkgs; [
            python3Full
            # python3.withPackages (python-pkgs: [
            #   python-pkgs.pandas
            #   python-pkgs.pip
            # ])
          ];
          shellHook   = '' echo "🐍 Python shell ready" '';
        };

        nodeEnv = pkgs.mkShell {
          pname       = "node-dev-shell";
          buildInputs = with pkgs; [
            nodejs
            yarn
          ];
          shellHook   = ''
            echo "🚀 Node.js shell ready"
          '';
        };
      };
    };
  };
}