#!/bin/bash

# Set the timezone
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

# Generate locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set the hostname
echo "archlinux" > /etc/hostname

# Configure hosts file
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.0.1   archlinux.localdomain archlinux
EOF

# Install base packages
pacman -Sy --noconfirm base linux linux-firmware vim

# Set root password
echo "root:password" | chpasswd

# Enable necessary services
systemctl enable dhcpcd

# Clean up
pacman -Scc --noconfirm

# Exit the script
exit 0