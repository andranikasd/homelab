resource "proxmox_vm_qemu" "worker_node" {
  count           = var.worker_count
  vmid            = var.start_vmid + var.etcd_count + var.control_plane_count + count.index
  name            = "worker-node-${count.index + 1}"
  target_node     = var.target_node
  cores           = var.worker_cores
  memory          = var.worker_memory
  scsihw          = "virtio-scsi-pci"
  bootdisk        = "scsi0"
  agent           = 1
  os_type         = "cloud-init"
  disks {
    size          = var.worker_disk_size
    storage       = var.worker_storage
    type          = "scsi"
    iothread      = true
  }

  network {
    model    = "virtio"
    bridge   = "vmbr0"
    ipconfig0 = "ip=${local.worker_ips[count.index]}/24,gw=${var.network_gateway}"
  }

  sshkeys            = file("${var.ssh_public_keys}")
  clone              = var.vm_template  # VM template for cloning
  onboot             = true

  # Cloud-init configuration
  ipconfig0 {
    ip     = "${local.worker_ips[count.index]}/24"
    gw     = var.network_gateway
  }

  provisioner "file" {
    source      = "./helpers/setup-worker.sh"
    destination = "/usr/local/setup-worker.sh"
    
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_ed25519")
      host        = local.worker_ips[count.index]
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /usr/local/setup-worker.sh",
      "/usr/local/setup-worker.sh ${count.index + 1} ${local.worker_ips[count.index]}"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_ed25519")
      host        = local.worker_ips[count.index]
    }
  }
}
