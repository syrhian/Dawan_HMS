#!/bin/bash

# var
disk=$(lsblk -no NAME,TYPE,SIZE | awk '$2=="disk" {print $1, "(" $3 ")"}' | \
gum choose --header "Sélectionner le disque à utiliser pour l'installation :" | awk '{print $1}')

pak_strap="base base-devel linux linux-firmware neovim nano cryptsetup btrfs-progs dosfstools util-linux git unzip sbctl networkmanager sudo grub efibootmgr"

export UUID_GRUB=$(blkid -s UUID -o value /dev/sda2)

# fonction(s)
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
  gum_s " * + Chiffrement avec LUKS ..." bash -c "echo -e -n '$cryptpass' | sudo cryptsetup luksFormat /dev/${disk}2 --batch-mode --key-file=-"
  gum_s "   └── Accès a la partition." bash -c "echo -e -n '$cryptpass' | sudo cryptsetup open /dev/${disk}2 root --key-file=-"
}

cr() {
    arch-chroot /mnt "$@"
}

gum_s() {
    local title="$1"
    shift
    if output=$(gum spin --title "$title" -- "$@" 2>&1); then
        echo -e "$title [\e[32m✔ \e[0m]"
    else
        echo -e "$title [\e[31m✖ \e[0m]"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $title" >> install_error.log
        echo "-------------------" >> install_error.log
        echo $output >> install_error.log
    fi
}

mkinitcpio_preset() {
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
}

mkinitcpio_conf() {
cat > /etc/mkinitcpio.conf << 'EOF'
FILES=(/secure/crypto_keyfile.bin)
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap block encrypt btrfs filesystems fsck)
EOF
}

crypttab_config() {
cat > /etc/crypttab <<EOF
root UUID=$UUID_GRUB /secure/crypto_keyfile.bin luks,discard
EOF
}

grub_config() {
    cr sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=7 root=/dev/mapper/root cryptdevice=UUID=$UUID_GRUB:root rootflags=subvol=@\"|" /etc/default/grub
    cr sed -i 's|^#GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|' /etc/default/grub
}

create_btrfs_subvolumes() {
    mount /dev/mapper/root /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    umount /mnt
}

partitionnement() {
    echo "    ├── création de la table de partition gpt"
    parted /dev/$disk -- mklabel gpt
    echo "    ├── création de la partition efi"
    parted /dev/$disk -- mkpart ESP fat32 1MiB 512MiB
    parted /dev/$disk -- set 1 esp on
    echo "    └── création de la partition root"
    parted /dev/$disk -- mkpart primary btrfs 512MiB 100%
}

clean_partitions() {
    echo "    ├── démontage de /mnt"
    umount -R /mnt
    echo "    ├── suppression des signatures du fs"
    wipefs -a /dev/$disk
    echo "    └── suppression des tables de partitions"
    sgdisk --zap-all /dev/$disk
}

###################################################

# netoyage de la partition sélectioné
gum_s " * + Nettoyage des partitions" clean_partitions

# création de partitions gpt et efi
gum_s " * + Création des partitions" partitionnement

# boot
gum_s " *   formatage du boot" mkfs.fat -F32 /dev/${disk}1


#root
disk_encrypt
gum_s " *   formatage du root" mkfs.btrfs -f -L root /dev/mapper/root

#sous-volumes btrfs
gum_s " *   Création des sous-volumes Btrfs" create_btrfs_subvolumes

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

gum_s " *   installation des bases du système" pacstrap -K /mnt $pak_strap

gum_s " *   génération du fstab" genfstab -U /mnt >> /mnt/etc/fstab

gum_s " *   création du preset mkinitcpio" mkinitcpio_preset

cfg_base() {
## arch-chroot /mnt
# timezone + horloge
echo "    ├── timezone Europe/Paris"
cr ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
echo "    └── synchronisation de l'horloge"
cr hwclock --systohc

# locales
echo "    + configuration des locales"
echo "    ├── fr_FR.UTF-8 UTF-8"
cr sed -i 's/^#\(fr_FR.UTF-8 UTF-8\)/\1/' /etc/locale.gen
echo "    ├── génération des locales"
cr locale-gen
echo "    ├── configuration des fichiers de locale"
cr bash -c "echo 'LANG=fr_FR.UTF-8' > /etc/locale.conf"
echo "    └── configuration du clavier sur français (AZERTY)"
cr bash -c "echo 'KEYMAP=fr' > /etc/vconsole.conf"

# hostname
echo "    + configuration du hostname"
echo "    └── archlinux"
cr bash -c "echo 'archlinux' > /etc/hostname"

# paquets
echo "    + installation des paquets supplémentaires"
cr pacman -S --noconfirm linux-headers btrfs-progs grub efibootmgr 

# keyfile
echo "    + création et configuration du keyfile"
echo "    ├── création du répertoire /secure"
cr mkdir /secure
echo "    ├── génération de la clé (/secure/crypto_keyfile.bin)"
cr dd if=/dev/urandom of=/secure/crypto_keyfile.bin bs=512 count=8
echo "    ├── restriction des permissions (000)"
cr chmod 000 /secure/crypto_keyfile.bin
echo "    └── ajout de la clé à LUKS"
cr cryptsetup luksAddKey /dev/sda2 /secure/crypto_keyfile.bin

# utilisateurs
echo "    + création d'un utilisateur avec droits sudo"
echo "    ├── mdp root"
cr passwd
echo "    ├── création de l'utilisateur sudo"
cr useradd -m -G wheel dawan
echo "    ├── mdp utilisateur"
cr passwd dawan
echo "    └── configuration de sudoers pour le groupe wheel"
cr sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# mkinitcpio.conf
cr mkinitcpio_conf

# crypttab
cr crypttab_config

# config grub
grub_config

# regen initramfs
cr mkinitcpio -P

# grub install
cr grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
cr grub-mkconfig -o /boot/grub/grub.cfg
}


gum_s " * + configuration des bases" cfg_base




#umount -R /mnt
#swapoff -a
#cryptsetup close root

