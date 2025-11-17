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
  gum spin --title "Encryptage avec LUKS ..." -- bash -c "echo -e -n '$cryptpass' | sudo cryptsetup luksFormat /dev/${disk}2 --batch-mode --key-file=-" > /dev/null
  echo -e " * Encryptage avec LUKS [\e[32m✔ \e[0m]"
  gum spin --title "Accès a la partition." -- bash -c "echo -e -n '$cryptpass' | sudo cryptsetup open /dev/${disk}2 root --key-file=-" > /dev/null
  echo -e " * Accès a la partition [\e[32m✔ \e[0m]"
}

# netoyage de la partition sélectioné
gum spin --title "Nettoyage des partitions" -- bash -c "wipefs -a /dev/$disk
sgdisk --zap-all /dev/$disk" > /dev/null
echo -e " * Nettoyage des partitions [\e[32m✔ \e[0m]"

# création de partitions gpt et efi
gum spin --title "Création des partitions" -- bash -c "
parted /dev/$disk -- mklabel gpt
parted /dev/$disk -- mkpart ESP fat32 1MiB 512MiB
parted /dev/$disk -- set 1 esp on
parted /dev/$disk -- mkpart primary btrfs 512MiB 100%
" > /dev/null
echo -e " * Création des partitions [\e[32m✔ \e[0m]"

# boot
gum spin --title "formatage du boot" -- bash -c "
mkfs.fat -F32 /dev/${disk}1
" > /dev/null
echo -e " * formatage du boot [\e[32m✔ \e[0m]"

#root
disk_encrypt
gum spin --title "formatage du root" -- bash -c "
mkfs.btrfs /dev/mapper/root
" > /dev/null
echo -e " * formatage du root [\e[32m✔ \e[0m]"

#sous-volumes btrfs
gum spin --title "Création des sous-volumes Btrfs" -- bash -c "
mount /dev/mapper/root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt 
" > /dev/null
echo -e " * Création des sous-volumes Btrfs [\e[32m✔ \e[0m]"

# Montage des systèmes de fichiers
echo -e " * + Montage des systèmes de fichiers "
mount -o subvol=@ /dev/mapper/root /mnt > /dev/null
echo -e "   ├── /dev/mapper/root /mnt"
mkdir -p /mnt/{boot,home,snapshots} > /dev/null
mount -o subvol=@home /dev/mapper/root /mnt/home > /dev/null
echo -e "   ├── /dev/mapper/root /mnt/home"
mount -o subvol=@snapshots /dev/mapper/root /mnt/snapshots > /dev/null
echo -e "   ├── /dev/mapper/root /mnt/snapshots"
mount /dev/${disk}1 /mnt/boot > /dev/null
echo -e "   └── /dev/${disk}1 /mnt/boot"

gum spin --title "installation des bases du système" -- bash -c "pacstrap -K /mnt base linux linux-firmware"
echo -e " * installation des bases du système [\e[32m✔ \e[0m]"

genfstab -U /mnt >> /mnt/etc/fstab
echo -e " * Génération du fstab [\e[32m✔ \e[0m]"

echo "root UUID=$(blkid -s UUID -o value /dev/sda2) none luks" > /mnt/etc/crypttab
echo -e " * Création du crypttab [\e[32m✔ \e[0m]"

gum spin --title "fermeture de luks" -- bash -c "cryptsetup close root" > /dev/null
echo -e " * fermeture de luks [\e[32m✔ \e[0m]"

