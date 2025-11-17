#!/bin/bash

# Cleanup script for Arch Linux installation

# Remove temporary files
rm -rf /tmp/*

# Remove unnecessary packages
pacman -Rns --noconfirm $(pacman -Qdtq)

# Clear the package cache
pacman -Scc --noconfirm

# Optionally, clear logs
rm -rf /var/log/*

# Exit the script
exit 0