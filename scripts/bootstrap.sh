#!/bin/bash

# Edge Stack GitOps Bootstrap Script
# This script sets up the complete GitOps environment

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose plugin is not installed. Please install Docker Compose plugin first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if SOPS is installed
    if ! command -v sops &> /dev/null; then
        log_error "SOPS is not installed. Please install SOPS first."
        exit 1
    fi
    
    # Check if age is installed
    if ! command -v age &> /dev/null; then
        log_error "age is not installed. Please install age first."
        exit 1
    fi
    
    log_success "All prerequisites are installed"
}

# Generate age key if it doesn't exist
generate_age_key() {
    local age_key_file="$HOME/.config/sops/age/keys.txt"
    
    if [[ ! -f "$age_key_file" ]]; then
        log_info "Generating age key for SOPS encryption..."
        mkdir -p "$(dirname "$age_key_file")"
        age-keygen -o "$age_key_file"
        log_success "Age key generated at $age_key_file"
        log_warning "Please backup your age key securely!"
    else
        log_info "Age key already exists at $age_key_file"
    fi
}

# Setup SOPS configuration
setup_sops() {
    local age_key_file="$HOME/.config/sops/age/keys.txt"
    local age_public_key
    
    if [[ ! -f "$age_key_file" ]]; then
        log_error "Age key file not found. Please run generate_age_key first."
        exit 1
    fi
    
    # Extract public key from age key file
    age_public_key=$(grep "public key:" "$age_key_file" | cut -d' ' -f4)
    
    # Update .sops.yaml with the actual public key
    sed -i "s/age1your-age-key-here-replace-with-actual-key/$age_public_key/" secrets/.sops.yaml
    
    log_success "SOPS configuration updated with age public key"
}

# Encrypt secrets
encrypt_secrets() {
    log_info "Encrypting secrets with SOPS..."
    
    # List of secret files to encrypt
    local secrets=(
        "traefik_cert.encrypted"
        "traefik_key.encrypted"
        "oauth2_proxy_client_id.encrypted"
        "oauth2_proxy_client_secret.encrypted"
        "crowdsec_api_key.encrypted"
    )
    
    for secret in "${secrets[@]}"; do
        local secret_path="secrets/$secret"
        if [[ -f "$secret_path" ]]; then
            log_info "Encrypting $secret..."
            sops -e -i "$secret_path"
            log_success "$secret encrypted"
        else
            log_warning "$secret not found, skipping..."
        fi
    done
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    cd terraform
    terraform init
    log_success "Terraform initialized"
    cd ..
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    cd terraform
    
    # Check if terraform.tfvars exists
    if [[ ! -f "terraform.tfvars" ]]; then
        log_error "terraform.tfvars not found. Please copy terraform.tfvars.example and configure it."
        exit 1
    fi
    
    # Plan deployment
    log_info "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply deployment
    log_info "Applying Terraform deployment..."
    terraform apply tfplan
    
    log_success "Infrastructure deployed successfully"
    cd ..
}

# Display next steps
show_next_steps() {
    log_success "Bootstrap completed successfully!"
    echo
    log_info "Next steps:"
    echo "1. Access Portainer at: https://your-domain:9443"
    echo "2. Set up admin account on first login"
    echo "3. Configure GitOps in Portainer:"
    echo "   - Go to Settings > GitOps"
    echo "   - Add your Git repository"
    echo "   - Enable auto-deployment"
    echo "4. Deploy your stacks:"
    echo "   - Traefik: https://traefik.your-domain"
    echo "   - CrowdSec: https://crowdsec.your-domain"
    echo "   - OAuth2 Proxy: https://auth.your-domain"
    echo
    log_info "For monitoring (optional):"
    echo "- Prometheus: https://prometheus.your-domain"
    echo "- Grafana: https://grafana.your-domain"
}

# Main function
main() {
    log_info "Starting Edge Stack GitOps Bootstrap..."
    
    check_root
    check_prerequisites
    generate_age_key
    setup_sops
    encrypt_secrets
    init_terraform
    deploy_infrastructure
    show_next_steps
}

# Run main function
main "$@"
