#!/usr/bin/env bash
set -euxo pipefail

# Speed up pacman and add some niceties
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf || true
echo 'ILoveCandy' >> /etc/pacman.conf || true

# Refresh keys and system
pacman -Sy --noconfirm archlinux-keyring
pacman -Syu --noconfirm --needed base

# Core tools (variable list is not trivial in pacman; expand default here)
pacman -S --noconfirm --needed sudo git curl neovim zsh tmux python python-pip jq yq

# Create non-root user
USERNAME=${USERNAME:-dawan}
UID=${UID:-1000}
GID=${GID:-1000}

if ! getent group "$GID" >/dev/null; then
  groupadd -g "$GID" "$USERNAME" || true
fi
if ! id -u "$UID" >/dev/null 2>&1; then
  useradd -m -u "$UID" -g "$GID" -s /bin/zsh "$USERNAME" || true
fi

echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/99-$USERNAME
chmod 0440 /etc/sudoers.d/99-$USERNAME

# Default shell tweaks
printf 'export EDITOR=nvim\n' >> /etc/zsh/zshrc
printf 'alias ll="ls -alF"\n' >> /etc/zsh/zshrc

# Cleanup
pacman -Scc --noconfirm || true
rm -rf /var/cache/pacman/pkg/* /tmp/*
