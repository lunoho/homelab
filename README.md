# Homelab Infrastructure

## Hardware & Network

**Server**: Intel NUC - i3-7100U (4 cores @ 2.4GHz), 8GB RAM, 120GB SSD
**Domain**: Custom domain (Hover registrar, Linode DNS)
**Network**: UniFi UDM Pro (local DNS, VPN, firewall)
**Local Domain**: <redacted, available in secrets.nix> for internal services

## Architecture

### Core Infrastructure (NixOS Services)
- **Reverse Proxy**: Traefik
- **Security**: fail2ban, firewall
- **Monitoring**: Prometheus + Grafana
- **DNS**: blocky or Pi-hole (tbd)
- **Backup**: Restic + automated snapshots

### Application Services (NixOS Services)
- **Media**: Jellyfin + *arr suite
- **Cloud**: Nextcloud
- **Password Management**: Vaultwarden
- **Home Automation**: Home Assistant
- **Dashboard**: Homepage or similar

### Data Storage
- **System**: NixOS on main drive
- **Media**: Large storage mount
- **Backups**: Automated to external storage

## Getting Started

1. **Clone the repository**
2. **Copy secrets template**: `cp secrets.nix.example secrets.nix`
3. **Edit secrets.nix** with your domain and email
4. **Deploy**: `./rebuild.sh`

## Configuration Structure

```
homelab/
├── configuration.nix          # Main system config
├── services/                  # Modular service configurations
│   ├── networking.nix         # Traefik, DNS, DDNS
│   ├── monitoring.nix         # Prometheus, Grafana (planned)
│   └── media.nix              # Jellyfin, *arr suite (planned)
├── secrets.nix               # Your domains/emails (git-ignored)
├── secrets.nix.example       # Template for secrets
└── rebuild.sh                # Enhanced deployment script
```

## Inspiration & References
- [TechHutTV Must-Have Services 2025](https://techhut.tv/must-have-home-server-services-2025/)
- [TechHutTV Homelab Config](https://github.com/TechHutTV/homelab)
- [NixOS Service Options](https://search.nixos.org/options)