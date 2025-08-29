{ config, lib, pkgs, ... }:

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
        http_port = 3000;
        http_addr = "127.0.0.1";
      };
      security = {
        admin_user = "admin";
        admin_password = "changeme"; # TODO: Use secrets management
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

  # TODO: Add Traefik labels for Grafana web access
  # TODO: Configure alerting rules
  # TODO: Add more exporters (systemd, nginx, etc.)
}