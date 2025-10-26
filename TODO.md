# Homelab TODO
## Core Infrastructure
- [ ] Monitoring: Prometheus + Grafana
- [X] Internal DNS: AdGuard Home with split DNS for *.domain.com
- [X] SSL Certificates: ACME with DNS challenges for wildcard certs
- [ ] Backup System: Restic with automated snapshots

## Application Services (NixOS Services)
- [x] Media Server: Jellyfin
- [x] Media Management: Sonarr, Radarr, Prowlarr, Bazarr
- [x] Media Requests: Jellyseerr
- [x] Usenet Downloader: SABnzbd
- [x] Dashboard: Homepage
- [ ] Cloud Storage: Nextcloud
- [ ] Password Manager: Vaultwarden
- [ ] Home Automation: Home Assistant

## Declarative Config Templates (Extract from Web UI Setup)
Complete in this order (based on dependencies):
- [ ] Complete Prowlarr web UI setup and extract config: `sudo cat /var/lib/private/prowlarr/config.xml`
- [ ] Complete SABnzbd web UI setup and extract config: `sudo cat /var/lib/sabnzbd/sabnzbd.ini`
- [ ] Complete Sonarr web UI setup and extract config: `sudo cat /var/lib/sonarr/.config/NzbDrone/config.xml`
- [ ] Complete Radarr web UI setup and extract config: `sudo cat /var/lib/radarr/.config/Radarr/config.xml`
- [ ] Complete Jellyfin web UI setup and create API key in secrets.nix
- [ ] Complete Bazarr web UI setup and extract config: `sudo cat /var/lib/bazarr/config/config.ini`
- [ ] Complete Jellyseerr web UI setup and extract config: `sudo cat /var/lib/private/jellyseerr/settings.json`
- [ ] Run `./scripts/extract-configs.sh` to save all configs to ~/config-templates/
- [ ] Create declarative config templates in services/media.nix based on extracted configs

## Media Stack Configuration (Post-Deployment)
- [ ] Configure usenet credentials in SABnzbd
- [ ] Add indexers to Prowlarr (public trackers, usenet indexers)
- [ ] Connect Sonarr/Radarr to Prowlarr for indexer management
- [ ] Set up quality profiles in Sonarr/Radarr
- [ ] Configure download paths and media library locations
- [ ] Connect Jellyseerr to Jellyfin (API key setup)
- [ ] Test end-to-end workflow: request → download → library
- [ ] Optional: Implement declarative-jellyfin flake for advanced config

## Network & External Access
- [x] AdGuard Home: Local DNS server with ad-blocking
- [x] Split DNS: Internal resolution for homelab services
- [x] Wildcard SSL: *.domain.com certificates via DNS challenges
- [ ] Change UDM DNS to homelab once server build is stable
- [ ] Consider Tailscale for secure remote access
- [ ] Investigate additional AdGuard lists and settings

## Data Storage
- [ ] Configure additional storage mounts
- [ ] Document data locations and recovery procedures

## Documentation & Maintenance
- [ ] Document service URLs and access methods
- [ ] Create service status dashboard
- [ ] Set up monitoring alerts
- [ ] Document rollback procedures