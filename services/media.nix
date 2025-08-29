{ config, lib, pkgs, ... }:

{
  # ===================
  # JELLYFIN MEDIA SERVER
  # ===================
  services.jellyfin = {
    enable = true;
    openFirewall = false; # Use Traefik for external access
    user = "media";
    group = "media"; 
  };

  # Create media user/group for consistent permissions
  users.groups.media = {};
  users.users.media = {
    isSystemUser = true;
    group = "media";
    home = "/var/lib/media";
    createHome = true;
  };

  # TODO: Add *arr suite services
  # services.sonarr.enable = true;
  # services.radarr.enable = true; 
  # services.prowlarr.enable = true;
  # services.bazarr.enable = true;

  # TODO: Configure media storage mounts
  # fileSystems."/media" = {
  #   device = "/dev/disk/by-label/media";
  #   fsType = "ext4";
  # };

  # TODO: Add Traefik routing labels
  # systemd.services.jellyfin.environment = {
  #   TRAEFIK_LABELS = "traefik.enable=true,traefik.http.routers.jellyfin.rule=Host(`jellyfin.home.domain.com`)";
  # };
}