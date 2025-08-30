#!/usr/bin/env bash

# Linode DDNS Updater Script
# Updates multiple A records when public IP changes

set -euo pipefail

# Configuration (will be replaced by NixOS systemd environment)
DOMAIN_ID="${LINODE_DOMAIN_ID}"
API_TOKEN="${LINODE_API_TOKEN}"
DOMAIN_NAME="${DOMAIN_NAME}"
RECORDS="${LINODE_RECORDS}"  # JSON array of records

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
    local record_id="$1"
    curl -s --max-time 10 \
        -H "Authorization: Bearer $API_TOKEN" \
        "$LINODE_API/domains/$DOMAIN_ID/records/$record_id" | \
        jq -r '.target' || {
            error "Failed to get current DNS record for ID $record_id"
        }
}

# Update DNS record
update_dns_record() {
    local record_id="$1"
    local new_ip="$2"
    
    curl -s --max-time 30 \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -X PUT \
        -d "{\"target\": \"$new_ip\", \"ttl_sec\": 300}" \
        "$LINODE_API/domains/$DOMAIN_ID/records/$record_id" >/dev/null || {
            error "Failed to update DNS record ID $record_id"
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
    
    if [[ -z "${RECORDS:-}" ]]; then
        error "LINODE_RECORDS environment variable is required"
    fi
    
    # Get current public IP
    log "Getting current public IP..."
    current_ip=$(get_public_ip)
    
    if ! is_valid_ip "$current_ip"; then
        error "Invalid public IP format: $current_ip"
    fi
    
    log "Current public IP: $current_ip"
    
    # Parse records JSON and process each record
    echo "$RECORDS" | jq -r '.[] | @base64' | while IFS= read -r record; do
        # Decode record
        name=$(echo "$record" | base64 -d | jq -r '.name')
        id=$(echo "$record" | base64 -d | jq -r '.id')
        
        log "Processing record: $name (ID: $id)"
        
        # Get current DNS IP
        dns_ip=$(get_dns_ip "$id")
        
        if [[ "$dns_ip" == "null" ]] || [[ -z "$dns_ip" ]]; then
            error "Failed to retrieve DNS record for $name (ID: $id)"
        fi
        
        log "Current DNS IP for $name: $dns_ip"
        
        # Compare and update if different
        if [[ "$current_ip" != "$dns_ip" ]]; then
            log "IP changed for $name from $dns_ip to $current_ip - updating..."
            update_dns_record "$id" "$current_ip"
            log "DNS record updated successfully for $name"
            
            # Verify the update
            sleep 2
            new_dns_ip=$(get_dns_ip "$id")
            if [[ "$new_dns_ip" == "$current_ip" ]]; then
                log "DNS update verified successfully for $name"
            else
                error "DNS update verification failed for $name: expected $current_ip, got $new_dns_ip"
            fi
        else
            log "IP unchanged for $name - no update needed"
        fi
    done
    
    log "DDNS update check completed"
}

# Run main function
main "$@"