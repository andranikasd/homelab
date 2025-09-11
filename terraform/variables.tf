# Proxmox Configuration
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification for Proxmox API"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

# VM Configuration
variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "edge-stack"
}

variable "vm_id" {
  description = "VM ID in Proxmox"
  type        = number
  default     = 100
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "vm_storage" {
  description = "Storage pool name"
  type        = string
  default     = "local-lvm"
}

variable "vm_disk_size" {
  description = "Disk size"
  type        = string
  default     = "20G"
}

variable "vm_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vm_public_ip" {
  description = "Public IP address for the VM"
  type        = string
}

variable "vm_gateway" {
  description = "Gateway IP address"
  type        = string
}

variable "vm_user" {
  description = "VM user"
  type        = string
  default     = "ubuntu"
}

variable "vm_password" {
  description = "VM password"
  type        = string
  sensitive   = true
}

variable "vm_ssh_key" {
  description = "SSH public key"
  type        = string
}

variable "vm_ssh_private_key" {
  description = "SSH private key path"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "vm_template" {
  description = "VM template name"
  type        = string
  default     = "ubuntu-22.04-cloud"
}

# Docker Configuration
variable "docker_host" {
  description = "Docker daemon host"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "docker_cert_path" {
  description = "Docker certificates path"
  type        = string
  default     = ""
}

variable "swarm_advertise_addr" {
  description = "Docker Swarm advertise address"
  type        = string
  default     = "0.0.0.0"
}

variable "portainer_agent_secret" {
  description = "Portainer agent secret for secure communication"
  type        = string
  sensitive   = true
}

variable "git_repository" {
  description = "Git repository URL for GitOps"
  type        = string
}

variable "git_branch" {
  description = "Git branch for GitOps"
  type        = string
  default     = "main"
}

variable "git_username" {
  description = "Git username for authentication"
  type        = string
  default     = ""
}

variable "git_password" {
  description = "Git password/token for authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "stack_path" {
  description = "Path to stacks in the Git repository"
  type        = string
  default     = "stacks"
}

variable "domain" {
  description = "Primary domain for the edge stack"
  type        = string
}

variable "email" {
  description = "Email for Let's Encrypt certificates"
  type        = string
}

variable "oauth2_proxy_provider" {
  description = "OAuth2 provider (google, github, etc.)"
  type        = string
  default     = "google"
}

variable "oauth2_proxy_redirect_url" {
  description = "OAuth2 redirect URL"
  type        = string
}

variable "crowdsec_api_url" {
  description = "CrowdSec API URL"
  type        = string
  default     = "https://api.crowdsec.net"
}
