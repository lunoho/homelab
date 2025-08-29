# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # ===================
  # BOOT & SYSTEM
  # ===================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  system.stateVersion = "25.05"; # do *not* change this

  # ===================
  # BASIC SETTINGS
  # ===================
  time.timeZone = "America/Denver";
  networking.hostName = "floe";

  # ===================
  # USERS
  # ===================
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKxoU5gbppBGpY9EZ7gydyVAdj0n3CXEilryavxiHbxe"
    ];
  };

  # ===================
  # NETWORKING & FIREWALL
  # ===================
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      22   # SSH
      80   # HTTP (for Let's Encrypt challenges and web services)
      443  # HTTPS
    ];

    allowedUDPPorts = [
      53   # DNS (Pi-hole)
    ];

    allowedTCPPortRanges = [
      # Docker container port mappings
      { from = 8000; to = 8999; }
    ];

    # Reject packets instead of dropping for better performance
    rejectPackets = true;

    extraCommands = ''
      # Allow established connections
      iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

      # Allow loopback
      iptables -A INPUT -i lo -j ACCEPT

      # Drop invalid packets
      iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

      # Log dropped packets (limit to prevent log spam)
      iptables -A INPUT -j LOG --log-prefix "iptables-dropped: " --log-level 4 -m limit --limit 5/min --limit-burst 10
    '';
  };

  # ===================
  # SERVICES
  # ===================
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;

      MaxAuthTries = 3;
      MaxSessions = 2;
      ClientAliveInterval = 3600; # 1 hour
      ClientAliveCountMax = 2;

      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = false;
      GatewayPorts = "no";
      PermitTunnel = "no";
    };
    ports = [ 22 ];
  };

  services.fail2ban = {
    enable = true;
    maxretry = 3;
    ignoreIP = [
      # Whitelist local networks
      "127.0.0.0/8"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];
    bantime = "1h";
    bantime-increment = {
      enable = true;
      rndtime = "8m";
      maxtime = "48h";
      factor = "2";
    };
    jails.sshd.enabled = true;
  };

  services.printing.enable = true;

  services.journald.extraConfig = ''
    Storage=persistent
    MaxRetentionSec=30d
  '';

  # ===================
  # VIRTUALISATION
  # ===================
  virtualisation.docker.enable = true;

  # ===================
  # PROGRAMS
  # ===================
  programs.mtr.enable = true;

  # ===================
  # PACKAGES
  # ===================
  environment.systemPackages = with pkgs; [
    neovim git nano tmux screen

    # Network & System Tools
    curl wget htop btop tree unzip rsync
    nmap dig tcpdump lsof netcat-gnu
    iperf3 speedtest-cli wireguard-tools

    # File & Archive Tools
    zip unzip tar gzip p7zip

    # Monitoring & Debugging
    iotop nethogs bandwhich
    strace ltrace mtr

    # Utilities
    jq yq-go fd ripgrep bat exa
    ncdu duf

    # Hardware Info
    lshw pciutils usbutils dmidecode
    smartmontools hdparm

    # Scripting Langs
    python3 nodejs
  ];

  # ===================
  # SYSTEM MANAGEMENT
  # ===================
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";  # Run at 4 AM daily
    allowReboot = true;
    channel = "https://nixos.org/channels/nixos-24.11";  # Stable channel
    flags = [
      "--upgrade-all"
      "--no-build-output"  # Reduce log spam
    ];
  };

  # ===================
  # NIX SETTINGS
  # ===================
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.auto-optimise-store = true;
}