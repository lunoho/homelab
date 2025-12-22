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

  # SMB credentials file
  environment.etc."smb-credentials/alexandria" = {
    text = ''
      username=${secrets.smbCredentials.alexandria.username}
      password=${secrets.smbCredentials.alexandria.password}
    '';
    mode = "0600";
  };

  # Mount the Synology share
  fileSystems."/mnt/alexandria" = {
    device = "//alexandria.local/data";
    fsType = "cifs";
    options = [
      "credentials=/etc/smb-credentials/alexandria"
      "uid=media"
      "gid=media"
      "file_mode=0644"
      "dir_mode=0755"
      "vers=2.0"
      "x-systemd.automount"
      "noauto"
      "_netdev"
    ];
  };
}
