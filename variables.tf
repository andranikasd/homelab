variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
}

variable "ssh_public_keys" {
  type = string
}

variable "pve_node" {
  type    = string
  default = "pve"
}

variable "lxc_password" {
  type = string
  description = "The password for the LXC container"
  sensitive = true
}
