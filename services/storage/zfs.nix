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
      ${pkgs.zfs}/bin/zfs list vessels/media || ${pkgs.zfs}/bin/zfs create vessels/media
      ${pkgs.zfs}/bin/zfs list vessels/media/movies || ${pkgs.zfs}/bin/zfs create vessels/media/movies
      ${pkgs.zfs}/bin/zfs list vessels/media/tv || ${pkgs.zfs}/bin/zfs create vessels/media/tv
      ${pkgs.zfs}/bin/zfs list vessels/media/music || ${pkgs.zfs}/bin/zfs create vessels/media/music
      ${pkgs.zfs}/bin/zfs list vessels/media/downloads || ${pkgs.zfs}/bin/zfs create vessels/media/downloads

      # Create download subdirectories
      mkdir -p /vessels/media/downloads/{incomplete,complete}

      # Ensure media user owns the datasets
      chown -R media:media /vessels/media
    '';
  };

  # Media services depend on ZFS datasets
  systemd.services.jellyfin.after = [ "zfs-datasets.service" ];
  systemd.services.sonarr.after = [ "zfs-datasets.service" ];
  systemd.services.radarr.after = [ "zfs-datasets.service" ];
  systemd.services.sabnzbd.after = [ "zfs-datasets.service" ];
}
