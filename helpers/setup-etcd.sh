#!/bin/bash

# Disable services and apply necessary pre-configuration
setenforce 0

# Get the node index and IP address from the arguments
ETCD_NODE_NAME=${1}
ETCD_IP_ADDRESS=${2}
ETCD_INITIAL_CLUSTER=${3}

# Disable SELinux (if applicable on Ubuntu systems)
if [ -f /etc/selinux/config ]; then
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi

# Stop and disable any network managers or firewalls that could interfere
for service in ufw NetworkManager; do
    systemctl disable $service
    systemctl stop $service
done

# Update firewall rules if UFW is still enabled
if command -v ufw &> /dev/null; then
    ufw allow 2379/tcp
    ufw allow 2380/tcp
    ufw reload
fi

# Update the package list and install necessary packages
apt-get update -y

# Download and install etcd & etcdctl
wget -q --show-progress "https://github.com/etcd-io/etcd/releases/download/v3.5.0/etcd-v3.5.0-linux-amd64.tar.gz"
tar zxf etcd-v3.5.0-linux-amd64.tar.gz

# Installing etcd and etcdctl
mv etcd-v3.5.0-linux-amd64/etcd* /usr/bin/
chmod +x /usr/bin/etcd*

# Setting up Configurations for etcd
cat <<EOF >/etc/etcd
ETCD_NAME=etcd-node-${ETCD_NODE_NAME}
ETCD_DATA_DIR=/var/lib/etcd
ETCD_LISTEN_CLIENT_URLS=http://${ETCD_IP_ADDRESS}:2379,http://127.0.0.1:2379
ETCD_LISTEN_PEER_URLS=http://${ETCD_IP_ADDRESS}:2380
ETCD_ADVERTISE_CLIENT_URLS=http://${ETCD_IP_ADDRESS}:2379
ETCD_INITIAL_ADVERTISE_PEER_URLS=http://${ETCD_IP_ADDRESS}:2380
ETCD_INITIAL_CLUSTER=${ETCD_INITIAL_CLUSTER}
ETCD_INITIAL_CLUSTER_STATE=new
ETCD_INITIAL_CLUSTER_TOKEN=etcd-cluster
EOF

# Setting up etcd systemd service file
cat <<EOF >/etc/systemd/system/etcd.service
[Unit]
Description=etcd

[Service]
Type=notify
EnvironmentFile=/etc/etcd
ExecStart=/usr/bin/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etcd
service etcd start