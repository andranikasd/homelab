#!/bin/bash

# VM Bootstrap Script for Edge Stack
# This script sets up the VM with Docker, Docker Compose, and necessary tools

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

# Update system
update_system() {
    log_info "Updating system packages..."
    apt update && apt upgrade -y
    log_success "System updated"
}

# Install Docker
install_docker() {
    log_info "Installing Docker..."
    
    # Remove old Docker packages
    apt remove -y docker docker-engine docker.io containerd runc || true
    
    # Install prerequisites
    apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add user to docker group
    usermod -aG docker $USER
    
    log_success "Docker installed"
}

# Install Terraform
install_terraform() {
    log_info "Installing Terraform..."
    
    # Download and install Terraform
    wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
    unzip terraform_1.6.0_linux_amd64.zip
    mv terraform /usr/local/bin/
    rm terraform_1.6.0_linux_amd64.zip
    
    log_success "Terraform installed"
}

# Install SOPS and age
install_sops() {
    log_info "Installing SOPS and age..."
    
    # Install age
    apt install -y age
    
    # Install SOPS
    wget https://github.com/mozilla/sops/releases/latest/download/sops-v3.8.1.linux.amd64
    mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
    chmod +x /usr/local/bin/sops
    
    log_success "SOPS and age installed"
}

# Install additional tools
install_tools() {
    log_info "Installing additional tools..."
    
    apt install -y \
        git \
        curl \
        wget \
        unzip \
        htop \
        vim \
        ufw \
        fail2ban \
        htop \
        tree \
        jq
    
    log_success "Additional tools installed"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."
    
    # Enable UFW
    ufw --force enable
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow Portainer
    ufw allow 9000/tcp
    ufw allow 9443/tcp
    
    # Allow Docker Swarm
    ufw allow 2376/tcp
    ufw allow 2377/tcp
    ufw allow 7946/tcp
    ufw allow 7946/udp
    ufw allow 4789/udp
    
    log_success "Firewall configured"
}

# Configure fail2ban
configure_fail2ban() {
    log_info "Configuring fail2ban..."
    
    # Create jail.local
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
EOF
    
    # Start and enable fail2ban
    systemctl start fail2ban
    systemctl enable fail2ban
    
    log_success "Fail2ban configured"
}

# Create directories
create_directories() {
    log_info "Creating directories..."
    
    mkdir -p /opt/edge-stack/{stacks,secrets,portainer,scripts}
    mkdir -p /home/ubuntu/.config/sops/age
    
    log_success "Directories created"
}

# Set up SSH key for root access
setup_ssh() {
    log_info "Setting up SSH access..."
    
    # Create .ssh directory for root
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    
    # Copy SSH key from ubuntu user
    if [ -f /home/ubuntu/.ssh/authorized_keys ]; then
        cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/
        chmod 600 /root/.ssh/authorized_keys
    fi
    
    log_success "SSH access configured"
}

# Configure Docker daemon
configure_docker() {
    log_info "Configuring Docker daemon..."
    
    # Create Docker daemon configuration
    cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "metrics-addr": "0.0.0.0:9323",
  "metrics-interval": "30s"
}
EOF
    
    # Restart Docker
    systemctl restart docker
    
    log_success "Docker daemon configured"
}

# Create systemd service for edge-stack
create_systemd_service() {
    log_info "Creating systemd service..."
    
    cat > /etc/systemd/system/edge-stack.service << EOF
[Unit]
Description=Edge Stack GitOps Bootstrap
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/edge-stack
ExecStart=/bin/bash -c 'cd /opt/edge-stack && docker swarm init --advertise-addr 0.0.0.0'
ExecStop=/bin/bash -c 'cd /opt/edge-stack && docker swarm leave --force || true'

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable edge-stack.service
    
    log_success "Systemd service created"
}

# Main function
main() {
    log_info "Starting VM bootstrap for Edge Stack..."
    
    update_system
    install_docker
    install_terraform
    install_sops
    install_tools
    configure_firewall
    configure_fail2ban
    create_directories
    setup_ssh
    configure_docker
    create_systemd_service
    
    log_success "VM bootstrap completed successfully!"
    log_info "VM is ready for Edge Stack deployment"
}

# Run main function
main "$@"
