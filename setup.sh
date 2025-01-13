#!/bin/bash

# Docker installation
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc


echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


if ! getent group docker > /dev/null 2>&1; then
    sudo groupadd docker
fi


if ! groups $USER | grep -q docker; then
    sudo usermod -aG docker $USER
    echo "User added to docker group. Please log out and log back in for changes to take effect."
fi



# Add Ubuntu repository
sudo sh -c 'echo "deb http://archive.ubuntu.com/ubuntu jammy main universe" > /etc/apt/sources.list'

# Update and install ZFS utils
sudo apt-get update
sudo apt-get install -y zfsutils-linux

# Check if /dev/sdb exists
if [ ! -e /dev/sdb ]; then
    echo "Error: /dev/sdb does not exist"
    exit 1
fi

# Create GPT label
echo "mklabel gpt" | sudo parted /dev/sdb

# Create ZFS pool and dataset
sudo zpool create -o ashift=12 -O atime=off -O canmount=off -O compression=lz4 data_pool /dev/sdb
if [ $? -eq 0 ]; then
    sudo zfs create -o mountpoint=/questdb_zfs data_pool/primary
else
    echo "Error: Failed to create ZFS pool"
    exit 1
fi