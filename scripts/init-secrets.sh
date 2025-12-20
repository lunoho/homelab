#!/usr/bin/env bash
# Initialize secrets.nix with auto-generated API keys
# This script should be run on the homelab server

set -e

SECRETS_FILE="/home/user/secrets.nix"
SECRETS_EXAMPLE="/home/user/homelab/secrets.nix.example"

echo "==================================="
echo "Secrets Initialization Script"
echo "==================================="
echo ""

# Check if secrets.nix already exists
if [ -f "$SECRETS_FILE" ]; then
    echo "⚠️  Warning: $SECRETS_FILE already exists!"
    echo ""
    read -p "Do you want to regenerate API keys? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting without changes."
        exit 0
    fi
    echo ""
    echo "Creating backup at ${SECRETS_FILE}.backup"
    cp "$SECRETS_FILE" "${SECRETS_FILE}.backup"
fi

# Check if example file exists
if [ ! -f "$SECRETS_EXAMPLE" ]; then
    echo "❌ Error: $SECRETS_EXAMPLE not found!"
    echo "Make sure you're running this from the homelab server."
    exit 1
fi

echo "📝 Generating API keys..."
echo ""

# Generate random API keys
gen_key() {
    openssl rand -hex 32
}

SONARR_KEY=$(gen_key)
RADARR_KEY=$(gen_key)
PROWLARR_KEY=$(gen_key)
BAZARR_KEY=$(gen_key)
SABNZBD_KEY=$(gen_key)
JELLYFIN_KEY=$(gen_key)
JELLYSEERR_KEY=$(gen_key)

# Prompt for user-specific values
echo "Please provide the following information:"
echo ""
read -p "Your email address: " USER_EMAIL
read -p "Your domain (e.g., example.com): " USER_DOMAIN
read -p "Admin password: " -s ADMIN_PASSWORD
echo ""
read -p "Alert email address: " ALERT_EMAIL
read -p "Alert email password (app password): " -s ALERT_EMAIL_PASSWORD
echo ""
read -p "Linode API token (optional, press Enter to skip): " LINODE_TOKEN
echo ""

# Create secrets.nix file
cat > "$SECRETS_FILE" <<EOF
{
  email = "$USER_EMAIL";
  domain = "$USER_DOMAIN";
  # External subdomains exposed on the internet (managed with DDNS)
  externalSubdomains = [];

  adminPassword = "$ADMIN_PASSWORD";

  # Email alerting configuration (for Prometheus Alertmanager)
  alertEmail = "$ALERT_EMAIL";
  alertEmailPassword = "$ALERT_EMAIL_PASSWORD";

  # Linode API token with Domain:Read_Write permissions
  linode.apiToken = "$LINODE_TOKEN";

  # ==============================================
  # API KEYS (auto-generated)
  # ==============================================
  # These are declaratively injected into services

  apiKeys = {
    sonarr = "$SONARR_KEY";
    radarr = "$RADARR_KEY";
    prowlarr = "$PROWLARR_KEY";
    bazarr = "$BAZARR_KEY";
    sabnzbd = "$SABNZBD_KEY";
    jellyfin = "$JELLYFIN_KEY";  # Note: Also create this key in Jellyfin UI
    jellyseerr = "$JELLYSEERR_KEY";
  };
}
EOF

# Set proper permissions
chmod 600 "$SECRETS_FILE"

echo "✅ Secrets file created at $SECRETS_FILE"
echo ""
echo "Generated API keys:"
echo "  - Sonarr:     $SONARR_KEY"
echo "  - Radarr:     $RADARR_KEY"
echo "  - Prowlarr:   $PROWLARR_KEY"
echo "  - Bazarr:     $BAZARR_KEY"
echo "  - SABnzbd:    $SABNZBD_KEY"
echo "  - Jellyfin:   $JELLYFIN_KEY"
echo "  - Jellyseerr: $JELLYSEERR_KEY"
echo ""
echo "⚠️  IMPORTANT: For Jellyfin"
echo "   Jellyfin API keys must be created through the UI:"
echo "   1. Go to Jellyfin Dashboard → API Keys"
echo "   2. Create a new key named 'Homepage'"
echo "   3. Copy the generated key"
echo "   4. Update secrets.nix with: apiKeys.jellyfin = \"<your-key>\""
echo ""
echo "🚀 Next steps:"
echo "   1. Review $SECRETS_FILE and make any needed changes"
echo "   2. Run: cd /home/user/homelab && ./rebuild.sh"
echo "   3. After services start, create Jellyfin API key (see above)"
echo "   4. Update secrets.nix with Jellyfin key and rebuild again"
echo ""
echo "🎉 Done!"
