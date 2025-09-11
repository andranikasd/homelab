#!/bin/bash

# Edge Stack GitOps Bootstrap - Complete Deployment Script
# This script provisions a VM in Proxmox and deploys the complete Edge Stack

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"
SECRETS_DIR="${SCRIPT_DIR}/secrets"

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
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
    
    # Check if terraform.tfvars exists
    if [[ ! -f "${TERRAFORM_DIR}/terraform.tfvars" ]]; then
        log_error "terraform.tfvars not found. Please copy terraform.tfvars.example and configure it."
        exit 1
    fi
    
    log_success "All prerequisites are installed"
}

# Generate age key if it doesn't exist
generate_age_key() {
    local age_key_file="$HOME/.config/sops/age/keys.txt"
    
    if [[ ! -f "$age_key_file" ]]; then
        log_step "Generating age key for SOPS encryption..."
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
    sed -i "s/age1your-age-key-here-replace-with-actual-key/$age_public_key/" "${SECRETS_DIR}/.sops.yaml"
    
    log_success "SOPS configuration updated with age public key"
}

# Encrypt secrets
encrypt_secrets() {
    log_step "Encrypting secrets with SOPS..."
    
    # Get age public key
    local age_public_key
    age_public_key=$(grep "public key:" "$HOME/.config/sops/age/keys.txt" | cut -d' ' -f4)
    
    # List of secret files to encrypt
    local secrets=(
        "traefik_cert.encrypted"
        "traefik_key.encrypted"
        "oauth2_proxy_client_id.encrypted"
        "oauth2_proxy_client_secret.encrypted"
        "crowdsec_api_key.encrypted"
    )
    
    for secret in "${secrets[@]}"; do
        local secret_path="${SECRETS_DIR}/$secret"
        if [[ -f "$secret_path" ]]; then
            log_info "Encrypting $secret..."
            sops -e --age "$age_public_key" -i "$secret_path"
            log_success "$secret encrypted"
        else
            log_warning "$secret not found, skipping..."
        fi
    done
}

# Initialize Terraform
init_terraform() {
    log_step "Initializing Terraform..."
    cd "${TERRAFORM_DIR}"
    terraform init
    log_success "Terraform initialized"
}

# Deploy infrastructure
deploy_infrastructure() {
    log_step "Deploying infrastructure with Terraform..."
    cd "${TERRAFORM_DIR}"
    
    # Plan deployment
    log_info "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Ask for confirmation
    echo
    log_warning "This will create a VM in Proxmox and deploy the Edge Stack."
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled by user"
        exit 0
    fi
    
    # Apply deployment
    log_info "Applying Terraform deployment..."
    terraform apply tfplan
    
    log_success "Infrastructure deployed successfully"
}

# Wait for services to be ready
wait_for_services() {
    log_step "Waiting for services to be ready..."
    
    # Get VM IP from Terraform output
    local vm_ip
    vm_ip=$(cd "${TERRAFORM_DIR}" && terraform output -raw vm_public_ip 2>/dev/null || echo "")
    
    if [[ -z "$vm_ip" ]]; then
        log_warning "Could not get VM IP from Terraform output"
        return
    fi
    
    # Extract IP from CIDR notation
    local ip_only
    ip_only=$(echo "$vm_ip" | cut -d'/' -f1)
    
    log_info "Waiting for VM at $ip_only to be ready..."
    
    # Wait for SSH to be available
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@"$ip_only" "echo 'SSH ready'" 2>/dev/null; then
            log_success "VM is ready"
            break
        fi
        
        log_info "Attempt $attempt/$max_attempts: Waiting for VM..."
        sleep 10
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        log_warning "VM may not be ready yet. Please check manually."
    fi
}

