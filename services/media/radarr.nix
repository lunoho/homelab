{ config, lib, pkgs, ... }:

let
  secrets = import /home/user/secrets.nix;
in
{
  # ===================
  # RADARR - MOVIE MANAGEMENT
  # ===================

  services.radarr = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
  };

  systemd.services.radarr.preStart = ''
    CONFIG_DIR="/var/lib/radarr/.config/Radarr"
    CONFIG_FILE="$CONFIG_DIR/config.xml"
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_FILE" ]; then
      cat > "$CONFIG_FILE" << 'EOF'
<Config>
  <BindAddress>*</BindAddress>
  <Port>7878</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>RADARR_API_KEY_PLACEHOLDER</ApiKey>
  <AuthenticationMethod>Forms</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Branch>master</Branch>
  <LogLevel>info</LogLevel>
  <SslCertPath></SslCertPath>
  <SslCertPassword></SslCertPassword>
  <UrlBase></UrlBase>
  <InstanceName>Radarr</InstanceName>
</Config>
EOF
    fi

    # Always update API key
    ${pkgs.gnused}/bin/sed -i 's|<ApiKey>.*</ApiKey>|<ApiKey>${secrets.apiKeys.radarr}</ApiKey>|' "$CONFIG_FILE"
  '';
}
