# Edge Stack – GitOps Stacks

This repository contains Docker Compose stacks and encrypted secrets for a complete Edge Stack deployment via Portainer GitOps.

## What's Included

- **Docker Compose Stacks**: Ready-to-deploy stacks for Traefik, CrowdSec, OAuth2-proxy, and monitoring
- **Encrypted Secrets**: SOPS-encrypted secrets for secure GitOps deployment
- **Portainer Configuration**: GitOps setup for automated deployments

## Architecture

- **Portainer**: Container management and GitOps
- **Docker Swarm**: Single-node cluster for orchestration
- **SOPS**: Encrypts secrets in Git using age encryption
- **GitOps**: Automated deployment from Git repository

## Stacks Available

### Core Services
- **Traefik**: Reverse proxy with SSL termination
- **CrowdSec**: WAF and security monitoring
- **OAuth2 Proxy**: Authentication and authorization
- **Monitoring**: Prometheus exporters for metrics

### Monitoring Endpoints
- **Node Exporter**: System metrics
- **Docker Exporter**: Docker metrics  
- **Traefik Exporter**: Traefik metrics
- **CrowdSec Exporter**: CrowdSec metrics

## Repository Structure

```
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
└── docs/                    # Documentation
    ├── SECRETS_GUIDE.md     # Secret setup guide
    └── QUICKSTART.md        # Quick start guide
```

## Quick Start

1. **Set up Proxmox VM** with Docker and Portainer
2. **Configure Portainer GitOps** to use this repository
3. **Deploy stacks** via Portainer interface

## Security

- All secrets are encrypted using SOPS with age encryption
- Secrets are automatically decrypted and deployed to Docker Swarm
- GitOps ensures consistent and auditable deployments
- WAF protection via CrowdSec

## License

See [LICENSE](LICENSE) file for details.
