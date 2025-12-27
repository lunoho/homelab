{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in
{
  # Enable Avahi for mDNS (.local) resolution
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # Create mount point
  systemd.tmpfiles.rules = [
    "d /mnt/alexandria 0755 root root -"
  ];

  # TODO: Re-enable when alexandria NAS is back online
  # # Mount unit with inline credentials
  # systemd.mounts = [{
  #   what = "//192.168.1.240/data";
  #   where = "/mnt/alexandria";
  #   type = "cifs";
  #   options = "username=${secrets.smbCredentials.alexandria.username},password=${secrets.smbCredentials.alexandria.password},uid=media,gid=media,file_mode=0644,dir_mode=0755,vers=2.0";
  #   wantedBy = [];
  # }];

  # # Automount unit
  # systemd.automounts = [{
  #   where = "/mnt/alexandria";
  #   wantedBy = [ "multi-user.target" ];
  #   automountConfig = {
  #     TimeoutIdleSec = "600";
  #   };
  # }];
}
