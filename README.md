# Homelab Docker Compose Stack

A production-ready monitoring and automation stack with Traefik, Prometheus, Grafana, and N8n.
SSL is handled by Cloudflare proxy.

## Services

| Service | URL | Description |
|---------|-----|-------------|
| Traefik | https://traefik.mxnq.net | Reverse proxy dashboard |
| Prometheus | https://prometheus.mxnq.net | Metrics collection |
| Grafana | https://grafana.mxnq.net | Dashboards & visualization |
| N8n | https://n8n.mxnq.net | Workflow automation |

## Quick Start

### 1. Configure DNS

Point `*.mxnq.net` to your server's IP via Cloudflare (proxied).

### 2. Create Environment File

```bash
cp .env.example .env
# Edit .env with your values

# Generate basic auth password:
echo $(htpasswd -nb admin your-password) | sed -e s/\\$/\\$\\$/g
```

### 3. Start the Stack

```bash
docker compose up -d
```

### 4. View Logs

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
│            CLOUDFLARE (SSL Termination)                 │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│                    TRAEFIK (:80)                        │
│                    Reverse Proxy                        │
└─────────────────────────────────────────────────────────┘
         │              │              │              │
    ┌────▼────┐   ┌─────▼─────┐  ┌─────▼────┐   ┌─────▼────┐
    │ Traefik │   │ Prometheus│  │  Grafana │   │   N8n    │
    │Dashboard│   │   :9090   │  │  :3000   │   │  :5678   │
    └─────────┘   └───────────┘  └──────────┘   └──────────┘
```
