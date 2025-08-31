# Homelab TODO
## Core Infrastructure
- [ ] Monitoring: Prometheus + Grafana
- [X] Internal DNS: AdGuard Home with split DNS for *.domain.com
- [X] SSL Certificates: ACME with DNS challenges for wildcard certs
- [ ] Backup System: Restic with automated snapshots (necessary?)

## Application Services (NixOS Services)
- [ ] Media Server: Jellyfin
- [ ] Media Management: Sonarr, Radarr, Prowlarr, Bazarr
- [ ] Media Requests: Overseerr or Jellyseerr
- [ ] Cloud Storage: Nextcloud
- [ ] Password Manager: Vaultwarden
- [ ] Home Automation: Home Assistant
- [ ] Dashboard: Homepage or Homarr

## Network & External Access
- [x] AdGuard Home: Local DNS server with ad-blocking
- [x] Split DNS: Internal resolution for homelab services
- [x] Wildcard SSL: *.domain.com certificates via DNS challenges
- [ ] Change UDM DNS to homelab once server build is stable
- [ ] Consider Tailscale for secure remote access
- [ ] Investigate additional AdGuard lists and settings

## Data Storage & Backup
- [ ] Configure additional storage mounts
- [ ] Set up automated backup strategy
- [ ] Document data locations and recovery procedures

## Documentation & Maintenance
- [ ] Document service URLs and access methods
- [ ] Create service status dashboard
- [ ] Set up monitoring alerts
- [ ] Document rollback procedures