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

resource "proxmox_lxc" "etcd-node-1" {
  target_node  = "pve"
  hostname     = "etcd-node-1"
  ostemplate   = "local:vztmpl/alpine-3.19-default_20240207_amd64.tar.xz"
  password     = var.lxc_password
  unprivileged = true

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
}

resource "proxmox_lxc" "etcd-node-2" {
  target_node  = "pve"
  hostname     = "etcd-node-2"
  ostemplate   = "local:vztmpl/alpine-3.19-default_20240207_amd64.tar.xz"
  password     = var.lxc_password
  unprivileged = true

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
}

resource "proxmox_lxc" "etcd-node-3" {
  target_node  = "pve"
  hostname     = "etcd-node-3"
  ostemplate   = "local:vztmpl/alpine-3.19-default_20240207_amd64.tar.xz"
  password     = var.lxc_password
  unprivileged = true

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
}
