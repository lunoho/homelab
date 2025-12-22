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

  # SMB credentials file (mount.cifs format)
  environment.etc."smb-credentials/alexandria" = {
    text = ''
user=${secrets.smbCredentials.alexandria.username}
pass=${secrets.smbCredentials.alexandria.password}
'';
    mode = "0600";
  };

  # Create mount point
  systemd.tmpfiles.rules = [
    "d /mnt/alexandria 0755 root root -"
  ];

  # Mount unit
  systemd.mounts = [{
    what = "//192.168.1.240/data";
    where = "/mnt/alexandria";
    type = "cifs";
    options = "credentials=/etc/smb-credentials/alexandria,uid=media,gid=media,file_mode=0644,dir_mode=0755,vers=2.0";
    wantedBy = []; # Don't auto-start, let automount trigger it
  }];

  # Automount unit
  systemd.automounts = [{
    where = "/mnt/alexandria";
    wantedBy = [ "multi-user.target" ];
    automountConfig = {
      TimeoutIdleSec = "600";
    };
  }];
}
