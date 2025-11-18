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

#gum spin --title "fermeture de luks" -- bash -c "cryptsetup close root" > /dev/null
#echo -e " * fermeture de luks [\e[32m✔ \e[0m]"

arch-chroot /mnt bash -c "

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

sed -i 's/^#\(fr_FR.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo 'LANG=fr_FR.UTF-8' > /etc/locale.conf
echo 'KEYMAP=fr' > /etc/vconsole.conf

echo 'archlinux' > /etc/hostname

pacman -S --noconfirm linux linux-headers linux-firmware btrfs-progs grub efibootmgr sudo networkmanager neovim

echo 'HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block encrypt filesystems btrfs fsck)' > /etc/mkinitcpio.conf
mkinitcpio -P

UUID_LUKS=$(blkid -s UUID -o value /dev/sda2)
sed -i 's|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID='$UUID_LUKS':root root=/dev/mapper/root\"|' /etc/default/grub

sed -i 's|^#GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|' /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

passwd
useradd -m -G wheel dawan
passwd dawan

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

systemctl enable NetworkManager
systemctl enable systemd-timesyncd

exit
"
#umount -R /mnt
#swapoff -a
#cryptsetup close root




