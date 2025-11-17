#!/bin/bash

# Install required packages for VirtualBox Guest Additions
pacman -Sy --noconfirm linux-headers virtualbox-guest-utils

# Load the VirtualBox Guest Additions kernel modules
modprobe -a vboxguest vboxsf vboxvideo

# Enable the VirtualBox Guest Additions services
systemctl enable vboxadd.service
systemctl enable vboxadd-service.service

# Start the VirtualBox Guest Additions services
systemctl start vboxadd.service
systemctl start vboxadd-service.service

# Clean up
pacman -Scc --noconfirm