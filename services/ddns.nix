{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in

{
  # DDNS Update Service
  systemd.services.ddns-update = {
    description = "Linode DDNS Update Service";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "ddns";
      Group = "ddns";
      ExecStart = "${pkgs.bash}/bin/bash ${../scripts/ddns-update.sh}";

      # Provide necessary tools in PATH
      Path = with pkgs; [ curl jq coreutils ];

      # Security hardening
      DynamicUser = true;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];

      # Network access required
      PrivateNetwork = false;

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
    };

    environment = {
      LINODE_API_TOKEN = secrets.linode.apiToken;
      LINODE_DOMAIN_ID = secrets.linode.domainId;
      LINODE_RECORD_ID = secrets.linode.recordId;
      DOMAIN_NAME = secrets.domain;
    };
  };

  # DDNS Update Timer (runs every 5 minutes)
  systemd.timers.ddns-update = {
    description = "Run DDNS Update every 5 minutes";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "2min";      # Start 2 minutes after boot
      OnUnitActiveSec = "5min"; # Run every 5 minutes
      Persistent = true;        # Catch up on missed runs
    };
  };

  # Create users and groups
  users.users.ddns = {
    description = "DDNS Update Service User";
    isSystemUser = true;
    group = "ddns";
  };

  users.groups.ddns = {};

  # Ensure script is executable
  system.activationScripts.ddns-script-permissions = ''
    chmod +x ${../scripts/ddns-update.sh}
  '';
}