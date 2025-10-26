{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in
{
  # ===================
  # REVERSE PROXY & SSL
  # ===================
  services.traefik = {
    enable = true;

    # Static configuration
    staticConfigOptions = {
      # Entry points (ports)
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entrypoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          address = ":443";
        };
      };

      # Certificate resolvers - Let's Encrypt with DNS challenges
      certificatesResolvers = {
        letsencrypt = {
          acme = {
            email = secrets.email;
            storage = "/var/lib/traefik/acme.json";
            dnsChallenge = {
              provider = "linode";
              delayBeforeCheck = 30;
            };
          };
        };
      };

      # File provider for static routes (since no Docker)
      providers = {
        file = {
          directory = "/etc/traefik/dynamic";
          watch = true;
        };
      };

      # API and dashboard
      api = {
        dashboard = true;
        insecure = false;
      };

      # Prometheus metrics endpoint
      metrics = {
        prometheus = {
          addEntryPointsLabels = true;
          addRoutersLabels = true;
          addServicesLabels = true;
          entryPoint = "metrics";
        };
      };

      # Add metrics entry point
      entryPoints.metrics = {
        address = ":9101";
      };

      # Logging
      log = {
        level = "INFO";
      };
      accessLog = {};
    };
  };

  # Create required directories and copy route config
  systemd.tmpfiles.rules = [
    "d /var/lib/traefik 0750 traefik traefik -"
    "d /etc/traefik/dynamic 0755 traefik traefik -"
  ];

  # Generate route configuration with secrets
  environment.etc."traefik/dynamic/routes.yml" = {
    text = ''
      http:
        routers:
          # Homepage Dashboard (root domain)
          homepage:
            rule: "Host(`${secrets.domain}`)"
            entryPoints:
              - websecure
            service: homepage
            tls:
              certResolver: letsencrypt
              domains:
                - main: "${secrets.domain}"
                  sans:
                    - "*.${secrets.domain}"

          # Traefik Dashboard
          traefik-dashboard:
            rule: "Host(`traefik.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: api@internal
            tls:
              certResolver: letsencrypt

          # AdGuard Home Dashboard
          adguard-dashboard:
            rule: "Host(`adguard.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: adguard
            tls:
              certResolver: letsencrypt

          # Grafana Dashboard
          grafana-dashboard:
            rule: "Host(`grafana.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: grafana
            tls:
              certResolver: letsencrypt

          # Prometheus Monitoring
          prometheus-dashboard:
            rule: "Host(`prometheus.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: prometheus
            tls:
              certResolver: letsencrypt

          # Alertmanager
          alertmanager-dashboard:
            rule: "Host(`alerts.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: alertmanager
            tls:
              certResolver: letsencrypt

          # Media Services
          jellyfin:
            rule: "Host(`jellyfin.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: jellyfin
            tls:
              certResolver: letsencrypt

          sonarr:
            rule: "Host(`sonarr.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: sonarr
            tls:
              certResolver: letsencrypt

          radarr:
            rule: "Host(`radarr.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: radarr
            tls:
              certResolver: letsencrypt

          prowlarr:
            rule: "Host(`prowlarr.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: prowlarr
            tls:
              certResolver: letsencrypt

          bazarr:
            rule: "Host(`bazarr.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: bazarr
            tls:
              certResolver: letsencrypt

          jellyseerr:
            rule: "Host(`requests.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: jellyseerr
            tls:
              certResolver: letsencrypt

          sabnzbd:
            rule: "Host(`sabnzbd.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: sabnzbd
            tls:
              certResolver: letsencrypt

        services:
          adguard:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:3000"

          grafana:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:3001"

          prometheus:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:9090"

          alertmanager:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:9093"

          # Media Services
          jellyfin:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:8096"

          sonarr:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:8989"

          radarr:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:7878"

          prowlarr:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:9696"

          bazarr:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:6767"

          jellyseerr:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:5055"

          sabnzbd:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:8080"

          homepage:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:8082"
    '';
    mode = "0644";
  };

  # Environment variables for DNS challenge
  systemd.services.traefik.environment = {
    LINODE_TOKEN = secrets.linode.apiToken;
  };

  # ===================
  # DNS AD-BLOCKING & LOCAL DNS
  # ===================
  services.adguardhome = {
    enable = true;
    host = "0.0.0.0";
    port = 3000;
    settings = {
      # Admin user configuration from secrets
      # Password hash will be generated from plain text password
      users = [];

      # DNS settings for split DNS
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;

        # Upstream DNS servers (DNS-over-HTTPS for privacy)
        upstream_dns = [
          "https://1.1.1.1/dns-query"
          "https://8.8.8.8/dns-query" 
          "https://9.9.9.9/dns-query"
        ];

        # Bootstrap DNS for initial resolution
        bootstrap_dns = [
          "1.1.1.1:53"
          "8.8.8.8:53"
        ];

        # Enable DNS-over-HTTPS
        upstream_dns_file = "";
      };

      # Filtering configuration with security hardening
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        blocking_mode = "default";
        blocked_response_ttl = 300;
        
        # Enhanced security features
        safe_browsing_enabled = true;  # Block malicious websites
        browsing_protection_enabled = true;  # Additional malware/phishing protection
        
        # Default blocklists
        filters = [
          {
            enabled = true;
            url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
            name = "AdGuard DNS filter";
            id = 1;
          }
          {
            enabled = true;
            url = "https://adaway.org/hosts.txt";
            name = "AdAway Default Blocklist";
            id = 2;
          }
        ];
        
        # DNS rewrites for local domain resolution
        rewrites = [
          {
            domain = "*.${secrets.domain}";
            answer = config.networking.primaryIPAddress or "192.168.1.5";
          }
        ];
      };

      # Web interface settings
      http = {
        address = "0.0.0.0:3000";
      };

      # Query logging
      querylog = {
        enabled = true;
        file_enabled = true;
        interval = "24h";  # Retain queries for 24 hours
        size_memory = 1000;
        anonymize_client_ip = true;  # Anonymize client IPs for privacy
      };

      # Statistics
      statistics = {
        enabled = true;
        interval = "24h";
      };

      # Client identification for network visibility
      clients = {
        runtime_sources = {
          whois = true;
          arp = true;
          rdns = true;
          dhcp = true;
        };
        persistent = [];  # Add specific client configs if needed
      };
    };
  };

  # Generate AdGuard admin user with bcrypt hash from plain text password
  systemd.services.adguard-setup = {
    description = "Setup AdGuard admin user";
    after = [ "adguardhome.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for AdGuard to be ready
      sleep 5
      
      # Generate bcrypt hash from plain text password
      HASH=$(${pkgs.apacheHttpd}/bin/htpasswd -nbB admin "${secrets.adminPassword}" | cut -d: -f2)
      
      # Set up admin user via API (only if not already configured)
      if ! ${pkgs.curl}/bin/curl -f http://localhost:3000/control/status >/dev/null 2>&1; then
        ${pkgs.curl}/bin/curl -X POST http://localhost:3000/control/install/configure \
          -H "Content-Type: application/json" \
          -d "{\"username\":\"admin\",\"password\":\"$HASH\"}"
      fi
    '';
  };

  # Open firewall ports
  networking.firewall = {
    allowedTCPPorts = [ 53 3000 ];
    allowedUDPPorts = [ 53 ];
  };
}
