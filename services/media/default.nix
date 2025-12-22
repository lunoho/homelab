{ config, lib, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./smb-mounts.nix
    ./jellyfin.nix
    ./sonarr.nix
    ./radarr.nix
    ./prowlarr.nix
    ./bazarr.nix
    ./jellyseerr.nix
    ./sabnzbd.nix
  ];

  # ===================
  # SERVICE DEPENDENCIES & ORDERING
  # ===================

  # Ensure Jellyfin starts after other media services are ready
  systemd.services.jellyfin.after = [ "sonarr.service" "radarr.service" ];

  # Ensure Prowlarr starts first as it manages indexers for other services
  systemd.services.sonarr.after = [ "prowlarr.service" "sabnzbd.service" ];
  systemd.services.radarr.after = [ "prowlarr.service" "sabnzbd.service" ];
  systemd.services.jellyseerr.after = [ "jellyfin.service" "sonarr.service" "radarr.service" ];
}
