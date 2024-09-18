module "control_plane" {
  source              = "./modules/control-plane"
  control_plane_count = 3
  proxmox_node        = "proxmox-node-01"
  lxc_template        = "ubuntu-20.04-template"
  lxc_storage         = "local-lvm"
  lxc_password        = "supersecret"
  control_plane_ips   = ["192.168.1.101", "192.168.1.102", "192.168.1.103"]

  # Pass Proxmox provider variables
  proxmox_api_token_secret = var.proxmox_api_token_secret
  proxmox_api_token_id     = var.proxmox_api_token_id
  pm_api_url               = var.pm_api_url
}

module "etcd" {
  source              = "./modules/etcd"
  etcd_node_count     = 3
  proxmox_node        = "proxmox-node-01"
  lxc_template        = "ubuntu-20.04-template"
  lxc_storage         = "local-lvm"
  lxc_password        = "supersecret"
  etcd_ips            = ["192.168.1.104", "192.168.1.105", "192.168.1.106"]

  # Pass Proxmox provider variables
  proxmox_api_token_secret = var.proxmox_api_token_secret
  proxmox_api_token_id     = var.proxmox_api_token_id
  pm_api_url               = var.pm_api_url
}
