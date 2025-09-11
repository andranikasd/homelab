# Manual Setup Guide

This guide will help you manually set up the Edge Stack using Proxmox cloud-init and Portainer.

## Prerequisites

- Proxmox server with Ubuntu 22.04 template
- Public IP: `51.178.20.53`
- Domain: `mxnq.net`

## Step 1: Create Proxmox VM

### VM Configuration
- **Name**: edge-stack
- **VM ID**: 100
- **CPU**: 4 cores
- **RAM**: 8GB
- **Disk**: 100GB
- **Network**: vmbr0 with public IP

### Cloud-Init Configuration
```yaml
#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJsXbdvx0uf+40L8wTTNFerokakXCGdcfc2QGXnaJVEJmJePVHgu9sLFDUtEZwBA1okTG/ut2VnVbe9EVm5tfFHSGxX+bxK4K/xMmgXJ7PYvn2lFyGEnhFi/CGtIrDpplwlTHkcj/2RR26OFVVJUVG3kDpAYqEKpzOL13/sYsXg6cao+7zvXggwAs67Vl+fe9XKal8J/6kWXrzB3akEX8WbrF4/eb6J/TEKuo7AzcSpsWsvCC3ns9FnRiwzbJ9xKgmdb12vYTbjUSlR+rqvfYD4kGffHAVIOCcgllnUAmKc3wJ7VZdK34eRvx8fg0x39bygFjLyhc6Y+/gJxvOPygy2yRpB6c5eClsqV5QKuNof5ZWELr+/tpOvYdjinLudhbz+GMZmyP0rtz6dPC9WQS8th3GR/T7qePrO79mMvZGVqeRqnGkRFqWTZH/p9CBykIJGgt47kCb9rBsaFVdYn3D+66HDRVYGQeuPPejRPPnrEqFXjyC+D/ro0Wz7w0Ea+/VC11RgqCfHWxEOUQ965hKZf/tUjUwqjM3u2hdYNvxOd3ISotNdH63KlYiNKmWDAW+9UcRId+Gxi7rcO/heS6Pu2epalFDAc1KrUAC2eCaDR8SE+s1UZ/S8Bz6ioMcr7Lyy/vjFD+YFspeqtM1a8O/FTbJO3Nj3GE9QUuYMgErdQ== andranikgrigoryan@fedora

runcmd:
  - apt update && apt upgrade -y
  - curl -fsSL https://get.docker.com -o get-docker.sh
  - sh get-docker.sh
  - usermod -aG docker ubuntu
  - apt install -y docker-compose-plugin
  - docker swarm init --advertise-addr 0.0.0.0
  - docker volume create portainer_data
  - docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
  - ufw allow ssh
  - ufw allow 80/tcp
  - ufw allow 443/tcp
  - ufw allow 9443/tcp
  - ufw --force enable
```

## Step 2: Access Portainer

1. **Access Portainer**: https://mxnq.net:9443
2. **Set up admin account** on first login
3. **Configure Docker Swarm** in Portainer

## Step 3: Configure GitOps

1. **Go to Settings > GitOps**
2. **Add Git Repository**:
   - URL: `https://github.com/andranikasd/homelab.git`
   - Branch: `main`
   - Path: `stacks/`
3. **Enable Auto-deploy**

## Step 4: Deploy Stacks

The stacks will be automatically deployed from Git:

- **Traefik**: https://traefik.mxnq.net
- **CrowdSec**: https://crowdsec.mxnq.net
- **OAuth2 Proxy**: https://auth.mxnq.net

## Step 5: Configure DNS

Point your domain records to `51.178.20.53`:
- `mxnq.net` → `51.178.20.53`
- `traefik.mxnq.net` → `51.178.20.53`
- `crowdsec.mxnq.net` → `51.178.20.53`
- `auth.mxnq.net` → `51.178.20.53`

## Step 6: Configure OAuth2

1. **Update OAuth2 settings** in Portainer
2. **Set environment variables**:
   - `OAUTH2_PROVIDER=google`
   - `OAUTH2_REDIRECT_URL=https://auth.mxnq.net/oauth2/callback`
   - `DOMAIN=mxnq.net`

## Monitoring

Access monitoring endpoints:
- **Node Exporter**: https://node-exporter.mxnq.net
- **Docker Exporter**: https://docker-exporter.mxnq.net
- **Traefik Exporter**: https://traefik-exporter.mxnq.net
- **CrowdSec Exporter**: https://crowdsec-exporter.mxnq.net

## Troubleshooting

### VM Not Starting
- Check Proxmox logs
- Verify cloud-init configuration
- Check network settings

### Portainer Not Accessible
- Check firewall rules
- Verify Docker is running
- Check Portainer logs: `docker logs portainer`

### Stacks Not Deploying
- Check GitOps configuration in Portainer
- Verify repository access
- Check stack logs in Portainer

## Security Notes

- All secrets are encrypted with SOPS
- Firewall is configured with UFW
- SSL certificates managed by Let's Encrypt
- WAF protection via CrowdSec
