#!/usr/bin/env bash
set -e

cd /home/user/homelab

# Parse arguments
BRANCH=""
FORCE_REBUILD=false
SKIP_HOME_MANAGER=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--branch)
      BRANCH="$2"
      shift 2
      ;;
    -f|--force)
      FORCE_REBUILD=true
      shift
      ;;
    --skip-home-manager)
      SKIP_HOME_MANAGER=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -b, --branch BRANCH      Switch to and pull specific branch"
      echo "  -f, --force             Force rebuild even if no changes"
      echo "  --skip-home-manager     Skip home-manager update"
      echo "  -h, --help              Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "Current config version: $(git rev-parse --short HEAD) ($(git branch --show-current))"

# Switch branch if specified, or show interactive menu
if [ -n "$BRANCH" ]; then
  echo "Switching to branch: $BRANCH"
  git fetch origin
  if git show-ref --verify --quiet refs/heads/"$BRANCH"; then
    git checkout "$BRANCH"
  else
    git checkout -b "$BRANCH" origin/"$BRANCH"
  fi
else
  # Show interactive branch selection if multiple branches available
  git fetch origin --prune >/dev/null 2>&1
  CURRENT_BRANCH=$(git branch --show-current)
  AVAILABLE_BRANCHES=($(git branch -r --format='%(refname:short)' | sed 's/origin\///' | grep -vE 'HEAD|^origin$' | sort -u))

  if [ ${#AVAILABLE_BRANCHES[@]} -gt 1 ]; then
    echo "Available branches:"
    for i in "${!AVAILABLE_BRANCHES[@]}"; do
      if [ "${AVAILABLE_BRANCHES[$i]}" = "$CURRENT_BRANCH" ]; then
        echo "  $((i+1)). ${AVAILABLE_BRANCHES[$i]} (current)"
      else
        echo "  $((i+1)). ${AVAILABLE_BRANCHES[$i]}"
      fi
    done

    echo -n "Select branch to deploy (or press Enter for current): "
    read -r CHOICE

    if [ -n "$CHOICE" ] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le ${#AVAILABLE_BRANCHES[@]} ]; then
      SELECTED_BRANCH="${AVAILABLE_BRANCHES[$((CHOICE-1))]}"
      if [ "$SELECTED_BRANCH" != "$CURRENT_BRANCH" ]; then
        echo "Switching to branch: $SELECTED_BRANCH"
        if git show-ref --verify --quiet refs/heads/"$SELECTED_BRANCH"; then
          git checkout "$SELECTED_BRANCH"
        else
          git checkout -b "$SELECTED_BRANCH" origin/"$SELECTED_BRANCH"
        fi
      fi
    fi
  fi
fi

# Check for updates and clean up stale branches
git fetch --prune
CURRENT=$(git rev-parse HEAD)
UPSTREAM=$(git rev-parse @{u} 2>/dev/null || git rev-parse origin/$(git branch --show-current))

if [ "$CURRENT" != "$UPSTREAM" ] || [ "$FORCE_REBUILD" = true ]; then
  if [ "$CURRENT" != "$UPSTREAM" ]; then
    echo "Updates available, pulling..."
    git pull
  else
    echo "Force rebuild requested..."
  fi

  echo "Rebuilding NixOS..."

  # Check if secrets.nix exists in home directory
  if [ ! -f ~/secrets.nix ]; then
    echo "ERROR: ~/secrets.nix not found!"
    echo "Copy the example and customize it:"
    echo "  cp $(pwd)/secrets.nix.example ~/secrets.nix"
    exit 1
  fi

  sudo nixos-rebuild switch
  echo "Updated to: $(git rev-parse --short HEAD) ($(git branch --show-current))"

  # Restart media services to apply API key changes from secrets.nix
  echo ""
  echo "Restarting media services to apply any secrets changes..."
  sudo systemctl restart sonarr radarr prowlarr bazarr sabnzbd jellyseerr homepage-dashboard
  echo "✅ Services restarted"
else
  echo "Already up to date!"
fi

# ===================
# HOME MANAGER UPDATE
# ===================
if [ "$SKIP_HOME_MANAGER" = false ]; then
  echo ""
  echo "Updating home-manager configuration..."

  if [ -d ~/.config/nix-config ]; then
    cd ~/.config/nix-config

    HM_CURRENT=$(git rev-parse --short HEAD)
    echo "Current home-manager config: $HM_CURRENT ($(git branch --show-current))"

    # Update home-manager repo
    git fetch origin
    git pull || echo "Home-manager repo already up to date"

    HM_NEW=$(git rev-parse --short HEAD)

    if [ "$HM_CURRENT" != "$HM_NEW" ] || [ "$FORCE_REBUILD" = true ]; then
      echo "Applying home-manager configuration..."
      nix run home-manager/master -- switch --flake .#user@floe
      echo "Home-manager updated to: $HM_NEW"
    else
      echo "Home-manager already up to date!"
    fi
  else
    echo "WARNING: ~/.config/nix-config not found, skipping home-manager update"
    echo "Clone it with: git clone git@github.com:lunoho/homemanager.git ~/.config/nix-config"
  fi
fi

echo ""
echo "Rebuild complete!"
