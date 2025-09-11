output "portainer_url" {
  description = "Portainer web interface URL"
  value       = "https://${var.domain}:9443"
}

output "portainer_admin_password" {
  description = "Portainer admin password (set on first login)"
  value       = "Set during first login to Portainer"
  sensitive   = true
}

output "swarm_join_token" {
  description = "Docker Swarm join token for additional nodes"
  value       = "Run: docker swarm join-token worker"
}

output "gitops_config_path" {
  description = "Path to GitOps configuration file"
  value       = "${path.module}/../portainer/gitops/gitops-config.json"
}

output "secrets_created" {
  description = "List of Docker secrets created"
  value = [
    docker_secret.traefik_cert.name,
    docker_secret.traefik_key.name,
    docker_secret.oauth2_proxy_client_id.name,
    docker_secret.oauth2_proxy_client_secret.name,
    docker_secret.crowdsec_api_key.name
  ]
}
