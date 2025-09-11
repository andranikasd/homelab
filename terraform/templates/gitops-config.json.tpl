{
  "name": "GitOps Configuration",
  "repository": {
    "url": "${git_repository}",
    "branch": "${git_branch}",
    "username": "${git_username}",
    "password": "${git_password}",
    "path": "${stack_path}"
  },
  "stacks": [
    {
      "name": "traefik",
      "file": "traefik/docker-compose.yml",
      "environment": "production"
    },
    {
      "name": "crowdsec",
      "file": "crowdsec/docker-compose.yml",
      "environment": "production"
    },
    {
      "name": "oauth2-proxy",
      "file": "oauth2-proxy/docker-compose.yml",
      "environment": "production"
    },
    {
      "name": "monitoring",
      "file": "monitoring/docker-compose.yml",
      "environment": "production"
    }
  ],
  "auto_deploy": true,
  "webhook_enabled": true
}
