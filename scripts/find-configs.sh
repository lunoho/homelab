#!/usr/bin/env bash
# Find where services actually store their configs

echo "Looking for service config files..."
echo ""

echo "Sonarr:"
sudo find /var/lib -name "*config.xml" -path "*/sonarr/*" 2>/dev/null || echo "  Not found in /var/lib"
echo ""

echo "Radarr:"
sudo find /var/lib -name "*config.xml" -path "*/radarr/*" 2>/dev/null || echo "  Not found in /var/lib"
echo ""

echo "Prowlarr:"
sudo find /var/lib -name "*config.xml" -path "*/prowlarr/*" 2>/dev/null || echo "  Not found in /var/lib"
echo ""

echo "Bazarr:"
sudo find /var/lib -name "*config.xml" -path "*/bazarr/*" 2>/dev/null || echo "  Not found in /var/lib"
sudo find /var/lib -name "config.ini" -path "*/bazarr/*" 2>/dev/null || echo "  No config.ini either"
echo ""

echo "SABnzbd:"
sudo find /var/lib -name "*.ini" -path "*/sabnzbd/*" 2>/dev/null || echo "  Not found in /var/lib"
echo ""

echo "Jellyseerr:"
sudo find /var/lib -name "*.json" -path "*/jellyseerr/*" 2>/dev/null || echo "  Not found in /var/lib"
echo ""

echo "All service state directories:"
ls -la /var/lib/ | grep -E "(sonarr|radarr|prowlarr|bazarr|sabnzbd|jellyseerr|jellyfin)"
