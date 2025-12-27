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
vim services/media/jellyfin.nix

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
- `services/storage/` - ZFS storage configuration (vessels pool)
- `services/media/` - Media stack (modular per-service files)
- `secrets.nix` - Domain names, credentials, API keys (git-ignored)
- `secrets.nix.example` - Template for secrets file
- `hardware-configuration.nix` - Auto-generated hardware config

**Adding New Services:**
1. Create/edit service module (e.g., `services/myservice.nix`)
2. Import in `configuration.nix`
3. Use `secrets.domain` for domain references, never hardcode domains
4. Test with `sudo nixos-rebuild test`
5. Apply with `sudo nixos-rebuild switch`

**Secrets Management:**
- `secrets.nix` contains domain names, API keys, and credentials
- Never commit `secrets.nix` to git (it's git-ignored)
- Use generic domains like `home.domain.com` in committed code
- Reference secrets via `let secrets = import /home/user/secrets.nix; in`

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

## Storage

### ZFS Pool: vessels

Primary storage on QNAP TR-004 DAS (4x12TB RAIDZ1, ~36TB usable):

```
/vessels/
├── media/              # Single dataset with folders (enables instant moves/hardlinks)
│   ├── movies/
│   ├── tv/
│   ├── music/
│   └── downloads/
│       ├── incomplete/
│       └── complete/
└── akhnaten/           # Separate datasets - backed up
    ├── photos/
    └── documents/
```

**Storage tiers:**
- `vessels/media` - Single dataset for all media. Folder structure enables *arr apps to hardlink/instant-move. Owned by `media:media`.
- `vessels/akhnaten/*` - Separate child datasets for critical files. Backed up to alexandria + offsite. Owned by `user:users`.

**Configuration:** `services/storage/zfs.nix`
- Auto-imports pool on boot
- Creates datasets and folders via systemd oneshot
- Monthly scrubs enabled
- LTS kernel for ZFS stability

**Known Issues & Workarounds:**
- **Use USB-A port, NOT USB-C/Thunderbolt**: The NUC7i3BNH's Alpine Ridge Thunderbolt controller crashes under sustained write I/O (xHCI dies with "host controller not responding, assume dead"). This is a [known Intel NUC issue](https://bugzilla.redhat.com/show_bug.cgi?id=1674263). Connect TR-004 to a USB-A port using a USB-C to USB-A cable - the PCH's USB controller (0000:00:14.0) is stable. Reads work fine on USB-C; only heavy writes crash it.
- **ZFS ARC limited to 4GB**: On the 8GB NUC, ZFS was consuming 6.6GB for caching, starving applications. Limited to 4GB via `zfs.zfs_arc_max` kernel parameter. Increase if RAM is upgraded.
- **8GB swap configured**: Prevents OOM kills and system freezes under memory pressure.

### Backup Strategy

| Data | Local Backup | Offsite |
|------|--------------|---------|
| `vessels/akhnaten/*` | alexandria (Synology) | TBD (B2 or family site) |
| `vessels/media/*` | None (replaceable) | None |

### alexandria (Synology NAS)

SMB mount at `/mnt/alexandria` - backup destination:
- Backup target for `vessels/akhnaten` (critical files)
- Can be powered off when not in use

## Media Stack

The media stack is organized in `services/media/` with one file per service:

```
services/media/
├── default.nix      # Imports all modules, defines service ordering
├── common.nix       # Shared media user/group
├── smb-mounts.nix   # Legacy NAS mount (/mnt/alexandria)
├── jellyfin.nix     # Media server
├── sonarr.nix       # TV series management
├── radarr.nix       # Movie management
├── prowlarr.nix     # Indexer management
├── bazarr.nix       # Subtitle management
├── jellyseerr.nix   # Request management
└── sabnzbd.nix      # Usenet downloader
```

### What's Declarative

These settings are managed in NixOS config and `secrets.nix`:
- API keys for all services (injected on every boot)
- SABnzbd usenet servers, categories, download directories
- Bazarr OpenSubtitles credentials
- Basic service settings (ports, auth mode, bind addresses)

### What Requires Manual Setup

The *arr apps store most config in SQLite databases. After first deploy:
- **Jellyfin**: Create users, add media libraries
- **Jellyseerr**: Run setup wizard (connect Jellyfin, add Sonarr/Radarr)
- **Sonarr/Radarr**: Add root folders, quality profiles, download client (SABnzbd)
- **Prowlarr**: Add indexers, sync to Sonarr/Radarr
- **Bazarr**: Add Sonarr/Radarr connections

State persists in `/var/lib/*` directories between rebuilds.

**Media paths:**
- Media library: `/vessels/media/{movies,tv,music}`
- Downloads: `/vessels/media/downloads/{incomplete,complete}`

### secrets.nix Media Fields

```nix
apiKeys = {
  sonarr = "...";
  radarr = "...";
  prowlarr = "...";
  bazarr = "...";
  sabnzbd = "...";
  jellyfin = "...";
  jellyseerr = "...";
};

usenetServers = [
  { host = "..."; port = 563; username = "..."; password = "..."; connections = 100; priority = 0; }
];

opensubtitles = { username = "..."; password = "..."; };
```