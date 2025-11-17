#!/usr/bin/bash
set -eu

echo "Installing and enabling SSH"
pacman -Sy --noconfirm openssh
systemctl enable sshd
systemctl start sshd

echo "Creating user dawan"
useradd -m -G wheel -s /bin/bash dawan
echo "dawan:Passw0rd" | chpasswd
echo "dawan ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dawan


