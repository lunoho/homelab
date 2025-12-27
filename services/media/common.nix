{ config, lib, pkgs, ... }:

{
  # ===================
  # SHARED MEDIA USER & STORAGE
  # ===================
  # Media stored on ZFS pool "vessels" at /vessels/media
  # Single dataset with folders: movies, tv, music, downloads

  users.groups.media = {};
  users.users.media = {
    isSystemUser = true;
    group = "media";
    home = "/var/lib/media";
    createHome = true;
    extraGroups = [ "users" ];
  };

  # SABnzbd state directory permissions
  systemd.tmpfiles.rules = [
    "Z /var/lib/sabnzbd 0755 media media -"
  ];
}
