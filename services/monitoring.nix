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

      systemd = {
        enable = true;
        port = 9558;
      };

      postgres = {
        enable = true;
        port = 9187;
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
        job_name = "systemd";
        static_configs = [{
          targets = [ "127.0.0.1:9558" ];
        }];
      }
      {
        job_name = "postgres";
        static_configs = [{
          targets = [ "127.0.0.1:9187" ];
        }];
      }
      {
        job_name = "adguard";
        static_configs = [{
          targets = [ "127.0.0.1:9617" ];
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

      dashboards.settings.providers = [{
        name = "default";
        orgId = 1;
        folder = "";
        type = "file";
        disableDeletion = false;
        updateIntervalSeconds = 10;
        allowUiUpdates = true;
        options.path = "/var/lib/grafana/dashboards";
      }];
    };
  };

  # Create dashboard directory
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
  ];

  # Download Grafana Dashboards
  systemd.services.grafana-dashboard-setup = {
    description = "Download Grafana dashboards";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "grafana";
    };
    script = ''
      ${pkgs.curl}/bin/curl -o /var/lib/grafana/dashboards/node-exporter-full.json \
        "https://grafana.com/api/dashboards/1860/revisions/37/download"

      ${pkgs.curl}/bin/curl -o /var/lib/grafana/dashboards/postgres.json \
        "https://grafana.com/api/dashboards/9628/revisions/8/download"

      chmod 644 /var/lib/grafana/dashboards/*.json
    '';
  };

  # TODO: Configure alerting rules
}