# Edge Stack GitOps Bootstrap - Setup Guide

This guide will walk you through setting up a complete GitOps environment using Terraform, Portainer, and Docker Swarm.

## Prerequisites

### System Requirements
- Proxmox host with Debian/Ubuntu
- Docker and Docker Compose plugin installed
- Terraform >= 1.0
- SOPS with age encryption
- Git access to this repository

### Install Prerequisites

#### 1. Install Docker and Docker Compose
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose plugin
sudo apt install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version
```

#### 2. Install Terraform
```bash
# Download and install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.6.0_linux_amd64.zip

# Verify installation
terraform --version
```

#### 3. Install SOPS and age
```bash
# Install age
sudo apt install age -y

# Install SOPS
wget https://github.com/mozilla/sops/releases/latest/download/sops-v3.8.1.linux.amd64
sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops

# Verify installation
sops --version
age --version
```

## Quick Start

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd homelab
```

### 2. Configure Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Run Bootstrap Script
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run bootstrap
./scripts/bootstrap.sh
```

## Manual Setup

If you prefer to set up manually:

### 1. Generate Age Key
```bash
# Generate age key for SOPS
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Extract public key
age_public_key=$(grep "public key:" ~/.config/sops/age/keys.txt | cut -d' ' -f4)
echo "Public key: $age_public_key"
```

### 2. Configure SOPS
```bash
# Update .sops.yaml with your public key
sed -i "s/age1your-age-key-here-replace-with-actual-key/$age_public_key/" secrets/.sops.yaml
```

### 3. Encrypt Secrets
```bash
# Edit secret files with your actual values
# Then encrypt them
./scripts/encrypt-secrets.sh encrypt
```

### 4. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Configuration

### Terraform Variables

Edit `terraform/terraform.tfvars` with your values:

```hcl
# Docker configuration
docker_host = "unix:///var/run/docker.sock"
swarm_advertise_addr = "0.0.0.0"

# Portainer configuration
portainer_agent_secret = "your-secure-agent-secret-here"

# GitOps configuration
git_repository = "https://github.com/your-username/your-homelab-repo.git"
git_branch = "main"
git_username = "your-git-username"
git_password = "your-git-token-or-password"

# Domain configuration
domain = "your-domain.com"
email = "your-email@example.com"

# OAuth2 Proxy configuration
oauth2_proxy_provider = "google"
oauth2_proxy_redirect_url = "https://your-domain.com/oauth2/callback"
```

### Secret Management

All secrets are encrypted using SOPS with age encryption:

1. **Edit secret files** in `secrets/` directory
2. **Encrypt with SOPS**:
   ```bash
   ./scripts/encrypt-secrets.sh encrypt
   ```
3. **Decrypt for editing**:
   ```bash
   ./scripts/encrypt-secrets.sh decrypt
   ```

### Environment Variables

Set these in Portainer for each stack:

- `DOMAIN` - Your primary domain
- `EMAIL` - Email for Let's Encrypt certificates
- `TRAEFIK_AUTH` - Basic auth for Traefik dashboard (htpasswd format)
- `CROWDSEC_AUTH` - Basic auth for CrowdSec dashboard
- `OAUTH2_PROVIDER` - OAuth2 provider (google, github, etc.)
- `OAUTH2_REDIRECT_URL` - OAuth2 redirect URL
- `OAUTH2_COOKIE_SECRET` - Random string for cookie encryption

## Portainer Setup

### 1. Access Portainer
Navigate to `https://your-domain:9443`

### 2. Initial Setup
- Set up admin account on first login
- Configure Docker Swarm settings

### 3. Configure GitOps
1. Go to **Settings > GitOps**
2. Add your Git repository:
   - URL: Your repository URL
   - Branch: `main`
   - Username: Your Git username
   - Password: Your Git token/password
   - Path: `stacks/`
3. Enable **Auto-deploy**
4. Configure webhook if needed

### 4. Deploy Stacks
Stacks will be automatically deployed from Git. Monitor deployment in Portainer.

## Stack Overview

### Traefik
- **URL**: `https://traefik.your-domain`
- **Purpose**: Reverse proxy, load balancer, SSL termination
- **Features**: Let's Encrypt integration, dashboard, metrics

### CrowdSec
- **URL**: `https://crowdsec.your-domain`
- **Purpose**: WAF, threat detection, security
- **Features**: Dashboard, API, bouncer integration

### OAuth2 Proxy
- **URL**: `https://auth.your-domain`
- **Purpose**: Authentication and authorization
- **Features**: OAuth2 integration, session management

### Monitoring (Exporters Only)
- **Node Exporter**: `https://node-exporter.your-domain`
- **Docker Exporter**: `https://docker-exporter.your-domain`
- **Traefik Exporter**: `https://traefik-exporter.your-domain`
- **CrowdSec Exporter**: `https://crowdsec-exporter.your-domain`

## Monitoring Integration

The monitoring stack provides Prometheus-compatible metrics endpoints that can be scraped by your external Prometheus instance in Kubernetes:

```yaml
# Example Prometheus scrape config
scrape_configs:
  - job_name: 'edge-stack-node'
    static_configs:
      - targets: ['node-exporter.your-domain:443']
    scheme: https
    tls_config:
      insecure_skip_verify: true
  
  - job_name: 'edge-stack-docker'
    static_configs:
      - targets: ['docker-exporter.your-domain:443']
    scheme: https
    tls_config:
      insecure_skip_verify: true
  
  - job_name: 'edge-stack-traefik'
    static_configs:
      - targets: ['traefik-exporter.your-domain:443']
    scheme: https
    tls_config:
      insecure_skip_verify: true
  
  - job_name: 'edge-stack-crowdsec'
    static_configs:
      - targets: ['crowdsec-exporter.your-domain:443']
    scheme: https
    tls_config:
      insecure_skip_verify: true
```

## Troubleshooting

### Common Issues

1. **Docker Swarm not initialized**:
   ```bash
   docker swarm init --advertise-addr 0.0.0.0
   ```

2. **Secrets not found**:
   - Ensure secrets are encrypted with SOPS
   - Check that age key is properly configured

3. **Terraform apply fails**:
   - Verify all variables are set in `terraform.tfvars`
   - Check that Docker is running and accessible

4. **Portainer can't access Git**:
   - Verify Git credentials in Portainer settings
   - Check repository permissions

### Logs

View logs for troubleshooting:
```bash
# Docker Swarm logs
docker service logs portainer
docker service logs traefik

# Terraform logs
cd terraform
terraform show
```

## Security Considerations

1. **Backup age key**: Store your age key securely
2. **Rotate secrets**: Regularly rotate API keys and passwords
3. **Network security**: Configure firewall rules appropriately
4. **SSL certificates**: Monitor Let's Encrypt certificate expiration
5. **Access control**: Use strong authentication for all services

## Maintenance

### Updates
- Update Docker images regularly
- Monitor security advisories
- Keep Terraform and SOPS updated

### Backups
- Backup Portainer data volume
- Backup encrypted secrets
- Backup Terraform state

### Monitoring
- Monitor service health
- Check certificate expiration
- Review security logs

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review logs for error messages
3. Consult the official documentation for each component
4. Create an issue in the repository
