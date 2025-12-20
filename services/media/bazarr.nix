{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in
{
  # ===================
  # BAZARR - SUBTITLE MANAGEMENT
  # ===================

  services.bazarr = {
    enable = true;
    openFirewall = false;
  };

  systemd.services.bazarr.preStart = ''
    CONFIG_DIR="/var/lib/bazarr/config"
    CONFIG_FILE="$CONFIG_DIR/config.yaml"
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_FILE" ]; then
      cat > "$CONFIG_FILE" << 'EOF'
analytics:
  enabled: false
auth:
  apikey: BAZARR_API_KEY_PLACEHOLDER
  password: ''
  type: null
  username: ''
backup:
  day: 6
  folder: /var/lib/bazarr/backup
  frequency: Weekly
  hour: 3
  retention: 31
general:
  adaptive_searching: true
  adaptive_searching_delay: 3w
  adaptive_searching_delta: 1w
  anti_captcha_provider: null
  auto_update: false
  base_url: ''
  branch: master
  chmod: '0640'
  chmod_enabled: false
  days_to_upgrade_subs: 7
  debug: false
  embedded_subs_show_desired: true
  embedded_subtitles_parser: ffprobe
  enabled_providers:
  - opensubtitlescom
  hi_extension: hi
  ip: '*'
  minimum_score: 90
  minimum_score_movie: 70
  movie_default_enabled: false
  multithreading: true
  page_size: 25
  port: 6767
  serie_default_enabled: false
  single_language: false
  theme: auto
  upgrade_frequency: 12
  upgrade_manual: true
  upgrade_subs: true
  use_embedded_subs: true
  use_radarr: true
  use_sonarr: true
  utf8_encode: true
  wanted_search_frequency: 6
  wanted_search_frequency_movie: 6
opensubtitlescom:
  include_ai_translated: false
  password: OPENSUBTITLES_PASSWORD_PLACEHOLDER
  use_hash: false
  username: OPENSUBTITLES_USERNAME_PLACEHOLDER
radarr:
  apikey: RADARR_API_KEY_PLACEHOLDER
  base_url: ''
  defer_search_signalr: false
  excluded_tags: []
  full_update: Daily
  full_update_day: 6
  full_update_hour: 4
  http_timeout: 60
  ip: 127.0.0.1
  movies_sync: 60
  only_monitored: false
  port: 7878
  ssl: false
  sync_only_monitored_movies: false
  use_ffprobe_cache: true
sonarr:
  apikey: SONARR_API_KEY_PLACEHOLDER
  base_url: ''
  defer_search_signalr: false
  exclude_season_zero: false
  excluded_series_types: []
  excluded_tags: []
  full_update: Daily
  full_update_day: 6
  full_update_hour: 4
  http_timeout: 60
  ip: 127.0.0.1
  only_monitored: false
  port: 8989
  series_sync: 60
  ssl: false
  sync_only_monitored_episodes: false
  sync_only_monitored_series: false
  use_ffprobe_cache: true
EOF
    fi

    # Always update secrets
    ${pkgs.gnused}/bin/sed -i "s|apikey: BAZARR_API_KEY_PLACEHOLDER|apikey: ${secrets.apiKeys.bazarr}|" "$CONFIG_FILE"
    ${pkgs.gnused}/bin/sed -i "s|apikey: RADARR_API_KEY_PLACEHOLDER|apikey: ${secrets.apiKeys.radarr}|" "$CONFIG_FILE"
    ${pkgs.gnused}/bin/sed -i "s|apikey: SONARR_API_KEY_PLACEHOLDER|apikey: ${secrets.apiKeys.sonarr}|" "$CONFIG_FILE"
    ${pkgs.gnused}/bin/sed -i "s|password: OPENSUBTITLES_PASSWORD_PLACEHOLDER|password: ${secrets.opensubtitles.password}|" "$CONFIG_FILE"
    ${pkgs.gnused}/bin/sed -i "s|username: OPENSUBTITLES_USERNAME_PLACEHOLDER|username: ${secrets.opensubtitles.username}|" "$CONFIG_FILE"

    # Update existing configs that already have real values
    ${pkgs.gnused}/bin/sed -i "s|^  apikey:.*|  apikey: ${secrets.apiKeys.bazarr}|" "$CONFIG_FILE"
  '';
}
