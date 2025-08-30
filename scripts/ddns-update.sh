#!/usr/bin/env bash

# Linode DDNS Updater Script
# Auto-discovers and updates A records by subdomain name
# Creates missing records automatically

set -euo pipefail

# Configuration (will be replaced by NixOS systemd environment)
API_TOKEN="${LINODE_API_TOKEN}"
DOMAIN_NAME="${DOMAIN_NAME}"
SUBDOMAINS="${LINODE_SUBDOMAINS}"  # JSON array of subdomain names

# Domain ID will be discovered via API
DOMAIN_ID=""

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

# Get domain ID by domain name
get_domain_id() {
    local domain_name="$1"
    
    log "Looking up domain ID for $domain_name"
    
    local response=$(curl -s --max-time 10 \
        -H "Authorization: Bearer $API_TOKEN" \
        "$LINODE_API/domains" 2>/dev/null)
    
    local curl_exit=$?
    if [[ $curl_exit -ne 0 ]]; then
        error "curl failed with exit code $curl_exit when looking up domain ID"
    fi
    
    # Check if response is valid JSON
    if ! echo "$response" | jq empty 2>/dev/null; then
        error "Invalid JSON response when looking up domain: ${response:0:100}..."
    fi
    
    # Check for API errors
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
        error "API error when looking up domain: $(echo "$response" | jq -r '.errors[0].reason // "Unknown error"')"
    fi
    
    # Find domain by exact name match
    local domain_id=$(echo "$response" | jq --arg domain "$domain_name" -r '
        .data[]? | select(.domain == $domain) | .id
    ' 2>/dev/null | head -n 1)
    
    if [[ -z "$domain_id" || "$domain_id" == "null" ]]; then
        error "Domain '$domain_name' not found in Linode account"
    fi
    
    log "Found domain ID: $domain_id for $domain_name"
    echo "$domain_id"
}

# Get current public IP
get_public_ip() {
    curl -s --max-time 10 "$IP_CHECK_URL" | tr -d '\n\r' || {
        error "Failed to get public IP from $IP_CHECK_URL"
    }
}

# Find DNS record by subdomain name
find_dns_record() {
    local subdomain="$1"
    local search_name="$subdomain"
    
    # Handle root domain (empty subdomain)
    if [[ "$subdomain" == "root" || "$subdomain" == "@" || "$subdomain" == "" ]]; then
        search_name=""
    fi
    
    log "Searching for DNS record: '$search_name'"
    
    local response=$(curl -s --max-time 10 \
        -H "Authorization: Bearer $API_TOKEN" \
        "$LINODE_API/domains/$DOMAIN_ID/records?type=A" 2>/dev/null)
    
    local curl_exit=$?
    if [[ $curl_exit -ne 0 ]]; then
        log "curl failed with exit code $curl_exit for $subdomain"
        echo ""
        return
    fi
    
    # Check if response is valid JSON
    if ! echo "$response" | jq empty 2>/dev/null; then
        log "Invalid JSON response for $subdomain: ${response:0:100}..."
        echo ""
        return
    fi
    
    # Check for API errors
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
        log "API error for $subdomain: $(echo "$response" | jq -r '.errors[0].reason // "Unknown error"')"
        echo ""
        return
    fi
    
    # Filter records by exact name match
    local found_record=$(echo "$response" | jq --arg name "$search_name" -r '
        .data[]? | select(.name == $name and .type == "A")
    ' | jq -s '.[0] // empty' 2>/dev/null)
    
    echo "$found_record"
}

# Create new DNS A record
create_dns_record() {
    local subdomain="$1"
    local ip="$2"
    local record_name="$subdomain"
    
    # Handle root domain
    if [[ "$subdomain" == "root" || "$subdomain" == "@" || "$subdomain" == "" ]]; then
        record_name=""
    fi
    
    local response=$(curl -s --max-time 30 \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "{\"type\": \"A\", \"name\": \"$record_name\", \"target\": \"$ip\", \"ttl_sec\": 300}" \
        "$LINODE_API/domains/$DOMAIN_ID/records" || {
            error "Failed to create DNS A record for $subdomain"
        })
    
    # Return the new record ID
    echo "$response" | jq -r '.id'
}

# Update existing DNS record
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
    
    if [[ -z "${DOMAIN_NAME:-}" ]]; then
        error "DOMAIN_NAME environment variable is required"
    fi
    
    if [[ -z "${SUBDOMAINS:-}" ]]; then
        error "LINODE_SUBDOMAINS environment variable is required"
    fi
    
    # Discover domain ID
    DOMAIN_ID=$(get_domain_id "$DOMAIN_NAME")
    
    # Get current public IP
    log "Getting current public IP..."
    current_ip=$(get_public_ip)
    
    if ! is_valid_ip "$current_ip"; then
        error "Invalid public IP format: $current_ip"
    fi
    
    log "Current public IP: $current_ip"
    
    # Parse subdomains JSON and process each subdomain
    echo "$SUBDOMAINS" | jq -r '.[]' | while IFS= read -r subdomain; do
        log "Processing subdomain: $subdomain"
        
        # Find existing record
        existing_record=$(find_dns_record "$subdomain")
        
        if [[ -n "$existing_record" ]]; then
            # Record exists - check if update needed
            record_id=$(echo "$existing_record" | jq -r '.id')
            current_dns_ip=$(echo "$existing_record" | jq -r '.target')
            
            log "Found existing record for $subdomain (ID: $record_id) with IP: $current_dns_ip"
            
            if [[ "$current_ip" != "$current_dns_ip" ]]; then
                log "IP changed for $subdomain from $current_dns_ip to $current_ip - updating..."
                update_dns_record "$record_id" "$current_ip"
                log "DNS record updated successfully for $subdomain"
                
                # Verify the update
                sleep 2
                updated_record=$(find_dns_record "$subdomain")
                new_dns_ip=$(echo "$updated_record" | jq -r '.target')
                if [[ "$new_dns_ip" == "$current_ip" ]]; then
                    log "DNS update verified successfully for $subdomain"
                else
                    error "DNS update verification failed for $subdomain: expected $current_ip, got $new_dns_ip"
                fi
            else
                log "IP unchanged for $subdomain - no update needed"
            fi
        else
            # Record doesn't exist - create it
            log "No existing A record found for $subdomain - creating new record..."
            new_record_id=$(create_dns_record "$subdomain" "$current_ip")
            
            if [[ -n "$new_record_id" ]] && [[ "$new_record_id" != "null" ]]; then
                log "DNS A record created successfully for $subdomain (ID: $new_record_id)"
                
                # Verify creation
                sleep 2
                created_record=$(find_dns_record "$subdomain")
                if [[ -n "$created_record" ]]; then
                    created_ip=$(echo "$created_record" | jq -r '.target')
                    if [[ "$created_ip" == "$current_ip" ]]; then
                        log "DNS record creation verified successfully for $subdomain"
                    else
                        error "DNS record creation verification failed for $subdomain: expected $current_ip, got $created_ip"
                    fi
                else
                    error "Failed to verify DNS record creation for $subdomain"
                fi
            else
                error "Failed to create DNS A record for $subdomain"
            fi
        fi
    done
    
    log "DDNS update check completed"
}

# Run main function
main "$@"