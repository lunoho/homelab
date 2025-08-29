# Homelab Infrastructure

Repository: git@github.com:lunoho/homelab.git

## Philosophy: NixOS-First Approach

This homelab uses a **pure NixOS approach** instead of Docker containers:

- **Declarative infrastructure**: All services defined in NixOS configuration
- **Atomic rollbacks**: Entire system can rollback to previous generations  
- **Better performance**: No container overhead
- **Integrated security**: Services run with proper systemd isolation
- **Single source of truth**: One configuration system manages everything

## Development Workflow

### Branch-based Development
For all infrastructure changes, use feature branches:

```bash
# Create feature branch locally
git checkout -b feature/add-jellyfin

# Edit NixOS configuration
vim configuration.nix
# OR edit modular files
vim services/media.nix

# Commit changes
git add . && git commit -m "Add Jellyfin media server"
git push -u origin feature/add-jellyfin

# Deploy to homelab for testing
ssh homelab
cd /home/user/homelab
./rebuild.sh --branch feature/add-jellyfin

# Test the service
# If successful, create PR and merge to main
```

### Configuration Management

**Modular Structure:**
- `configuration.nix` - Main system config, imports all modules
- `services/` - Individual service modules
- `secrets.nix` - Domain names, emails, and sensitive config (git-ignored)
- `secrets.nix.example` - Template for secrets file
- `hardware-configuration.nix` - Auto-generated hardware config

**Adding New Services:**
1. Create/edit service module (e.g., `services/media.nix`)
2. Import in `configuration.nix` 
3. Use `secrets.domain` for domain references, never hardcode domains
4. Test with `sudo nixos-rebuild test`
5. Apply with `sudo nixos-rebuild switch`

**Secrets Management:**
- `secrets.nix` contains actual domain names and emails
- Never commit `secrets.nix` to git (it's git-ignored)
- Use generic domains like `home.domain.com` in committed code
- Reference secrets via `let secrets = import ../secrets.nix; in`

### Deployment Scripts

**rebuild.sh** - Enhanced deployment script:
- `./rebuild.sh` - Standard update from current branch
- `./rebuild.sh -b feature/name` - Switch to branch and deploy  
- `./rebuild.sh -f` - Force rebuild without changes
- `./rebuild.sh -h` - Show help

### Best Practices

1. **Always use feature branches** for new services or major changes
2. **Test with `nixos-rebuild test`** before switching
3. **Keep services modular** - one service per module file when possible
4. **Use descriptive commit messages** that explain the "why"
5. **Document service access** in commit messages (URLs, ports, etc.)
6. **NEVER commit domain names or email addresses** - use generic examples like `domain.com` or `example.com` in code
7. **Always use secrets.nix** for actual domain names, emails, and other sensitive information

### Emergency Rollback
```bash
# NixOS built-in rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or via bootloader menu on restart
# Lists all previous generations to choose from

# Git-based rollback
git log --oneline  # Find last working commit
git checkout [commit-hash]
sudo nixos-rebuild switch
```