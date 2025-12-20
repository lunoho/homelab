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

  # Note: Jellyfin API keys are managed through the UI (Dashboard > API Keys)
  # They cannot be set declaratively as they're stored in the database
  # After first boot, create an API key in Jellyfin UI and add it to secrets.nix

  # ===================
  # SONARR - TV SERIES MANAGEMENT
  # ===================
  services.sonarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
  };

  # Declaratively set API key in config
  systemd.services.sonarr.preStart = ''
    CONFIG_FILE="/var/lib/sonarr/.config/NzbDrone/config.xml"
    if [ -f "$CONFIG_FILE" ]; then
      # Update existing API key
      ${pkgs.gnused}/bin/sed -i 's|<ApiKey>.*</ApiKey>|<ApiKey>${secrets.apiKeys.sonarr}</ApiKey>|' "$CONFIG_FILE"
    fi
  '';

  # ===================
  # RADARR - MOVIE MANAGEMENT
  # ===================
  services.radarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
  };

  # Declaratively set API key in config
  systemd.services.radarr.preStart = ''
    CONFIG_FILE="/var/lib/radarr/.config/Radarr/config.xml"
    if [ -f "$CONFIG_FILE" ]; then
      # Update existing API key
      ${pkgs.gnused}/bin/sed -i 's|<ApiKey>.*</ApiKey>|<ApiKey>${secrets.apiKeys.radarr}</ApiKey>|' "$CONFIG_FILE"
    fi
  '';

  # ===================
  # PROWLARR - INDEXER MANAGEMENT
  # ===================
  services.prowlarr = {
    enable = true;
    openFirewall = false;
  };

  # Declaratively set API key in config
  systemd.services.prowlarr.preStart = ''
    CONFIG_FILE="/var/lib/private/prowlarr/config.xml"
    if [ -f "$CONFIG_FILE" ]; then
      # Update existing API key
      ${pkgs.gnused}/bin/sed -i 's|<ApiKey>.*</ApiKey>|<ApiKey>${secrets.apiKeys.prowlarr}</ApiKey>|' "$CONFIG_FILE"
    fi
  '';

  # ===================
  # BAZARR - SUBTITLE MANAGEMENT
  # ===================
  services.bazarr = {
    enable = true;
    openFirewall = false;
  };

  # Declaratively set API key in config
  systemd.services.bazarr.preStart = ''
    CONFIG_FILE="/var/lib/bazarr/config/config.ini"
    if [ -f "$CONFIG_FILE" ]; then
      # Update existing API key in INI format
      ${pkgs.gnused}/bin/sed -i 's|^apikey = .*|apikey = ${secrets.apiKeys.bazarr}|' "$CONFIG_FILE"
    fi
  '';

  # ===================
  # JELLYSEERR - REQUEST MANAGEMENT
  # ===================
  services.jellyseerr = {
    enable = true;
    port = 5055;
    openFirewall = false; # Use Traefik for external access
  };

  # Declaratively set API key in config
  systemd.services.jellyseerr.preStart = ''
    CONFIG_FILE="/var/lib/private/jellyseerr/settings.json"
    if [ -f "$CONFIG_FILE" ]; then
      # Update existing API key using jq
      ${pkgs.jq}/bin/jq '.main.apiKey = "${secrets.apiKeys.jellyseerr}"' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
      mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    fi
  '';

  # ===================
  # SABNZBD - USENET DOWNLOADER
  # ===================
  services.sabnzbd = {
    enable = true;
    openFirewall = false; # Use Traefik for external access
  };

  # Declaratively set API key and host whitelist in config
  systemd.services.sabnzbd.preStart = ''
    CONFIG_FILE="/var/lib/sabnzbd/sabnzbd.ini"
    if [ -f "$CONFIG_FILE" ]; then
      ${pkgs.gnused}/bin/sed -i 's|^api_key = .*|api_key = ${secrets.apiKeys.sabnzbd}|' "$CONFIG_FILE"
      ${pkgs.gnused}/bin/sed -i 's|^host_whitelist = .*|host_whitelist = sabnzbd.${secrets.domain}, localhost|' "$CONFIG_FILE"
    fi
  '';

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