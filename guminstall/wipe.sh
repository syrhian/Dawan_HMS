#!/bin/bash

disk=$(lsblk -no NAME,TYPE,SIZE | awk '$2=="disk" {print $1, "(" $3 ")"}' | \
  gum choose --header "Sélectionner le disque à utiliser pour l'installation :" | awk '{print $1}')

disk_encrypt() {
  local cryptpass confirm

  while true; do
    cryptpass=$(gum input --password --header "Choix de la passphrase : ")
    confirm=$(gum input --password --header "Confirmer la passphrase : ")

    if [ "$cryptpass" != "$confirm" ]; then
      gum spin -a "right" --spinner dot --spinner.foreground "196" --title "❌ Les passphrases ne correspondent pas, réessayez..." -- bash -c 'read -n 1 -s'
    else
      break
    fi
  done

  # Lancement du chiffrement
  gum spin --title "Encryptage avec LUKS ..." -- bash -c "echo -n '$cryptpass' | sudo cryptsetup luksFormat /dev/${disk}2 --batch-mode --key-file=-" > /dev/null
  gum spin --title "Accès a la partition." -- bash -c "echo -n '$cryptpass' | sudo cryptsetup open /dev/${disk}2 root --key-file=-" > /dev/null
}

# netoyage de la partition sélectioné
gum spin --title "Nettoyage des partitions" -- bash -c "wipefs -a /dev/$disk
sgdisk --zap-all /dev/$disk" > /dev/null

# création de partitions gpt et efi
gum spin --title "Création des partitions" -- bash -c "
parted /dev/$disk -- mklabel gpt
parted /dev/$disk -- mkpart ESP fat32 1MiB 512MiB
parted /dev/$disk -- set 1 esp on
parted /dev/$disk -- mkpart primary btrfs 512MiB 100%
" > /dev/null

# boot
gum spin --title "formatage du boot" -- bash -c "
mkfs.fat -F32 /dev/${disk}1
" > /dev/null

#root
disk_encrypt
gum spin --title "formatage du root" -- bash -c "
mkfs.btrfs /dev/mapper/root
" > /dev/null

#sous-volumes btrfs
gum spin --title "Création des sous-volumes Btrfs" -- bash -c "
mount /dev/mapper/root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt 
" > /dev/null

# Montage des systèmes de fichiers
mount -o subvol=@ /dev/mapper/root /mnt > /dev/null
mkdir -p /mnt/{boot,home,snapshots} > /dev/null
mount -o subvol=@home /dev/mapper/root /mnt/home > /dev/null
mount -o subvol=@snapshots /dev/mapper/root /mnt/snapshots > /dev/null
mount /dev/${disk}1 /mnt/boot > /dev/null

