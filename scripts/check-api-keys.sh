#!/usr/bin/env bash
# Check if service API keys match secrets.nix

echo "==================================="
echo "API Key Verification"
echo "==================================="
echo ""

# Load secrets
SECRETS_FILE="/home/user/secrets.nix"
if [ ! -f "$SECRETS_FILE" ]; then
    echo "❌ Error: $SECRETS_FILE not found!"
    exit 1
fi

echo "📋 Comparing API keys in service configs vs secrets.nix"
echo ""

# Helper to extract key from secrets.nix
get_secret_key() {
    nix eval --raw --impure --expr "(import $SECRETS_FILE).apiKeys.$1" 2>/dev/null
}

# Check Sonarr
echo "🔍 Sonarr:"
SECRET_KEY=$(get_secret_key sonarr)
if [ -f /var/lib/sonarr/config.xml ]; then
    CONFIG_KEY=$(grep '<ApiKey>' /var/lib/sonarr/config.xml | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')
    echo "  secrets.nix: $SECRET_KEY"
    echo "  config.xml:  $CONFIG_KEY"
    [ "$SECRET_KEY" = "$CONFIG_KEY" ] && echo "  ✅ Match" || echo "  ❌ Mismatch"
else
    echo "  ⚠️  Config file not found"
fi
echo ""

# Check Radarr
echo "🔍 Radarr:"
SECRET_KEY=$(get_secret_key radarr)
if [ -f /var/lib/radarr/config.xml ]; then
    CONFIG_KEY=$(grep '<ApiKey>' /var/lib/radarr/config.xml | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')
    echo "  secrets.nix: $SECRET_KEY"
    echo "  config.xml:  $CONFIG_KEY"
    [ "$SECRET_KEY" = "$CONFIG_KEY" ] && echo "  ✅ Match" || echo "  ❌ Mismatch"
else
    echo "  ⚠️  Config file not found"
fi
echo ""

# Check Prowlarr
echo "🔍 Prowlarr:"
SECRET_KEY=$(get_secret_key prowlarr)
if [ -f /var/lib/prowlarr/config.xml ]; then
    CONFIG_KEY=$(grep '<ApiKey>' /var/lib/prowlarr/config.xml | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')
    echo "  secrets.nix: $SECRET_KEY"
    echo "  config.xml:  $CONFIG_KEY"
    [ "$SECRET_KEY" = "$CONFIG_KEY" ] && echo "  ✅ Match" || echo "  ❌ Mismatch"
else
    echo "  ⚠️  Config file not found"
fi
echo ""

# Check Bazarr
echo "🔍 Bazarr:"
SECRET_KEY=$(get_secret_key bazarr)
if [ -f /var/lib/bazarr/config.xml ]; then
    CONFIG_KEY=$(grep '<ApiKey>' /var/lib/bazarr/config.xml | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')
    echo "  secrets.nix: $SECRET_KEY"
    echo "  config.xml:  $CONFIG_KEY"
    [ "$SECRET_KEY" = "$CONFIG_KEY" ] && echo "  ✅ Match" || echo "  ❌ Mismatch"
else
    echo "  ⚠️  Config file not found"
fi
echo ""

# Check SABnzbd
echo "🔍 SABnzbd:"
SECRET_KEY=$(get_secret_key sabnzbd)
if [ -f /var/lib/sabnzbd/sabnzbd.ini ]; then
    CONFIG_KEY=$(grep '^api_key = ' /var/lib/sabnzbd/sabnzbd.ini | sed 's/^api_key = //')
    echo "  secrets.nix: $SECRET_KEY"
    echo "  sabnzbd.ini: $CONFIG_KEY"
    [ "$SECRET_KEY" = "$CONFIG_KEY" ] && echo "  ✅ Match" || echo "  ❌ Mismatch"
else
    echo "  ⚠️  Config file not found"
fi
echo ""

# Check Jellyseerr
echo "🔍 Jellyseerr:"
SECRET_KEY=$(get_secret_key jellyseerr)
if [ -f /var/lib/jellyseerr/settings.json ]; then
    CONFIG_KEY=$(jq -r '.main.apiKey // "not_set"' /var/lib/jellyseerr/settings.json)
    echo "  secrets.nix:    $SECRET_KEY"
    echo "  settings.json:  $CONFIG_KEY"
    [ "$SECRET_KEY" = "$CONFIG_KEY" ] && echo "  ✅ Match" || echo "  ❌ Mismatch"
else
    echo "  ⚠️  Config file not found"
fi
echo ""

echo "💡 If any keys mismatch, restart the services:"
echo "   sudo systemctl restart sonarr radarr prowlarr bazarr sabnzbd jellyseerr homepage-dashboard"
