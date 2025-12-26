{ config, lib, pkgs, ... }:

{
  # ===================
  # ZFS STORAGE - VESSELS
  # ===================
  # QNAP TR-004 with 4x12TB in RAIDZ1 (~36TB usable)
  # Pool created imperatively, managed declaratively

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "vessels" ];

  # Required for ZFS - unique per machine
  networking.hostId = "55311757";

  # ZFS maintenance
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
    };
    # TRIM disabled - not supported on HDDs
  };

  # Ensure datasets exist on boot
  systemd.services.zfs-datasets = {
    description = "Ensure ZFS datasets exist";
    after = [ "zfs-import.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Media - single dataset with folder structure (enables instant moves/hardlinks)
      ${pkgs.zfs}/bin/zfs list vessels/media || ${pkgs.zfs}/bin/zfs create vessels/media
      mkdir -p /vessels/media/{movies,tv,music,downloads}
      mkdir -p /vessels/media/downloads/{incomplete,complete}

      # Critical datasets (backed up to alexandria + offsite)
      ${pkgs.zfs}/bin/zfs list vessels/akhnaten || ${pkgs.zfs}/bin/zfs create vessels/akhnaten
      ${pkgs.zfs}/bin/zfs list vessels/akhnaten/photos || ${pkgs.zfs}/bin/zfs create vessels/akhnaten/photos
      ${pkgs.zfs}/bin/zfs list vessels/akhnaten/documents || ${pkgs.zfs}/bin/zfs create vessels/akhnaten/documents

      # Ensure media user owns media
      chown -R media:media /vessels/media
      # User owns critical datasets
      chown -R user:users /vessels/akhnaten
    '';
  };

  # Media services depend on ZFS datasets
  systemd.services.jellyfin.after = [ "zfs-datasets.service" ];
  systemd.services.sonarr.after = [ "zfs-datasets.service" ];
  systemd.services.radarr.after = [ "zfs-datasets.service" ];
  systemd.services.sabnzbd.after = [ "zfs-datasets.service" ];
}
