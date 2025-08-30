#!/usr/bin/env bash

# Linode DDNS Updater Script
# Updates A record when public IP changes

set -euo pipefail

# Configuration (will be replaced by NixOS systemd environment)
DOMAIN_ID="${LINODE_DOMAIN_ID}"
RECORD_ID="${LINODE_RECORD_ID}"
API_TOKEN="${LINODE_API_TOKEN}"
DOMAIN_NAME="${DOMAIN_NAME}"

# API endpoints
LINODE_API="https://api.linode.com/v4"
IP_CHECK_URL="https://ipv4.icanhazip.com"

# Logging
LOG_TAG="ddns-update"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LOG_TAG] $1" >&2
}

error() {
    log "ERROR: $1"
    exit 1
}

# Get current public IP
get_public_ip() {
    curl -s --max-time 10 "$IP_CHECK_URL" | tr -d '\n\r' || {
        error "Failed to get public IP from $IP_CHECK_URL"
    }
}

# Get current DNS record IP
get_dns_ip() {
    curl -s --max-time 10 \
        -H "Authorization: Bearer $API_TOKEN" \
        "$LINODE_API/domains/$DOMAIN_ID/records/$RECORD_ID" | \
        jq -r '.target' || {
            error "Failed to get current DNS record"
        }
}

# Update DNS record
update_dns_record() {
    local new_ip="$1"

    curl -s --max-time 30 \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -X PUT \
        -d "{\"target\": \"$new_ip\", \"ttl_sec\": 300}" \
        "$LINODE_API/domains/$DOMAIN_ID/records/$RECORD_ID" >/dev/null || {
            error "Failed to update DNS record"
        }
}

# Validate IP format
is_valid_ip() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -ra ADDR <<< "$ip"
        for i in "${ADDR[@]}"; do
            if [[ $i -gt 255 ]] || [[ $i -lt 0 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Main execution
main() {
    log "Starting DDNS update check for $DOMAIN_NAME"

    # Validate required environment variables
    if [[ -z "${API_TOKEN:-}" ]]; then
        error "LINODE_API_TOKEN environment variable is required"
    fi

    # Get current IPs
    log "Getting current public IP..."
    current_ip=$(get_public_ip)

    if ! is_valid_ip "$current_ip"; then
        error "Invalid public IP format: $current_ip"
    fi

    log "Current public IP: $current_ip"

    log "Getting current DNS record..."
    dns_ip=$(get_dns_ip)

    if [[ "$dns_ip" == "null" ]] || [[ -z "$dns_ip" ]]; then
        error "Failed to retrieve DNS record or record not found"
    fi

    log "Current DNS IP: $dns_ip"

    # Compare and update if different
    if [[ "$current_ip" != "$dns_ip" ]]; then
        log "IP changed from $dns_ip to $current_ip - updating DNS record..."
        update_dns_record "$current_ip"
        log "DNS record updated successfully"

        # Verify the update
        sleep 2
        new_dns_ip=$(get_dns_ip)
        if [[ "$new_dns_ip" == "$current_ip" ]]; then
            log "DNS update verified successfully"
        else
            error "DNS update verification failed: expected $current_ip, got $new_dns_ip"
        fi
    else
        log "IP unchanged - no update needed"
    fi

    log "DDNS update check completed"
}

# Run main function
main "$@"