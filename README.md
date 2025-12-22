# Homelab Infrastructure

## Hardware & Network

**Server**: Intel NUC - i3-7100U (4 cores @ 2.4GHz), 8GB RAM, 120GB SSD
**Domain**: Custom domain (Hover registrar, Linode DNS)
**Network**: UniFi UDM Pro (local DNS, VPN, firewall)
**Local Domain**: <redacted, available in secrets.nix> for internal services

## Architecture

### Core Infrastructure (Implemented)
- **Reverse Proxy**: Traefik (wildcard SSL via Linode DNS)
- **DNS & Ad-blocking**: AdGuard Home (split DNS for internal services)
- **Security**: fail2ban, firewall, systemd isolation
- **Monitoring**: Prometheus + Grafana + Alertmanager (email alerts)
- **DDNS**: Linode DNS updates every 5 minutes

### Application Services (Implemented)
- **Media Server**: Jellyfin
- **Media Management**: Sonarr, Radarr, Prowlarr, Bazarr
- **Media Requests**: Jellyseerr
- **Usenet**: SABnzbd
- **Dashboard**: Homepage (with live service widgets)

### Future Services (Planned)
- **Backup**: Restic + automated snapshots
- **Cloud**: Nextcloud
- **Password Management**: Vaultwarden
- **Home Automation**: Home Assistant

### Data Storage
- **System**: NixOS on main drive
- **Media**: SMB mount at /mnt/alexandria
- **Service Data**: /var/lib/* directories

## Getting Started

### First-Time Setup

1. **Clone the repository** on your homelab server
2. **Generate secrets**: `./scripts/init-secrets.sh` (auto-generates API keys)
3. **Deploy**: `./rebuild.sh`
4. **Configure Jellyfin API** (only service requiring manual setup):
   - Go to Jellyfin → Dashboard → API Keys
   - Create key named "Homepage"
   - Update `secrets.nix` with the key
   - Rebuild: `./rebuild.sh`

## Configuration Structure

```
homelab/
├── configuration.nix          # Main system config
├── hardware-configuration.nix # Auto-generated hardware config
├── services/
│   ├── networking.nix         # Traefik, AdGuard Home
│   ├── monitoring.nix         # Prometheus, Grafana, Alertmanager
│   ├── ddns.nix               # Linode DDNS updates
│   ├── homepage.nix           # Dashboard with service widgets
│   ├── home-manager.nix       # User environment config
│   └── media/
│       ├── default.nix        # Media imports and orchestration
│       ├── common.nix         # Shared user/storage config
│       ├── smb-mounts.nix     # Network storage mounts
│       ├── jellyfin.nix       # Media server
│       ├── sonarr.nix         # TV series management
│       ├── radarr.nix         # Movie management
│       ├── prowlarr.nix       # Indexer manager
│       ├── bazarr.nix         # Subtitle management
│       ├── jellyseerr.nix     # Request management
│       └── sabnzbd.nix        # Usenet downloader
├── scripts/
│   ├── init-secrets.sh        # Generate initial secrets
│   ├── extract-configs.sh     # Extract service configs
│   └── ddns-update.sh         # DDNS update script
├── secrets.nix               # Your domains/credentials (git-ignored)
├── secrets.nix.example       # Template for secrets
└── rebuild.sh                # Enhanced deployment script
```

## Inspiration & References
- [TechHutTV Must-Have Services 2025](https://techhut.tv/must-have-home-server-services-2025/)
- [TechHutTV Homelab Config](https://github.com/TechHutTV/homelab)
- [NixOS Service Options](https://search.nixos.org/options)
- [Nixarr](https://nixarr.com/nixos-options/)
