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

      # Certificate resolvers
      certificatesResolvers = {
        letsencrypt = {
          acme = {
            email = secrets.email;
            storage = "/var/lib/traefik/acme.json";
            httpChallenge = {
              entryPoint = "web";
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

          # Test service - simple API endpoint
          traefik-ping:
            rule: "Host(`ping.${secrets.domain}`)"
            entryPoints:
              - websecure
            service: ping@internal
            tls:
              certResolver: letsencrypt

        # Future services will be added here
        # Example:
        # services:
        #   jellyfin:
        #     loadBalancer:
        #       servers:
        #         - url: "http://127.0.0.1:8096"
    '';
    mode = "0644";
  };

  # ===================
  # DNS AD-BLOCKING
  # ===================
  # TODO: Add blocky/pihole configuration

  # ===================
  # DYNAMIC DNS
  # ===================
  # TODO: Add DDNS configuration for Linode
}