resource "proxmox_lxc" "etcd_node" {
  count           = var.etcd_count
  vmid            = var.start_vmid + count.index
  target_node     = var.target_node
  hostname        = "etcd-node-${count.index + 1}"
  ostemplate      = var.ostemplate
  password        = "password"
  unprivileged    = true
  onboot          = true 
  start           = true # Ensures container starts after creation
  ssh_public_keys = var.ssh_public_keys

  rootfs {
    storage = var.rootfs_storage
    size    = var.rootfs_size
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${local.etcd_ips[count.index]}/24"
    gw     = var.network_gateway
  }

  # File provisioner to copy setup script
  provisioner "file" {
    source      = "./helpers/setup-etcd.sh"
    destination = "/usr/local/setup-etcd.sh"
    
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_ed25519")
      host        = local.etcd_ips[count.index]
    }
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /usr/local/setup-etcd.sh",
      "/usr/local/setup-etcd.sh ${count.index + 1} ${local.etcd_ips[count.index]} '${join(",", [for i in range(var.etcd_count) : "etcd-node-${i + 1}=http://${local.etcd_ips[i]}:2380"])}'"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_ed25519")
      host        = local.etcd_ips[count.index]
    }
  }
}
