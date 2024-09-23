#!/bin/bash

# Arguments passed to the script
CONTROL_PLANE_ID=${1}   # ID of the control-plane node (e.g., 1, 2, 3)
CONTROL_PLANE_IP=${2}   # The IP of the current control-plane node
ETCD_ENDPOINTS=${3}     # A comma-separated list of etcd endpoints (e.g., https://192.168.5.100:2379,https://192.168.5.101:2379,https://192.168.5.102:2379)

# Update and install required packages
apt-get update
apt-get install -y curl

# Download and install k0s
curl -sSLf https://get.k0s.sh | sudo sh

# Create k0s configuration file using external etcd
k0s config create --role=controller --storage=etcd > /etc/k0s/k0s.yaml

# Update the k0s configuration to include the external etcd cluster
sed -i "s|https://127.0.0.1:2379|${ETCD_ENDPOINTS}|g" /etc/k0s/k0s.yaml

# Add current node's IP to the cluster config
sed -i "s|address: 127.0.0.1|address: ${CONTROL_PLANE_IP}|g" /etc/k0s/k0s.yaml

# Initialize the k0s control-plane node
k0s install controller --single

# Start k0s service
k0s start

# Enable k0s service to start on boot
systemctl enable k0s
