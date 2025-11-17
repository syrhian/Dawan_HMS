#!/bin/bash

# Configure the network
echo "Configuring network..."
systemctl enable dhcpcd
systemctl start dhcpcd

# Update the system clock
echo "Updating system clock..."
timedatectl set-ntp true

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p /mnt/arch

# Mount the root partition
echo "Mounting root partition..."
mount /dev/sda1 /mnt/arch

# Prepare for installation
echo "Preparing for installation..."
pacstrap /mnt/arch base linux linux-firmware vim

# Generate fstab
echo "Generating fstab..."
genfstab -U /mnt/arch >> /mnt/arch/etc/fstab

echo "Setup completed. Proceed with the installation."