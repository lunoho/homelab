{ config, lib, pkgs, ... }:

{
  # ===================
  # SHARED MEDIA USER & STORAGE
  # ===================

  users.groups.media = {};
  users.users.media = {
    isSystemUser = true;
    group = "media";
    home = "/var/lib/media";
    createHome = true;
    extraGroups = [ "users" ];
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
    "Z /var/lib/sabnzbd 0755 media media -"
  ];
}