# Deploy stacks to VM
deploy_stacks() {
    log_step "Deploying stacks to VM..."
    
    # Get VM IP from Terraform output
    local vm_ip
    vm_ip=$(cd "${TERRAFORM_DIR}" && terraform output -raw vm_public_ip 2>/dev/null || echo "")
    
    if [[ -z "$vm_ip" ]]; then
        log_warning "Could not get VM IP from Terraform output"
        return
    fi
    
    # Extract IP from CIDR notation
    local ip_only
    ip_only=$(echo "$vm_ip" | cut -d'/' -f1)
    
    log_info "Deploying stacks to VM at $ip_only..."
    
    # Copy stacks to VM
    scp -r -o StrictHostKeyChecking=no "${SCRIPT_DIR}/stacks" ubuntu@"$ip_only":/opt/edge-stack/
    scp -r -o StrictHostKeyChecking=no "${SCRIPT_DIR}/secrets" ubuntu@"$ip_only":/opt/edge-stack/
    
    # Deploy stacks
    ssh -o StrictHostKeyChecking=no ubuntu@"$ip_only" << 'EOF'
        cd /opt/edge-stack
        
        # Initialize Docker Swarm
        sudo docker swarm init --advertise-addr 0.0.0.0
        
        # Deploy Traefik
        sudo docker stack deploy -c stacks/traefik/docker-compose.yml traefik
        
        # Wait a bit for Traefik to start
        sleep 30
        
        # Deploy CrowdSec
        sudo docker stack deploy -c stacks/crowdsec/docker-compose.yml crowdsec
        
        # Deploy OAuth2 Proxy
        sudo docker stack deploy -c stacks/oauth2-proxy/docker-compose.yml oauth2-proxy
        
        # Deploy Monitoring
        sudo docker stack deploy -c stacks/monitoring/docker-compose.yml monitoring
EOF
    
    log_success "Stacks deployed successfully"
}

# Display deployment summary
show_deployment_summary() {
    log_step "Deployment Summary"
    
    # Get VM IP from Terraform output
    local vm_ip
    vm_ip=$(cd "${TERRAFORM_DIR}" && terraform output -raw vm_public_ip 2>/dev/null || echo "")
    
    if [[ -z "$vm_ip" ]]; then
        log_warning "Could not get VM IP from Terraform output"
        return
    fi
    
    # Extract IP from CIDR notation
    local ip_only
    ip_only=$(echo "$vm_ip" | cut -d'/' -f1)
    
    # Get domain from terraform.tfvars
    local domain
    domain=$(grep 'domain =' "${TERRAFORM_DIR}/terraform.tfvars" | cut -d'"' -f2)
    
    echo
    log_success "🎉 Edge Stack deployment completed successfully!"
    echo
    log_info "📋 Deployment Summary:"
    echo "   • VM IP: $ip_only"
    echo "   • Domain: $domain"
    echo
    log_info "🌐 Services Available:"
    echo "   • Portainer: https://$domain:9443"
    echo "   • Traefik Dashboard: https://traefik.$domain"
    echo "   • CrowdSec Dashboard: https://crowdsec.$domain"
    echo "   • OAuth2 Proxy: https://auth.$domain"
    echo
    log_info "📊 Monitoring Endpoints:"
    echo "   • Node Exporter: https://node-exporter.$domain"
    echo "   • Docker Exporter: https://docker-exporter.$domain"
    echo "   • Traefik Exporter: https://traefik-exporter.$domain"
    echo "   • CrowdSec Exporter: https://crowdsec-exporter.$domain"
    echo
    log_info "🔧 Next Steps:"
    echo "   1. Access Portainer and set up admin account"
    echo "   2. Configure GitOps in Portainer settings"
    echo "   3. Set up DNS records for your domain"
    echo "   4. Configure OAuth2 provider settings"
    echo "   5. Set up monitoring in your Kubernetes cluster"
    echo
    log_warning "⚠️  Important:"
    echo "   • Backup your age key: ~/.config/sops/age/keys.txt"
    echo "   • Update DNS records to point to: $ip_only"
    echo "   • Configure firewall rules as needed"
}

# Main function
main() {
    log_info "🚀 Starting Edge Stack GitOps Bootstrap Deployment..."
    echo
    
    check_root
    check_prerequisites
    generate_age_key
    setup_sops
    encrypt_secrets
    init_terraform
    deploy_infrastructure
    wait_for_services
    deploy_stacks
    show_deployment_summary
}

# Run main function
main "$@"
