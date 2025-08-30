# Homelab TODO
## Core Infrastructure
- [ ] Monitoring: Prometheus + Grafana
- [ ] Internal DNS: AdGuard Home with split DNS for *.domain.com
- [ ] SSL Certificates: ACME with DNS challenges for wildcard certs
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
- [ ] AdGuard Home: Local DNS server with ad-blocking
- [ ] Split DNS: Internal resolution for homelab services
- [ ] Wildcard SSL: *.domain.com certificates via DNS challenges
- [ ] Consider Tailscale for secure remote access
- [ ] Document public vs private service access

## Data Storage & Backup
- [ ] Configure additional storage mounts
- [ ] Set up automated backup strategy (necessary?)
- [ ] Document data locations and recovery procedures

## Documentation & Maintenance
- [ ] Document service URLs and access methods
- [ ] Create service status dashboard
- [ ] Set up monitoring alerts
- [ ] Document rollback procedures