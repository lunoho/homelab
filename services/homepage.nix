{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in
{
  # ===================
  # HOMEPAGE DASHBOARD
  # ===================
  services.homepage-dashboard = {
    enable = true;

    # Listen on localhost only - Traefik will proxy
    listenPort = 8082;

    # Main settings
    settings = {
      title = "Homelab Dashboard";
      favicon = "https://gethomepage.dev/img/favicon.ico";

      # Base URL for proper host validation
      base = "https://home.${secrets.domain}";

      # Color scheme
      color = "slate";
      theme = "dark";

      # Security - allow access from our domain
      headerStyle = "boxed";
      target = "_blank";

      # Layout
      layout = {
        "Media Services" = {
          style = "row";
          columns = 3;
        };
        "Management" = {
          style = "row";
          columns = 3;
        };
        "Monitoring" = {
          style = "row";
          columns = 3;
        };
      };
    };

    # Service widgets with live integrations
    services = [
      {
        "Media Services" = [
          {
            "Jellyfin" = {
              icon = "jellyfin.png";
              href = "https://jellyfin.${secrets.domain}";
              description = "Media Server";
              widget = {
                type = "jellyfin";
                url = "http://127.0.0.1:8096";
                key = secrets.apiKeys.jellyfin;
                enableBlocks = true;
                enableNowPlaying = true;
              };
            };
          }
          {
            "Jellyseerr" = {
              icon = "jellyseerr.png";
              href = "https://requests.${secrets.domain}";
              description = "Media Requests";
              widget = {
                type = "jellyseerr";
                url = "http://127.0.0.1:5055";
                key = secrets.apiKeys.jellyseerr;
              };
            };
          }
          {
            "SABnzbd" = {
              icon = "sabnzbd.png";
              href = "https://sabnzbd.${secrets.domain}";
              description = "Usenet Downloader";
              widget = {
                type = "sabnzbd";
                url = "http://127.0.0.1:8080";
                key = secrets.apiKeys.sabnzbd;
              };
            };
          }
        ];
      }
      {
        "Management" = [
          {
            "Sonarr" = {
              icon = "sonarr.png";
              href = "https://sonarr.${secrets.domain}";
              description = "TV Series Management";
              widget = {
                type = "sonarr";
                url = "http://127.0.0.1:8989";
                key = secrets.apiKeys.sonarr;
                enableQueue = true;
              };
            };
          }
          {
            "Radarr" = {
              icon = "radarr.png";
              href = "https://radarr.${secrets.domain}";
              description = "Movie Management";
              widget = {
                type = "radarr";
                url = "http://127.0.0.1:7878";
                key = secrets.apiKeys.radarr;
                enableQueue = true;
              };
            };
          }
          {
            "Prowlarr" = {
              icon = "prowlarr.png";
              href = "https://prowlarr.${secrets.domain}";
              description = "Indexer Manager";
              widget = {
                type = "prowlarr";
                url = "http://127.0.0.1:9696";
                key = secrets.apiKeys.prowlarr;
              };
            };
          }
          {
            "Bazarr" = {
              icon = "bazarr.png";
              href = "https://bazarr.${secrets.domain}";
              description = "Subtitle Management";
              widget = {
                type = "bazarr";
                url = "http://127.0.0.1:6767";
                key = secrets.apiKeys.bazarr;
              };
            };
          }
        ];
      }
      {
        "Monitoring" = [
          {
            "Grafana" = {
              icon = "grafana.png";
              href = "https://grafana.${secrets.domain}";
              description = "Metrics & Dashboards";
            };
          }
          {
            "Prometheus" = {
              icon = "prometheus.png";
              href = "https://prometheus.${secrets.domain}";
              description = "Metrics Collection";
            };
          }
          {
            "AdGuard Home" = {
              icon = "adguard-home.png";
              href = "https://adguard.${secrets.domain}";
              description = "DNS & Ad Blocking";
              widget = {
                type = "adguard";
                url = "http://127.0.0.1:3000";
                username = "admin";
                password = secrets.adminPassword;
              };
            };
          }
          {
            "Traefik" = {
              icon = "traefik.png";
              href = "https://traefik.${secrets.domain}";
              description = "Reverse Proxy";
            };
          }
        ];
      }
    ];

    # Bookmarks section
    bookmarks = [
      {
        "Documentation" = [
          {
            "NixOS Manual" = [
              {
                abbr = "NX";
                href = "https://nixos.org/manual/nixos/stable/";
              }
            ];
          }
          {
            "Homepage Docs" = [
              {
                abbr = "HP";
                href = "https://gethomepage.dev/";
              }
            ];
          }
        ];
      }
    ];

    # Widgets for system info and other data
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          uptime = true;
        };
      }
      {
        search = {
          provider = "google";
          target = "_blank";
        };
      }
    ];
  };

  # Add allowed hosts for our domain (we're behind Traefik)
  systemd.services.homepage-dashboard.environment = {
    HOMEPAGE_ALLOWED_HOSTS = lib.mkForce "localhost:8082,127.0.0.1:8082,home.${secrets.domain}";
  };
}
