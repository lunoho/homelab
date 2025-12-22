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
    
    alertmanager = {
      enable = true;
      port = 9093;
      configuration = {
        global = {
          smtp_smarthost = "smtp.fastmail.com:587";
          smtp_from = "${secrets.alertEmail}";
          smtp_auth_username = "${secrets.alertEmail}";
          smtp_auth_password = "${secrets.alertEmailPassword}";
        };
        
        route = {
          group_by = ["alertname"];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "12h";
          receiver = "email-alerts";
        };
        
        receivers = [
          {
            name = "email-alerts";
            email_configs = [
              {
                to = "${secrets.alertEmail}";
                headers = {
                  Subject = "🚨 Homelab Alert: {{ .GroupLabels.alertname }}";
                };
                html = ''
                  <h2>Homelab Alert</h2>
                  {{ range .Alerts }}
                  <h3>{{ .Annotations.summary }}</h3>
                  <p><strong>Description:</strong> {{ .Annotations.description }}</p>
                  <p><strong>Severity:</strong> {{ .Labels.severity }}</p>
                  <p><strong>Instance:</strong> {{ .Labels.instance }}</p>
                  <p><strong>Status:</strong> {{ .Status }}</p>
                  <hr>
                  {{ end }}
                '';
              }
            ];
          }
        ];
      };
    };

    alertmanagers = [
      {
        static_configs = [
          {
            targets = [ "127.0.0.1:9093" ];
          }
        ];
      }
    ];

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
        job_name = "traefik";
        static_configs = [{
          targets = [ "127.0.0.1:9101" ];
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
    after = [ "network-online.target" "grafana.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "grafana";
    };
    script = ''
      ${pkgs.curl}/bin/curl -fsSL --retry 3 --retry-delay 10 -o /var/lib/grafana/dashboards/node-exporter-full.json \
        "https://grafana.com/api/dashboards/1860/revisions/37/download" || true
      ${pkgs.curl}/bin/curl -fsSL --retry 3 --retry-delay 10 -o /var/lib/grafana/dashboards/postgres.json \
        "https://grafana.com/api/dashboards/9628/revisions/8/download" || true
      ${pkgs.curl}/bin/curl -fsSL --retry 3 --retry-delay 10 -o /var/lib/grafana/dashboards/traefik.json \
        "https://grafana.com/api/dashboards/4475/revisions/5/download" || true
      ${pkgs.curl}/bin/curl -fsSL --retry 3 --retry-delay 10 -o /var/lib/grafana/dashboards/prometheus-overview.json \
        "https://grafana.com/api/dashboards/3662/revisions/2/download" || true
      ${pkgs.curl}/bin/curl -fsSL --retry 3 --retry-delay 10 -o /var/lib/grafana/dashboards/alerts.json \
        "https://grafana.com/api/dashboards/13407/revisions/1/download" || true
      chmod 644 /var/lib/grafana/dashboards/*.json 2>/dev/null || true
    '';
  };

  # ===================
  # PROMETHEUS ALERTING RULES
  # ===================
  services.prometheus.rules = [
    ''
      groups:
        - name: system.rules
          rules:
            # High CPU usage
            - alert: HighCpuUsage
              expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "High CPU usage on {{ $labels.instance }}"
                description: "CPU usage is above 80% for more than 5 minutes"

            # High memory usage
            - alert: HighMemoryUsage
              expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "High memory usage on {{ $labels.instance }}"
                description: "Memory usage is above 85% for more than 5 minutes"

            # High disk usage
            - alert: HighDiskUsage
              expr: (node_filesystem_size_bytes - node_filesystem_avail_bytes) / node_filesystem_size_bytes * 100 > 90
              for: 5m
              labels:
                severity: critical
              annotations:
                summary: "High disk usage on {{ $labels.instance }}"
                description: "Disk usage on {{ $labels.mountpoint }} is above 90%"

            # Service down alerts
            - alert: ServiceDown
              expr: up == 0
              for: 2m
              labels:
                severity: critical
              annotations:
                summary: "Service {{ $labels.job }} is down"
                description: "{{ $labels.job }} has been down for more than 2 minutes"

            # System load high
            - alert: HighSystemLoad
              expr: node_load1 > 2
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "High system load on {{ $labels.instance }}"
                description: "System load is {{ $value }} for more than 5 minutes"

        - name: traefik.rules
          rules:
            # Traefik down
            - alert: TraefikDown
              expr: up{job="traefik"} == 0
              for: 2m
              labels:
                severity: critical
              annotations:
                summary: "Traefik reverse proxy is down"
                description: "Traefik reverse proxy is not responding"

        - name: postgres.rules
          rules:
            # PostgreSQL down
            - alert: PostgreSQLDown
              expr: up{job="postgres"} == 0
              for: 2m
              labels:
                severity: critical
              annotations:
                summary: "PostgreSQL database is down"
                description: "PostgreSQL database is not responding"

            # Too many connections
            - alert: PostgreSQLTooManyConnections
              expr: pg_stat_activity_count / pg_settings_max_connections * 100 > 80
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "PostgreSQL has too many connections"
                description: "PostgreSQL connection usage is above 80%"
    ''
  ];
}