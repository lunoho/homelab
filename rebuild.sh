#!/usr/bin/env bash
set -e

cd /home/user/homelab

# Parse arguments
BRANCH=""
FORCE_REBUILD=false

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
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -b, --branch BRANCH    Switch to and pull specific branch"
      echo "  -f, --force           Force rebuild even if no changes"
      echo "  -h, --help            Show this help"
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
  git fetch origin >/dev/null 2>&1
  CURRENT_BRANCH=$(git branch --show-current)
  AVAILABLE_BRANCHES=($(git branch -r --format='%(refname:short)' | sed 's/origin\///' | grep -v HEAD | sort -u))
  
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

# Check for updates
git fetch
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
  
  # Check if secrets.nix exists
  if [ ! -f secrets.nix ]; then
    echo "ERROR: secrets.nix not found!"
    echo "Copy the example and customize it:"
    echo "  cp secrets.nix.example secrets.nix"
    echo "  # Then edit secrets.nix with your actual domain and email"
    exit 1
  fi
  
  sudo nixos-rebuild switch
  echo "Updated to: $(git rev-parse --short HEAD) ($(git branch --show-current))"
else
  echo "Already up to date!"
fi
