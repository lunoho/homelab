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

  # Create password file for Grafana using preStart (more reliable than tmpfiles)
  systemd.services.grafana.preStart = ''
    mkdir -p /etc/secrets/grafana
    echo -n "${secrets.adminPassword}" > /etc/secrets/grafana/admin-password
    chmod 600 /etc/secrets/grafana/admin-password
    chown grafana:grafana /etc/secrets/grafana/admin-password
  '';


  # TODO: Configure alerting rules
  # TODO: Add more exporters (systemd, nginx, etc.)
}