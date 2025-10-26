{ config, pkgs, lib, ... }:

{
  # Home Manager is managed via user's nix-config flake
  # This module just ensures the user has necessary packages to manage it

  environment.systemPackages = with pkgs; [
    git  # Required for flakes
    # home-manager will be available via the flake
  ];

  # Ensure user can access their home-manager flake config
  # The flake should be cloned to /home/user/.config/nix-config

  # Optional: Create a systemd user service to auto-apply home-manager on login
  # Disabled by default - user can manually run: home-manager switch --flake ~/.config/nix-config#user@homelab

  # systemd.user.services.home-manager-auto-apply = {
  #   description = "Auto-apply Home Manager configuration";
  #   wantedBy = [ "default.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.bash}/bin/bash -c 'cd ~/.config/nix-config && ${pkgs.home-manager}/bin/home-manager switch --flake .#user@homelab'";
  #   };
  # };
}
