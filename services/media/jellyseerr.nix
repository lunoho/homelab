{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in
{
  # ===================
  # JELLYSEERR - REQUEST MANAGEMENT
  # ===================

  services.jellyseerr = {
    enable = true;
    port = 5055;
    openFirewall = false;
  };

  systemd.services.jellyseerr.preStart = ''
    CONFIG_DIR="/var/lib/private/jellyseerr"
    CONFIG_FILE="$CONFIG_DIR/settings.json"
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_FILE" ]; then
      cat > "$CONFIG_FILE" << 'EOF'
{
  "clientId": "",
  "vapidPrivate": "",
  "vapidPublic": "",
  "main": {
    "apiKey": "JELLYSEERR_API_KEY_PLACEHOLDER",
    "applicationTitle": "Jellyseerr",
    "applicationUrl": "",
    "csrfProtection": false,
    "cacheImages": false,
    "defaultPermissions": 32,
    "defaultQuotas": {
      "movie": {},
      "tv": {}
    },
    "hideAvailable": false,
    "localLogin": true,
    "newPlexLogin": true,
    "region": "",
    "originalLanguage": "",
    "trustProxy": false,
    "mediaServerType": 4,
    "partialRequestsEnabled": true,
    "locale": "en"
  },
  "plex": {
    "name": "",
    "ip": "",
    "port": 32400,
    "useSsl": false,
    "libraries": []
  },
  "jellyfin": {
    "name": "",
    "hostname": "",
    "externalHostname": "",
    "jellyfinForgotPasswordUrl": "",
    "libraries": [],
    "serverId": ""
  },
  "tautulli": {},
  "radarr": [],
  "sonarr": [],
  "public": {
    "initialized": false
  },
  "notifications": {
    "agents": {}
  },
  "jobs": {
    "plex-recently-added-scan": { "schedule": "0 */5 * * * *" },
    "plex-full-scan": { "schedule": "0 0 3 * * *" },
    "plex-watchlist-sync": { "schedule": "0 */10 * * * *" },
    "radarr-scan": { "schedule": "0 0 4 * * *" },
    "sonarr-scan": { "schedule": "0 30 4 * * *" },
    "availability-sync": { "schedule": "0 0 5 * * *" },
    "download-sync": { "schedule": "0 * * * * *" },
    "download-sync-reset": { "schedule": "0 0 1 * * *" },
    "jellyfin-recently-added-scan": { "schedule": "0 */5 * * * *" },
    "jellyfin-full-scan": { "schedule": "0 0 3 * * *" },
    "image-cache-cleanup": { "schedule": "0 0 5 * * *" }
  }
}
EOF
    fi

    # Always update API key
    if [ -f "$CONFIG_FILE" ]; then
      ${pkgs.jq}/bin/jq '.main.apiKey = "${secrets.apiKeys.jellyseerr}"' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
      mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    fi
  '';
}
