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

    path = with pkgs; [ curl jq coreutils ];

    serviceConfig = {
      Type = "oneshot";
      User = "ddns";
      Group = "ddns";
      ExecStart = let
        ddnsScript = pkgs.writeShellScript "ddns-update" ''
          ${builtins.readFile ../scripts/ddns-update.sh}
        '';
      in "${ddnsScript}";

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
      LINODE_SUBDOMAINS = builtins.toJSON secrets.linode.externalSubdomains;
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
}