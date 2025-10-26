#!/usr/bin/env bash
# Debug Bazarr and Jellyseerr issues

echo "==================================="
echo "Debugging Bazarr & Jellyseerr"
echo "==================================="
echo ""

# Check Bazarr
echo "🔍 Bazarr Status:"
sudo systemctl status bazarr --no-pager -l | head -20
echo ""

echo "📂 Bazarr config files:"
sudo find /var/lib/bazarr -type f -name "*.ini" -o -name "*.xml" 2>/dev/null
echo ""

echo "🔑 Bazarr API key in config:"
if [ -f /var/lib/bazarr/config/config.ini ]; then
    sudo grep -E "^apikey|^api_key" /var/lib/bazarr/config/config.ini || echo "  No apikey found in config.ini"
else
    echo "  config.ini not found"
fi
echo ""

echo "📝 Bazarr logs (last 20 lines):"
sudo journalctl -u bazarr -n 20 --no-pager
echo ""

echo "========================================="
echo ""

# Check Jellyseerr
echo "🔍 Jellyseerr Status:"
sudo systemctl status jellyseerr --no-pager -l | head -20
echo ""

echo "📂 Jellyseerr settings file:"
ls -la /var/lib/private/jellyseerr/settings.json 2>/dev/null || echo "  Not found"
echo ""

echo "🔑 Jellyseerr API key in config:"
if [ -f /var/lib/private/jellyseerr/settings.json ]; then
    sudo jq -r '.main.apiKey // "NOT_SET"' /var/lib/private/jellyseerr/settings.json
else
    echo "  settings.json not found"
fi
echo ""

echo "📝 Jellyseerr logs (last 20 lines):"
sudo journalctl -u jellyseerr -n 20 --no-pager
echo ""

# Check secrets.nix values
echo "🔐 Expected API keys from secrets.nix:"
echo "  Bazarr:    $(nix eval --raw --impure --expr '(import /home/user/secrets.nix).apiKeys.bazarr')"
echo "  Jellyseerr: $(nix eval --raw --impure --expr '(import /home/user/secrets.nix).apiKeys.jellyseerr')"
