#!/usr/bin/env bash
# Extract config files from media services after web UI setup
# Run this AFTER completing initial setup for each service

set -e

OUTPUT_DIR="$HOME/config-templates"
mkdir -p "$OUTPUT_DIR"

echo "==================================="
echo "Extracting Media Service Configs"
echo "==================================="
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""

# Sonarr
if sudo test -f /var/lib/sonarr/.config/NzbDrone/config.xml; then
    echo "✓ Extracting Sonarr config..."
    sudo cat /var/lib/sonarr/.config/NzbDrone/config.xml > "$OUTPUT_DIR/sonarr-config.xml"
else
    echo "✗ Sonarr config not found (setup not complete?)"
fi

# Radarr
if sudo test -f /var/lib/radarr/.config/Radarr/config.xml; then
    echo "✓ Extracting Radarr config..."
    sudo cat /var/lib/radarr/.config/Radarr/config.xml > "$OUTPUT_DIR/radarr-config.xml"
else
    echo "✗ Radarr config not found (setup not complete?)"
fi

# Prowlarr
if sudo test -f /var/lib/private/prowlarr/config.xml; then
    echo "✓ Extracting Prowlarr config..."
    sudo cat /var/lib/private/prowlarr/config.xml > "$OUTPUT_DIR/prowlarr-config.xml"
else
    echo "✗ Prowlarr config not found (setup not complete?)"
fi

# Bazarr
if sudo test -f /var/lib/bazarr/config/config.yaml; then
    echo "✓ Extracting Bazarr config..."
    sudo cat /var/lib/bazarr/config/config.yaml > "$OUTPUT_DIR/bazarr-config.yaml"
else
    echo "✗ Bazarr config not found (setup not complete?)"
fi

# SABnzbd
if sudo test -f /var/lib/sabnzbd/sabnzbd.ini; then
    echo "✓ Extracting SABnzbd config..."
    sudo cat /var/lib/sabnzbd/sabnzbd.ini > "$OUTPUT_DIR/sabnzbd.ini"
else
    echo "✗ SABnzbd config not found (setup not complete?)"
fi

# Jellyseerr
if sudo test -f /var/lib/private/jellyseerr/settings.json; then
    echo "✓ Extracting Jellyseerr config..."
    sudo cat /var/lib/private/jellyseerr/settings.json > "$OUTPUT_DIR/jellyseerr-settings.json"
else
    echo "✗ Jellyseerr config not found (setup not complete?)"
fi

echo ""
echo "==================================="
echo "Done! Config templates saved to:"
echo "$OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "1. Review the extracted configs"
echo "2. Share them so we can create declarative templates"
echo "3. Templatize API keys and other secrets"
echo "==================================="
