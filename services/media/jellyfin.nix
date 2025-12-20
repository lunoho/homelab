{ config, lib, pkgs, ... }:

{
  # ===================
  # JELLYFIN MEDIA SERVER
  # ===================

  services.jellyfin = {
    enable = true;
    openFirewall = false;
    user = "media";
    group = "media";
  };

  # Configure Jellyfin to trust reverse proxy and local networks
  systemd.services.jellyfin.preStart = ''
    CONFIG_DIR="/var/lib/jellyfin/config"
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/network.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <KnownProxies>
    <string>127.0.0.1</string>
    <string>172.17.0.0/16</string>
  </KnownProxies>
  <EnableRemoteAccess>true</EnableRemoteAccess>
  <LocalNetworkSubnets>
    <string>192.168.0.0/16</string>
    <string>10.0.0.0/8</string>
    <string>172.16.0.0/12</string>
  </LocalNetworkSubnets>
</NetworkConfiguration>
EOF
  '';
}
