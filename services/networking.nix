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
          # Traefik Dashboard
          traefik-dashboard:
            rule: "Host(`traefik.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: api@internal
            tls:
              certResolver: letsencrypt
              domains:
                - main: "${secrets.domain}"
                  sans:
                    - "*.${secrets.domain}"

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

        services:
          adguard:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:3000"

          grafana:
            loadBalancer:
              servers:
                - url: "http://127.0.0.1:3001"

        # Future services will be added here
        # Example:
        # jellyfin:
        #   loadBalancer:
        #     servers:
        #       - url: "http://127.0.0.1:8096"
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
      # Password must be bcrypt hash - see secrets.nix.example for generation commands
      users = [
        {
          name = "admin";
          password = secrets.adminPassword;
        }
      ];

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

  # Open firewall ports
  networking.firewall = {
    allowedTCPPorts = [ 53 3000 ];
    allowedUDPPorts = [ 53 ];
  };
}
