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

      # Color scheme
      color = "slate";
      theme = "dark";

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
                key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
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
                key = "{{HOMEPAGE_VAR_JELLYSEERR_API_KEY}}";
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
                key = "{{HOMEPAGE_VAR_SABNZBD_API_KEY}}";
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
                key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
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
                key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
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
                key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
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
                key = "{{HOMEPAGE_VAR_BAZARR_API_KEY}}";
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
                password = "{{HOMEPAGE_VAR_ADGUARD_PASSWORD}}";
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

  # Environment file for API keys (will need to be created manually)
  systemd.services.homepage-dashboard.serviceConfig = {
    EnvironmentFile = lib.mkForce "/var/lib/homepage-dashboard/homepage.env";
  };

  # Create directory for environment file
  systemd.tmpfiles.rules = [
    "d /var/lib/homepage-dashboard 0750 homepage homepage -"
  ];

  # Create a placeholder environment file with instructions
  environment.etc."homepage-dashboard/homepage.env.example" = {
    text = ''
      # Homepage Dashboard API Keys
      # Copy this file to /var/lib/homepage-dashboard/homepage.env and fill in your API keys
      # Then restart homepage: sudo systemctl restart homepage-dashboard

      # Jellyfin API Key (Settings > API Keys in Jellyfin)
      HOMEPAGE_VAR_JELLYFIN_API_KEY=your_jellyfin_api_key

      # Jellyseerr API Key (Settings > General in Jellyseerr)
      HOMEPAGE_VAR_JELLYSEERR_API_KEY=your_jellyseerr_api_key

      # SABnzbd API Key (Config > General in SABnzbd)
      HOMEPAGE_VAR_SABNZBD_API_KEY=your_sabnzbd_api_key

      # Sonarr API Key (Settings > General in Sonarr)
      HOMEPAGE_VAR_SONARR_API_KEY=your_sonarr_api_key

      # Radarr API Key (Settings > General in Radarr)
      HOMEPAGE_VAR_RADARR_API_KEY=your_radarr_api_key

      # Prowlarr API Key (Settings > General in Prowlarr)
      HOMEPAGE_VAR_PROWLARR_API_KEY=your_prowlarr_api_key

      # Bazarr API Key (Settings > General in Bazarr)
      HOMEPAGE_VAR_BAZARR_API_KEY=your_bazarr_api_key

      # AdGuard Home Password (admin user password)
      HOMEPAGE_VAR_ADGUARD_PASSWORD=your_adguard_password
    '';
    mode = "0644";
  };
}
