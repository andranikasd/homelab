terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure     = true
  pm_api_url          = "https://10.0.0.40:8006/api2/json"
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_api_token_id     = var.proxmox_api_token_id
}
