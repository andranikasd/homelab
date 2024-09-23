resource "proxmox_lxc" "control_plane" {
  count           = var.control_plane_count
  vmid            = var.start_vmid + var.etcd_count + count.index
  target_node     = var.target_node
  hostname        = "control-plane-${count.index + 1}"
  ostemplate      = var.ostemplate
  password        = "password"
  unprivileged    = true
  onboot          = true 
  start           = true
  ssh_public_keys = var.ssh_public_keys

  rootfs {
    storage = var.rootfs_storage
    size    = var.rootfs_size
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${local.control_plane_ips[count.index]}/24"
    gw     = var.network_gateway
  }

  # File provisioner to copy setup script to the control plane node
  provisioner "file" {
    source      = "./helpers/setup-k0s.sh"
    destination = "/usr/local/setup-k0s.sh"
    
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_ed25519")
      host        = local.control_plane_ips[count.index]
    }
  }

  # Execute the setup-k0s.sh script with dynamic arguments
  provisioner "remote-exec" {
    inline = [
      "chmod +x /usr/local/setup-k0s.sh",
      "/usr/local/setup-k0s.sh ${count.index + 1} ${local.control_plane_ips[count.index]} '${join(",", [for i in range(var.etcd_count) : "https://${local.etcd_ips[i]}:2379"])}'"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_ed25519")
      host        = local.control_plane_ips[count.index]
    }
  }
}
