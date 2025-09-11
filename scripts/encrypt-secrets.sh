#!/bin/bash

# Secret encryption helper script
# This script helps encrypt secrets using SOPS

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

# Check if age key exists
check_age_key() {
    local age_key_file="$HOME/.config/sops/age/keys.txt"
    
    if [[ ! -f "$age_key_file" ]]; then
        log_error "Age key not found at $age_key_file"
        log_info "Please run: age-keygen -o $age_key_file"
        exit 1
    fi
}

# Encrypt a single file
encrypt_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "File $file_path not found"
        return 1
    fi
    
    log_info "Encrypting $file_path..."
    sops -e -i "$file_path"
    log_success "$file_path encrypted"
}

# Decrypt a single file
decrypt_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "File $file_path not found"
        return 1
    fi
    
    log_info "Decrypting $file_path..."
    sops -d -i "$file_path"
    log_success "$file_path decrypted"
}

# Encrypt all secrets
encrypt_all() {
    log_info "Encrypting all secrets..."
    
    local secrets_dir="secrets"
    local encrypted_files=(
        "traefik_cert.encrypted"
        "traefik_key.encrypted"
        "oauth2_proxy_client_id.encrypted"
        "oauth2_proxy_client_secret.encrypted"
        "crowdsec_api_key.encrypted"
    )
    
    for file in "${encrypted_files[@]}"; do
        local file_path="$secrets_dir/$file"
        if [[ -f "$file_path" ]]; then
            encrypt_file "$file_path"
        else
            log_warning "$file_path not found, skipping..."
        fi
    done
}

# Decrypt all secrets
decrypt_all() {
    log_info "Decrypting all secrets..."
    
    local secrets_dir="secrets"
    local encrypted_files=(
        "traefik_cert.encrypted"
        "traefik_key.encrypted"
        "oauth2_proxy_client_id.encrypted"
        "oauth2_proxy_client_secret.encrypted"
        "crowdsec_api_key.encrypted"
    )
    
    for file in "${encrypted_files[@]}"; do
        local file_path="$secrets_dir/$file"
        if [[ -f "$file_path" ]]; then
            decrypt_file "$file_path"
        else
            log_warning "$file_path not found, skipping..."
        fi
    done
}

# Show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [FILE]"
    echo
    echo "Commands:"
    echo "  encrypt [FILE]  Encrypt a specific file or all secrets"
    echo "  decrypt [FILE]  Decrypt a specific file or all secrets"
    echo "  help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 encrypt                                    # Encrypt all secrets"
    echo "  $0 encrypt secrets/traefik_cert.encrypted    # Encrypt specific file"
    echo "  $0 decrypt                                    # Decrypt all secrets"
    echo "  $0 decrypt secrets/traefik_cert.encrypted     # Decrypt specific file"
}

# Main function
main() {
    check_sops
    check_age_key
    
    case "${1:-help}" in
        encrypt)
            if [[ -n "${2:-}" ]]; then
                encrypt_file "$2"
            else
                encrypt_all
            fi
            ;;
        decrypt)
            if [[ -n "${2:-}" ]]; then
                decrypt_file "$2"
            else
                decrypt_all
            fi
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
