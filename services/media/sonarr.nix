{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in
{
  # ===================
  # SONARR - TV SERIES MANAGEMENT
  # ===================

  services.sonarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
  };

  systemd.services.sonarr.preStart = ''
    CONFIG_DIR="/var/lib/sonarr/.config/NzbDrone"
    CONFIG_FILE="$CONFIG_DIR/config.xml"
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_FILE" ]; then
      cat > "$CONFIG_FILE" << 'EOF'
<Config>
  <BindAddress>*</BindAddress>
  <Port>8989</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>SONARR_API_KEY_PLACEHOLDER</ApiKey>
  <AuthenticationMethod>Forms</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Branch>main</Branch>
  <LogLevel>info</LogLevel>
  <SslCertPath></SslCertPath>
  <SslCertPassword></SslCertPassword>
  <UrlBase></UrlBase>
  <InstanceName>Sonarr</InstanceName>
</Config>
EOF
    fi

    # Always update API key
    ${pkgs.gnused}/bin/sed -i 's|<ApiKey>.*</ApiKey>|<ApiKey>${secrets.apiKeys.sonarr}</ApiKey>|' "$CONFIG_FILE"
  '';
}
