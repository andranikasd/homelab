#!/bin/bash

# Arguments passed to the script
WORKER_ID=${1}   # ID of the worker node (e.g., 1, 2, 3)
WORKER_IP=${2}   # IP address of the current worker node

# Update and install required packages
apt-get update
apt-get install -y curl

# Download and install k0s
curl -sSLf https://get.k0s.sh | sudo sh

# Install k0s as a worker node
k0s install worker

# Start k0s service
k0s start

# Enable k0s service to start on boot
systemctl enable k0s

# Retrieve the k0s join token from the control-plane (you need to manually provide the correct IP or retrieve it dynamically)
JOIN_TOKEN=$(curl -s http://control-plane-1:8080/v1beta1/token)

# Join the worker node to the k0s cluster
k0s worker join --token ${JOIN_TOKEN} --api-server=https://control-plane-1:6443
