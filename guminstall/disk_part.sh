#!/bin/bash

disk=$(lsblk -no NAME,TYPE,SIZE | awk '$2=="disk" {print $1, "(" $3 ")"}' | \
  gum choose --header "Sélectionner le disque à utiliser pour l'installation :" | awk '{print $1}')

export PASSWD="p"

cr() {
    arch-chroot /mnt "$@"
}

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
  gum spin --title "Chiffrement avec LUKS ..." -- bash -c "echo -e -n '$cryptpass' | sudo cryptsetup luksFormat /dev/${disk}2 --batch-mode --key-file=-" > /dev/null
  echo -e " * Chiffrement avec LUKS [\e[32m✔ \e[0m]"
  gum spin --title "Accès a la partition." -- bash -c "echo -e -n '$cryptpass' | sudo cryptsetup open /dev/${disk}2 root --key-file=-" > /dev/null
  echo -e " * Accès a la partition [\e[32m✔ \e[0m]"
}

# netoyage de la partition sélectioné
gum spin --title "Nettoyage des partitions" -- bash -c "
umount -R /mnt
wipefs -a /dev/$disk
sgdisk --zap-all /dev/$disk
" > /dev/null
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
mkfs.btrfs -f -L root /dev/mapper/root
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

# Montage des partitions
echo -e " * + Montage des partitions "
mount -o subvol=@ /dev/mapper/root /mnt > /dev/null
echo -e "   ├── /dev/mapper/root /mnt"
mkdir -p /mnt/{boot,home,snapshots} > /dev/null
mount -o subvol=@home /dev/mapper/root /mnt/home > /dev/null
echo -e "   ├── /dev/mapper/root /mnt/home"
mount -o subvol=@snapshots /dev/mapper/root /mnt/snapshots > /dev/null
echo -e "   ├── /dev/mapper/root /mnt/snapshots"
mount /dev/${disk}1 /mnt/boot > /dev/null
echo -e "   └── /dev/${disk}1 /mnt/boot"

gum spin --title "installation des bases du système" -- bash -c "pacstrap -K /mnt linux base base-devel linux-firmware neovim nano cryptsetup btrfs-progs dosfstools util-linux git unzip sbctl networkmanager sudo grub efibootmgr"
echo -e " * installation des bases du système [\e[32m✔ \e[0m]"

gum spin --title "installation des bases du système" -- bash -c "genfstab -U /mnt >> /mnt/etc/fstab"
echo -e " * génération du fstab [\e[32m✔ \e[0m]"

cat << 'EOF' > /mnt/etc/mkinitcpio.d/linux.preset
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
ALL_microcode=(/boot/*-ucode.img)

PRESETS=('default' 'fallback')

default_image="/boot/initramfs-linux.img"
default_options=""

fallback_image="/boot/initramfs-linux-fallback.img"
fallback_options="-S autodetect"
EOF

cr ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
cr hwclock --systohc
echo -e " * définition timezone et horloge système [\e[32m✔ \e[0m]"

cr sed -i 's/^#\(fr_FR.UTF-8 UTF-8\)/\1/' /etc/locale.gen
cr locale-gen
cr echo 'LANG=fr_FR.UTF-8' > /etc/locale.conf
cr echo 'KEYMAP=fr' > /etc/vconsole.conf
echo -e " * configuration locales et clavier [\e[32m✔ \e[0m]"

cr echo 'archlinux' > /etc/hostname
echo -e " * configuration du hostname [\e[32m✔ \e[0m]"

cr pacman -S --noconfirm linux-headers btrfs-progs grub efibootmgr
echo -e " * installation des paquets grub efibootmgr linux-headers btrfs-progs [\e[32m✔ \e[0m]"

#mkdir /mnt/boot/secure
#dd if=/dev/urandom of=/mnt/boot/secure/crypto_keyfile.bin bs=512 count=8
#chmod 000 /mnt/boot/secure/*
#chmod 600 /mnt/boot/initramfs-linux*
#cryptsetup luksAddKey /dev/sda2 /mnt/boot/secure/crypto_keyfile.bin
#passwd

cr chpasswd <<<"root:$PASSWD"
echo -e " * configuration du mot de passe root [\e[32m✔ \e[0m]"
cr useradd -m -G wheel dawan
cr chpasswd <<<"dawan:$PASSWD"
echo -e " * création de l'utilisateur dawan [\e[32m✔ \e[0m]"

cr sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

cat << EOF > /mnt/etc/mkinitcpio.conf
#FILES="/boot/secure/crypto_keyfile.bin"
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap block encrypt btrfs filesystems fsck)
EOF
echo -e " * configuration mkinitcpio.conf [\e[32m✔ \e[0m]"

UUID_GRUB=$(blkid -s UUID -o value /dev/sda2)

#cat << EOF > /mnt/etc/crypttab
#root UUID=${UUID_GRUB} /boot/secure/crypto_keyfile.bin luks,discard
#EOF


sed -i \
"s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=loglevel=7\ root=/dev/mapper/root\ cryptdevice=UUID=${UUID_GRUB}:root\ rootflags=subvol=@|" \
/mnt/etc/default/grub

sed -i \
"s|^#GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|" \
/mnt/etc/default/grub
echo -e " * configuration grub [\e[32m✔ \e[0m]"

cr mkinitcpio -P
echo -e " * génération des images initramfs [\e[32m✔ \e[0m]"

cr grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
cr grub-mkconfig -o /boot/grub/grub.cfg
echo -e " * installation de grub [\e[32m✔ \e[0m]"


systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager
systemctl --root /mnt mask systemd-networkd
echo -e " * Activation des services [\e[32m✔ \e[0m]"

#umount -R /mnt
#swapoff -a
#cryptsetup close root

cat /mnt/etc/default/grub | grep GRUB_CMDLINE_LINUX_DEFAULT
cat /mnt/etc/locale.gen | grep fr_FR.UTF-8
cat /mnt/etc/mkinitcpio.conf
cat /mnt/etc/fstab
#cat /mnt/etc/crypttab
cat /mnt/etc/mkinitcpio.d/linux.preset
ls /mnt/boot
