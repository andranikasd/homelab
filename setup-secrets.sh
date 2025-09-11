#!/bin/bash

# Secret Setup Script for Edge Stack
# This script helps you create and encrypt all required secrets

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if SOPS is installed
check_sops() {
    if ! command -v sops &> /dev/null; then
        log_error "SOPS is not installed. Please install SOPS first."
        exit 1
    fi
}

# Create secret file
create_secret() {
    local secret_name="$1"
    local secret_description="$2"
    local secret_file="secrets/${secret_name}.encrypted"
    
    log_info "Setting up: $secret_description"
    echo "Please enter the value for $secret_description:"
    read -s secret_value
    
    if [[ -z "$secret_value" ]]; then
        log_warning "No value provided for $secret_name, using placeholder"
        secret_value="placeholder-${secret_name}"
    fi
    
    # Create temporary file with secret
    echo "$secret_value" > "/tmp/${secret_name}.tmp"
    
    # Encrypt with SOPS
    sops -e "/tmp/${secret_name}.tmp" > "$secret_file"
    
    # Clean up
    rm "/tmp/${secret_name}.tmp"
    
    log_success "$secret_description configured"
}

# Main function
main() {
    log_info "🔐 Setting up Edge Stack Secrets"
    echo
    
    check_sops
    
    log_info "This script will help you set up all required secrets for the Edge Stack."
    echo
    log_warning "You'll need:"
    echo "  • Google OAuth2 Client ID and Secret"
    echo "  • CrowdSec API Key"
    echo "  • SSL certificates (optional - Let's Encrypt will be used)"
    echo
    
    read -p "Press Enter to continue..."
    echo
    
    # Create secrets directory if it doesn't exist
    mkdir -p secrets
    
    # Set up each secret
    create_secret "traefik_cert" "Traefik SSL Certificate (use 'placeholder' for Let's Encrypt)"
    create_secret "traefik_key" "Traefik SSL Private Key (use 'placeholder' for Let's Encrypt)"
    create_secret "oauth2_proxy_client_id" "OAuth2 Proxy Client ID"
    create_secret "oauth2_proxy_client_secret" "OAuth2 Proxy Client Secret"
    create_secret "crowdsec_api_key" "CrowdSec API Key"
    
    echo
    log_success "🎉 All secrets have been configured and encrypted!"
    echo
    log_info "Next steps:"
    echo "  1. Run: ./deploy.sh"
    echo "  2. Access Portainer at: https://mxnq.net:9443"
    echo "  3. Configure GitOps in Portainer"
    echo
}

# Run main function
main "$@"
