{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in
{
  # ===================
  # PROWLARR - INDEXER MANAGEMENT
  # ===================

  services.prowlarr = {
    enable = true;
    openFirewall = false;
  };

  systemd.services.prowlarr.preStart = ''
    CONFIG_DIR="/var/lib/private/prowlarr"
    CONFIG_FILE="$CONFIG_DIR/config.xml"
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_FILE" ]; then
      cat > "$CONFIG_FILE" << 'EOF'
<Config>
  <BindAddress>*</BindAddress>
  <Port>9696</Port>
  <SslPort>6969</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>PROWLARR_API_KEY_PLACEHOLDER</ApiKey>
  <AuthenticationMethod>Forms</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Branch>master</Branch>
  <LogLevel>info</LogLevel>
  <SslCertPath></SslCertPath>
  <SslCertPassword></SslCertPassword>
  <UrlBase></UrlBase>
  <InstanceName>Prowlarr</InstanceName>
</Config>
EOF
    fi

    # Always update API key
    ${pkgs.gnused}/bin/sed -i 's|<ApiKey>.*</ApiKey>|<ApiKey>${secrets.apiKeys.prowlarr}</ApiKey>|' "$CONFIG_FILE"
  '';
}
