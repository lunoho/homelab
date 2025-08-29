# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  time.timeZone = "America/Denver";
  networking.hostName = "floe";
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKxoU5gbppBGpY9EZ7gydyVAdj0n3CXEilryavxiHbxe"
    ];
  };

  services.openssh.enable = true;
  services.printing.enable = true;
  virtualisation.docker.enable = true;

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

  programs.mtr.enable = true;

  # do *not* change this
  # https://nixos.org/manual/nixos/stable/#sec-upgrading
  system.stateVersion = "25.05"; # yes, I read the comment
}

