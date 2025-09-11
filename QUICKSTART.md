# Quick Start Guide - OVH Edge Stack

This guide will get your Edge Stack running on your OVH Proxmox server in minutes.

## Prerequisites

- Your OVH Proxmox server running at `pve.mxnq.net`
- Terraform installed on your local machine
- SOPS and age installed
- SSH access to your OVH server

## One-Command Deployment

```bash
# 1. Clone the repository
git clone https://github.com/andranikgrigoryan/homelab.git
cd homelab

# 2. Make scripts executable
chmod +x deploy.sh scripts/*.sh

# 3. Deploy everything
./deploy.sh
```

## What Gets Deployed

### VM Configuration
- **Name**: edge-stack
- **Resources**: 4 CPU cores, 8GB RAM, 100GB disk
- **IP**: 51.178.20.53 (your OVH public IP)
- **OS**: Ubuntu 22.04 with Docker pre-installed

### Services Deployed
- **Portainer**: https://mxnq.net:9443
- **Traefik Dashboard**: https://traefik.mxnq.net
- **CrowdSec Dashboard**: https://crowdsec.mxnq.net
- **OAuth2 Proxy**: https://auth.mxnq.net

### Monitoring Endpoints
- **Node Exporter**: https://node-exporter.mxnq.net
- **Docker Exporter**: https://docker-exporter.mxnq.net
- **Traefik Exporter**: https://traefik-exporter.mxnq.net
- **CrowdSec Exporter**: https://crowdsec-exporter.mxnq.net

## Configuration

The deployment uses your OVH configuration:
- Proxmox API: `https://pve.mxnq.net:8006/api2/json`
- VM ID: 100
- Storage: local
- Bridge: vmbr0
- Domain: mxnq.net

## After Deployment

1. **Access Portainer**:
   - Go to https://mxnq.net:9443
   - Set up admin account on first login

2. **Configure GitOps**:
   - Go to Settings > GitOps
   - Repository: https://github.com/andranikgrigoryan/homelab.git
   - Path: stacks/
   - Enable auto-deploy

3. **Set up DNS**:
   - Point mxnq.net to 51.178.20.53
   - Add subdomains: traefik, crowdsec, auth, etc.

4. **Configure OAuth2**:
   - Update OAuth2 provider settings
   - Set up redirect URLs

## Troubleshooting

### VM Not Starting
```bash
# Check Proxmox logs
ssh root@pve.mxnq.net "pveam list"

# Verify template exists
ssh root@pve.mxnq.net "qm list"
```

### Services Not Accessible
```bash
# Check VM status
ssh ubuntu@51.178.20.53 "docker ps"

# Check Docker Swarm
ssh ubuntu@51.178.20.53 "docker node ls"
```

### Portainer Not Loading
```bash
# Check Portainer logs
ssh ubuntu@51.178.20.53 "docker service logs portainer"

# Check if port is open
nmap -p 9443 51.178.20.53
```

## Customization

### Change VM Resources
Edit `terraform/terraform.tfvars`:
```hcl
vm_cores = 6        # More CPU
vm_memory = 12288   # More RAM
vm_disk_size = "200G"  # Larger disk
```

### Add More Services
1. Create new stack in `stacks/`
2. Add to GitOps config in `terraform/templates/gitops-config.json.tpl`
3. Redeploy with `./deploy.sh`

### Update Secrets
```bash
# Decrypt secrets
./scripts/encrypt-secrets.sh decrypt

# Edit secret files
vim secrets/traefik_cert.encrypted

# Re-encrypt
./scripts/encrypt-secrets.sh encrypt

# Redeploy
./deploy.sh
```

## Security Notes

- All secrets are encrypted with SOPS
- Firewall is configured with UFW
- Fail2ban is enabled for SSH protection
- SSL certificates are managed by Let's Encrypt

## Monitoring Integration

The monitoring endpoints provide Prometheus-compatible metrics that can be scraped by your Kubernetes cluster:

```yaml
# Example Prometheus scrape config
scrape_configs:
  - job_name: 'ovh-edge-stack'
    static_configs:
      - targets: 
        - 'node-exporter.mxnq.net:443'
        - 'docker-exporter.mxnq.net:443'
        - 'traefik-exporter.mxnq.net:443'
        - 'crowdsec-exporter.mxnq.net:443'
    scheme: https
    tls_config:
      insecure_skip_verify: true
```

## Support

For issues:
1. Check the logs: `ssh ubuntu@51.178.20.53 "docker service logs <service-name>"`
2. Verify VM status in Proxmox
3. Check DNS resolution
4. Review firewall rules

## Next Steps

1. Set up monitoring in your Kubernetes cluster
2. Configure backup strategies
3. Set up log aggregation
4. Implement CI/CD pipelines
5. Add more edge services as needed
