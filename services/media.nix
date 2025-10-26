{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in
{
  # ===================
  # SHARED MEDIA USER & STORAGE
  # ===================
  
  # Create media user/group for consistent permissions across all services
  users.groups.media = {};
  users.users.media = {
    isSystemUser = true;
    group = "media";
    home = "/var/lib/media";
    createHome = true;
    extraGroups = [ "users" ]; # Allow access to user directories if needed
  };

  # Create media directories with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/media 0755 media media -"
    "d /var/lib/media/movies 0755 media media -"
    "d /var/lib/media/tv 0755 media media -"
    "d /var/lib/media/music 0755 media media -"
    "d /var/lib/media/downloads 0755 media media -"
    "d /var/lib/media/usenet 0755 media media -"
    "d /var/lib/media/usenet/completed 0755 media media -"
    "d /var/lib/media/usenet/incomplete 0755 media media -"
  ];

  # ===================
  # JELLYFIN MEDIA SERVER
  # ===================
  services.jellyfin = {
    enable = true;
    openFirewall = false; # Use Traefik for external access
    user = "media";
    group = "media";
  };

  # ===================
  # SONARR - TV SERIES MANAGEMENT
  # ===================
  services.sonarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
  };

  # ===================
  # RADARR - MOVIE MANAGEMENT  
  # ===================
  services.radarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
  };

  # ===================
  # PROWLARR - INDEXER MANAGEMENT
  # ===================
  services.prowlarr = {
    enable = true;
    openFirewall = false;
  };

  # ===================
  # BAZARR - SUBTITLE MANAGEMENT
  # ===================
  services.bazarr = {
    enable = true;
    openFirewall = false;
  };

  # ===================
  # JELLYSEERR - REQUEST MANAGEMENT
  # ===================
  services.jellyseerr = {
    enable = true;
    port = 5055;
    openFirewall = false; # Use Traefik for external access
  };

  # ===================
  # SABNZBD - USENET DOWNLOADER
  # ===================
  services.sabnzbd = {
    enable = true;
    openFirewall = false; # Use Traefik for external access
  };

  # ===================
  # SERVICE DEPENDENCIES & ORDERING
  # ===================
  
  # Ensure Jellyfin starts after other media services are ready
  systemd.services.jellyfin.after = [ "sonarr.service" "radarr.service" ];
  
  # Ensure Prowlarr starts first as it manages indexers for other services
  systemd.services.sonarr.after = [ "prowlarr.service" "sabnzbd.service" ];
  systemd.services.radarr.after = [ "prowlarr.service" "sabnzbd.service" ];
  systemd.services.jellyseerr.after = [ "jellyfin.service" "sonarr.service" "radarr.service" ];

  # ===================
  # MEDIA DIRECTORY STRUCTURE
  # ===================
  
  # Future: Configure additional storage mounts
  # This would typically be configured when you have a dedicated media drive
  # fileSystems."/var/lib/media" = {
  #   device = "/dev/disk/by-label/media-drive";
  #   fsType = "ext4";
  #   options = [ "defaults" "user" "rw" ];
  # };
}