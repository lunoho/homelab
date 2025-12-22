# Homelab TODO
## Core Infrastructure
- [x] Monitoring: Prometheus + Grafana + Alertmanager (with email alerts)
- [x] Internal DNS: AdGuard Home with split DNS for *.domain.com
- [x] SSL Certificates: ACME with DNS challenges for wildcard certs
- [x] DDNS: Linode DNS updates every 5 minutes
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

## Declarative Config (Completed via preStart scripts)
API keys and core settings are now declaratively injected on every boot:
- [x] SABnzbd: Full config including usenet servers, categories, paths
- [x] Bazarr: OpenSubtitles credentials, Sonarr/Radarr connections
- [x] Sonarr/Radarr/Prowlarr: API keys injected into config.xml
- [x] Jellyseerr: API key injected into settings.json

Manual setup still required (state stored in SQLite):
- [ ] Jellyfin: Create users, add media libraries, generate API key for Homepage
- [ ] Prowlarr: Add indexers (usenet/torrent)
- [ ] Sonarr/Radarr: Add root folders, quality profiles, connect to SABnzbd
- [ ] Jellyseerr: Run setup wizard (connect to Jellyfin, add Sonarr/Radarr)

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
- [x] Configure SMB mount at /mnt/alexandria
- [ ] Document data locations and recovery procedures

## Documentation & Maintenance
- [ ] Document service URLs and access methods
- [x] Create service status dashboard (Homepage with widgets)
- [x] Set up monitoring alerts (Alertmanager with email)
- [ ] Document rollback procedures