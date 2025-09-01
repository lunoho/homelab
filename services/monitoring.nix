{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in
{
  # ===================
  # PROMETHEUS MONITORING
  # ===================
  services.prometheus = {
    enable = true;
    port = 9090;

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" "processes" ];
        port = 9100;
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "127.0.0.1:9100" ];
        }];
      }
      {
        job_name = "traefik";
        static_configs = [{
          targets = [ "127.0.0.1:8080" ];
        }];
      }
    ];
  };

  # ===================
  # GRAFANA DASHBOARDS
  # ===================
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3001;
        http_addr = "127.0.0.1";
        domain = "grafana.${secrets.domain}";
        root_url = "https://grafana.${secrets.domain}";
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{/etc/secrets/grafana/admin-password}";
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [{
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:9090";
        isDefault = true;
      }];
    };
  };

  # Create password file for Grafana (avoids Nix store)
  systemd.tmpfiles.rules = [
    "d /etc/secrets/grafana 0755 root root -"
    "f+ /etc/secrets/grafana/admin-password 0600 grafana grafana - ${secrets.adminPassword}"
  ];


  # TODO: Configure alerting rules
  # TODO: Add more exporters (systemd, nginx, etc.)
}