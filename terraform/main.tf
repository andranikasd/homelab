terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Configure Proxmox provider
provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_api_token_id = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure = var.proxmox_tls_insecure
}

# Configure Docker provider
provider "docker" {
  host = "tcp://${var.vm_public_ip}:2376"
  cert_path = var.docker_cert_path
}

# Create Proxmox VM for Edge Stack
resource "proxmox_vm_qemu" "edge_stack_vm" {
  name        = var.vm_name
  target_node = var.proxmox_node
  vmid        = var.vm_id
  
  # VM Configuration
  cores   = var.vm_cores
  memory  = var.vm_memory
  sockets = 1
  
  # Storage
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  # OS Disk
  disk {
    storage = var.vm_storage
    size    = var.vm_disk_size
    format  = "qcow2"
    type    = "scsi"
  }
  
  # Network - Public IP
  network {
    model  = "virtio"
    bridge = var.vm_bridge
    cidr   = var.vm_public_ip
    gateway = var.vm_gateway
  }
  
  # Cloud-init configuration
  ciuser     = var.vm_user
  cipassword = var.vm_password
  sshkeys    = var.vm_ssh_key
  
  # OS Image
  clone = var.vm_template
  
  # Cloud-init settings
  cicustom = "user=${var.vm_user},password=${var.vm_password},sshkey=${var.vm_ssh_key}"
  
  # Startup script
  startup = "order=1,up=30"
  
  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Wait for VM to be ready
resource "null_resource" "wait_for_vm" {
  depends_on = [proxmox_vm_qemu.edge_stack_vm]
  
  provisioner "local-exec" {
    command = "sleep 60"
  }
}

# Bootstrap script for VM setup
resource "null_resource" "bootstrap_vm" {
  depends_on = [null_resource.wait_for_vm]
  
  connection {
    type        = "ssh"
    host        = var.vm_public_ip
    user        = var.vm_user
    private_key = file(var.vm_ssh_private_key)
    timeout     = "5m"
  }
  
  provisioner "file" {
    source      = "../scripts/vm-bootstrap.sh"
    destination = "/tmp/vm-bootstrap.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/vm-bootstrap.sh",
      "sudo /tmp/vm-bootstrap.sh"
    ]
  }
}

# Initialize Docker Swarm
resource "docker_network" "swarm_network" {
  name = "swarm_network"
  driver = "overlay"
  attachable = true
}

# Create Docker Swarm
resource "null_resource" "docker_swarm_init" {
  provisioner "local-exec" {
    command = "docker swarm init --advertise-addr ${var.swarm_advertise_addr}"
  }
  
  depends_on = [docker_network.swarm_network]
}

# Create Portainer data volume
resource "docker_volume" "portainer_data" {
  name = "portainer_data"
}

# Create Portainer agent network
resource "docker_network" "portainer_agent_network" {
  name = "portainer_agent_network"
  driver = "overlay"
  attachable = true
}

# Deploy Portainer CE
resource "docker_service" "portainer" {
  name = "portainer"
  
  task_spec {
    container_spec {
      image = "portainer/portainer-ce:latest"
      
      env = {
        PORTAINER_AGENT_SECRET = var.portainer_agent_secret
      }
      
      mounts {
        target = "/data"
        source = docker_volume.portainer_data.name
        type   = "volume"
      }
      
      mounts {
        target = "/var/run/docker.sock"
        source = "/var/run/docker.sock"
        type   = "bind"
      }
    }
    
    networks = [
      docker_network.swarm_network.id,
      docker_network.portainer_agent_network.id
    ]
    
    placement {
      constraints = ["node.role == manager"]
    }
  }
  
  endpoint_spec {
    ports {
      target_port    = 9000
      published_port = 9000
      protocol       = "tcp"
    }
    
    ports {
      target_port    = 9443
      published_port = 9443
      protocol       = "tcp"
    }
  }
  
  depends_on = [null_resource.docker_swarm_init]
}

# Deploy Portainer Agent
resource "docker_service" "portainer_agent" {
  name = "portainer-agent"
  
  task_spec {
    container_spec {
      image = "portainer/agent:latest"
      
      env = {
        AGENT_SECRET = var.portainer_agent_secret
        PORTAINER_HOST = "portainer:9000"
      }
      
      mounts {
        target = "/var/run/docker.sock"
        source = "/var/run/docker.sock"
        type   = "bind"
      }
      
      mounts {
        target = "/var/lib/docker/volumes"
        source = "/var/lib/docker/volumes"
        type   = "bind"
      }
    }
    
    networks = [
      docker_network.swarm_network.id,
      docker_network.portainer_agent_network.id
    ]
    
    placement {
      constraints = ["node.role == manager"]
    }
  }
  
  depends_on = [docker_service.portainer]
}

# Create Docker secrets from SOPS encrypted files
resource "docker_secret" "traefik_cert" {
  name = "traefik_cert"
  data = base64encode(file("${path.module}/../secrets/traefik_cert.encrypted"))
}

resource "docker_secret" "traefik_key" {
  name = "traefik_key"
  data = base64encode(file("${path.module}/../secrets/traefik_key.encrypted"))
}

resource "docker_secret" "oauth2_proxy_client_id" {
  name = "oauth2_proxy_client_id"
  data = base64encode(file("${path.module}/../secrets/oauth2_proxy_client_id.encrypted"))
}

resource "docker_secret" "oauth2_proxy_client_secret" {
  name = "oauth2_proxy_client_secret"
  data = base64encode(file("${path.module}/../secrets/oauth2_proxy_client_secret.encrypted"))
}

resource "docker_secret" "crowdsec_api_key" {
  name = "crowdsec_api_key"
  data = base64encode(file("${path.module}/../secrets/crowdsec_api_key.encrypted"))
}

# Create GitOps configuration file for Portainer
resource "local_file" "gitops_config" {
  content = templatefile("${path.module}/templates/gitops-config.json.tpl", {
    git_repository = var.git_repository
    git_branch     = var.git_branch
    git_username   = var.git_username
    git_password   = var.git_password
    stack_path     = var.stack_path
  })
  
  filename = "${path.module}/../portainer/gitops/gitops-config.json"
}

# Create Portainer stack definitions
resource "local_file" "traefik_stack" {
  content = file("${path.module}/../stacks/traefik/docker-compose.yml")
  filename = "${path.module}/../portainer/gitops/traefik-stack.yml"
}

resource "local_file" "crowdsec_stack" {
  content = file("${path.module}/../stacks/crowdsec/docker-compose.yml")
  filename = "${path.module}/../portainer/gitops/crowdsec-stack.yml"
}

resource "local_file" "oauth2_proxy_stack" {
  content = file("${path.module}/../stacks/oauth2-proxy/docker-compose.yml")
  filename = "${path.module}/../portainer/gitops/oauth2-proxy-stack.yml"
}

resource "local_file" "monitoring_stack" {
  content = file("${path.module}/../stacks/monitoring/docker-compose.yml")
  filename = "${path.module}/../portainer/gitops/monitoring-stack.yml"
}
