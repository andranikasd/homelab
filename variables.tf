variable "proxmox_api_url" {
  description = "The URL for the Proxmox API, including the port and the API path."
  type        = string
  default     = "https://10.0.0.40:8006/api2/json"
}

variable "proxmox_api_token_id" {
  description = "The token ID used for Proxmox API authentication in the format user@realm!token-name."
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "The secret for the Proxmox API token to authenticate requests."
  type        = string
}

variable "target_node" {
  description = "The Proxmox node (e.g., 'pve') where the LXC containers will be deployed."
  type        = string
  default     = "pve"
}

variable "start_vmid" {
  description = "Start numbet for proxmox LXC container ids"
  type        = number
  default     = 500
}

variable "start_ip_cidr" {
  description = "The starting IP in CIDR notation for the LXC containers (e.g., '10.0.0.100/24'). The IPs for the containers will be sequential from this starting address."
  type        = string
  default     = "10.0.0.100/24"
}

variable "network_gateway" {
  description = "The gateway address for the container network"
  type        = string
  default     = "10.0.0.10" # You can change this to your default gateway
}

variable "etcd_count" {
  description = "The number of etcd nodes to create."
  type        = number
  default     = 3
}

variable "control_plane_count" {
  description = "The number of control-plane nodes to create."
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "The number of worker nodes to create."
  type        = number
  default     = 2
}

variable "worker_cores" {
  description = "The number of CPU cores for each worker node."
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "The amount of memory (in MB) for each worker node."
  type        = number
  default     = 8192
}

variable "worker_disk_size" {
  description = "The disk size for each worker node."
  type        = string
  default     = "50G"
}

variable "worker_storage" {
  description = "The storage pool for the worker VM disks."
  type        = string
  default     = "local-lvm"
}

variable "vm_template" {
  description = "The template to clone for creating the worker nodes."
  type        = string
  default     = "ubuntu-22.04-template"
}

variable "ostemplate" {
  description = "The path to the LXC OS template that will be used to provision the containers."
  type        = string
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

variable "rootfs_storage" {
  description = "The storage pool in Proxmox where the root filesystem of the LXC containers will be stored."
  type        = string
  default     = "local-lvm"
}

variable "rootfs_size" {
  description = "The size of the root filesystem for each LXC container, specified in gigabytes (e.g., '8G')."
  type        = string
  default     = "8G"
}

variable "ssh_public_keys" {
  description = "The SSH public key(s) used for authenticating into the LXC containers after they are provisioned."
  type        = string
}
