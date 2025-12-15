# Homelab Docker Compose Stack

A production-ready monitoring and automation stack with Traefik, Prometheus, Grafana, and N8n.

## Services

| Service | URL | Description |
|---------|-----|-------------|
| Traefik | https://traefik.mxnq.net | Reverse proxy dashboard |
| Prometheus | https://prometheus.mxnq.net | Metrics collection |
| Grafana | https://grafana.mxnq.net | Dashboards & visualization |
| N8n | https://n8n.mxnq.net | Workflow automation |

## Quick Start

### 1. Configure DNS

Point `*.mxnq.net` to your server's public IP address.

### 2. Update Environment Variables

Edit `.env` file with your values:

```bash
# Generate basic auth password
echo $(htpasswd -nb admin your-password) | sed -e s/\\$/\\$\\$/g
```

### 3. Create Data Directories

```bash
mkdir -p data/{prometheus,grafana}
sudo chown -R 1000:1000 data/
```

### 4. Start the Stack

```bash
docker compose up -d
```

### 5. View Logs

```bash
docker compose logs -f
```

## Default Credentials

- **Traefik/Prometheus**: Set via `TRAEFIK_BASIC_AUTH` in `.env`
- **Grafana**: `admin` / `GRAFANA_ADMIN_PASSWORD` from `.env`
- **N8n**: `N8N_BASIC_AUTH_USER` / `N8N_BASIC_AUTH_PASSWORD` from `.env`

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    TRAEFIK (443)                        │
│              Reverse Proxy + Let's Encrypt              │
└─────────────────────────────────────────────────────────┘
         │              │              │              │
    ┌────▼────┐   ┌─────▼─────┐  ┌─────▼────┐   ┌─────▼────┐
    │ Traefik │   │ Prometheus│  │  Grafana │   │   N8n    │
    │Dashboard│   │   :9090   │  │  :3000   │   │  :5678   │
    └─────────┘   └───────────┘  └──────────┘   └──────────┘
```
