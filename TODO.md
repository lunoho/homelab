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
- [ ] Cloud Storage: Nextcloud
- [ ] Password Manager: Vaultwarden
- [ ] Home Automation: Home Assistant
- [ ] Dashboard: Homepage or Homarr

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