terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
  required_version = ">= 1.0.0"
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

locals {
  # Allocate IPs for etcd, control-plane, and worker nodes
  etcd_ips         = [for i in range(var.etcd_count) : cidrhost(var.start_ip_cidr, i + 1)]
  control_plane_ips = [for i in range(var.control_plane_count) : cidrhost(var.start_ip_cidr, i + var.etcd_count + 1)]
  worker_ips       = [for i in range(var.worker_count) : cidrhost(var.start_ip_cidr, i + var.etcd_count + var.control_plane_count + 1)]
}