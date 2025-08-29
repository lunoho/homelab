#!/usr/bin/env bash
set -e

cd /home/user/homelab
echo "Current config version: $(git rev-parse --short HEAD)"

git fetch
if [ $(git rev-parse HEAD) != $(git rev-parse @{u}) ]; then
  echo "Updates available, pulling..."
  git pull
  echo "Rebuilding NixOS..."
  sudo nixos-rebuild switch
  echo "Updated to: $(git rev-parse --short HEAD)"
else
  echo "Already up to date!"
fi
