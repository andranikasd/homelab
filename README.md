# Edge Stack – Complete GitOps Bootstrap

This repository provides a complete end-to-end GitOps bootstrap solution that:

1. **Provisions a VM in Proxmox** with public IP
2. **Sets up Portainer** with all the tools
3. **Deploys everything functionally** in one command

## Architecture

- **Proxmox**: VM provisioning and management
- **Terraform**: Infrastructure as Code for VM and Docker Swarm
- **Portainer**: Container management and GitOps
- **Docker Swarm**: Single-node cluster for orchestration
- **SOPS**: Encrypts secrets in Git using age encryption
- **GitOps**: Automated deployment from Git repository

## Complete End-to-End Deployment

### One-Command Deployment

```bash
# Clone and deploy everything
git clone https://github.com/andranikgrigoryan/homelab.git
cd homelab

# Run complete deployment (VM + Portainer + Stacks)
./deploy.sh
```

### What This Does

1. **Creates VM in Proxmox**:
   - 4 CPU cores, 8GB RAM, 100GB disk
   - Public IP: `51.178.20.53`
   - Ubuntu 22.04 with Docker pre-installed

2. **Deploys Portainer**:
   - Web UI at `https://mxnq.net:9443`
   - Docker Swarm management
   - GitOps configuration

3. **Deploys Edge Stack**:
   - **Traefik**: Reverse proxy with SSL
   - **CrowdSec**: WAF and security
   - **OAuth2 Proxy**: Authentication
   - **Monitoring**: Prometheus exporters

## Repository Structure

```
├── terraform/                 # Terraform configurations
│   ├── main.tf              # Main infrastructure
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   └── terraform.tfvars.example
├── stacks/                   # Docker Compose stacks
│   ├── traefik/             # Reverse proxy
│   ├── crowdsec/            # WAF and security
│   ├── oauth2-proxy/        # Authentication
│   └── monitoring/          # Observability stack
├── secrets/                  # SOPS encrypted secrets
│   ├── .sops.yaml           # SOPS configuration
│   └── *.encrypted          # Encrypted secret files
├── portainer/               # Portainer configurations
│   └── gitops/              # GitOps stack definitions
└── scripts/                 # Utility scripts
    ├── bootstrap.sh         # Initial setup script
    └── encrypt-secrets.sh   # Secret encryption helper
```

## Security

- All secrets are encrypted using SOPS with age encryption
- Secrets are automatically decrypted and deployed to Docker Swarm
- GitOps ensures consistent and auditable deployments
- WAF protection via CrowdSec

## Monitoring

- Traefik provides reverse proxy and load balancing
- CrowdSec offers WAF and threat detection
- oauth2-proxy handles authentication
- Optional monitoring stack for observability

## License

See [LICENSE](LICENSE) file for details.
