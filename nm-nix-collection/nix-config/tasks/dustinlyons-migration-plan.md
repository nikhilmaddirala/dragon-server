# dustinlyons Template Migration Analysis

## Current Architecture Comparison

### **nm-nix-config (Current - Monolithic)**
- **Single flake.nix** with everything inline (~200+ lines)
- **Direct configuration** with hardcoded username
- **Basic structure** but missing advanced features
- **Bash + Starship** shell setup
- **Manual Home Manager activation issues**

### **dustinlyons Template (Modular)**
- **Modular architecture** with separate files for different concerns
- **Template system** with `%USER%`, `%NAME%`, `%EMAIL%` placeholders  
- **Custom apps** for build/deployment automation
- **Zsh + Powerlevel10k** shell setup
- **Proper Home Manager integration** with `home.homeDirectory` and `home.username` settings
- **Advanced features**: dock management, secrets, overlays, multi-platform support

## Key Architectural Differences

### Template Structure
```
templates/starter/
├── flake.nix                    # Template flake with placeholders
├── apps/                       # Custom build/deployment scripts
├── hosts/darwin/               # Platform-specific configuration
├── modules/
│   ├── darwin/                 # macOS-specific modules
│   │   ├── home-manager.nix    # Home Manager integration
│   │   ├── packages.nix        # Darwin packages
│   │   └── casks.nix          # Homebrew casks
│   └── shared/                 # Cross-platform modules
│       ├── home-manager.nix    # Shared shell/tool config
│       └── packages.nix        # Shared packages
└── overlays/                   # Package overrides/patches
```

### Home Manager Integration Differences

**dustinlyons template includes:**
```nix
home-manager.users.${user} = { pkgs, config, lib, ... }:{
  home = {
    enableNixpkgsReleaseCheck = false;
    # CRITICAL: These settings are missing in nm-nix-config
    homeDirectory = "/Users/${user}";
    username = "${user}";
    packages = pkgs.callPackage ./packages.nix {};
    stateVersion = "23.11";
  };
  programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };
};
```

**nm-nix-config currently missing:**
- `home.homeDirectory`
- `home.username`
- Modular program imports

## Migration Strategy Options

### **Option A: Hybrid Approach (Recommended)**
Adopt dustinlyons modular architecture while keeping existing preferences:

1. **Create modular structure** from dustinlyons template
2. **Keep your package selections** but organize them into separate files
3. **Switch to Zsh + Powerlevel10k** OR modify template to use Bash + Starship
4. **Add missing Home Manager settings** (`home.homeDirectory`, `home.username`)
5. **Adopt custom apps** for better build automation
6. **Keep corporate-friendly setup** without secrets initially

### **Option B: Full Template Migration**  
Start fresh with dustinlyons template and customize:

1. **Initialize template** in new directory
2. **Run nix run .#apply** to set user info
3. **Migrate your package preferences** to template structure
4. **Add your corporate-specific settings**
5. **Test Home Manager auto-activation**

### **Option C: Fix Current Issues First**
Fix Home Manager activation in current config, then migrate later:

1. **Add missing `home.homeDirectory = "/Users/nikhilmaddirala"`**
2. **Add missing `home.username = "nikhilmaddirala"`** 
3. **Test if this fixes Home Manager auto-activation**
4. **Migrate to modular structure gradually**

## Key Benefits of Migration

1. **Better Home Manager Integration** - Proper activation without manual intervention
2. **Modular Architecture** - Easier to maintain and debug
3. **Build Automation** - Custom apps for common tasks
4. **Future-Proof** - Established patterns and community support
5. **Advanced Features** - Dock management, better shell setup, secrets support

## Recommended Implementation Plan

1. **First**: Fix immediate Home Manager issue in current config (Option C)
2. **Then**: Migrate to hybrid approach (Option A) to get best of both worlds
3. **Test**: Verify Home Manager auto-activation works with template
4. **Enhance**: Add advanced features as needed

This approach minimizes risk while solving the immediate Home Manager activation problem and setting up for future improvements.

## Next Steps

- [ ] Fix current Home Manager activation issue
- [ ] Test dustinlyons template initialization
- [ ] Plan modular architecture migration
- [ ] Implement hybrid approach
- [ ] Add advanced features (dock, secrets, etc.)