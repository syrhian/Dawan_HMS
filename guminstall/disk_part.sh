#!/bin/bash

export GUM_SPIN_PADDING="0 1"
export GUM_SPIN_SPINNER_FOREGROUND="196"

LOG=arch_install.log

disk=$(lsblk -no NAME,TYPE,SIZE | awk '$2=="disk" {print $1, "(" $3 ")"}' | \
  gum choose --header "Sélectionner le disque à utiliser pour l'installation :" | awk '{print $1}')

export USER="dawan"
export PASSWD="p"

export PACKAGES="linux-headers btrfs-progs grub efibootmgr"
#export PACSTRAP="linux base base-devel linux-firmware neovim nano cryptsetup btrfs-progs dosfstools util-linux git unzip sbctl networkmanager sudo grub efibootmgr"

cr() {
    arch-chroot /mnt "$@"
}
export -f cr

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
  if gum spin --title "+ Chiffrement avec LUKS ..." -- bash -c "
  {
  echo -e -n '$cryptpass' | sudo cryptsetup luksFormat /dev/${disk}2 --batch-mode --key-file=-
  } >> ${LOG} 2>&1
  "; then
      echo -e " * + Chiffrement avec LUKS [\e[32m✔ \e[0m]"
  else
      echo -e " * + Chiffrement avec LUKS [\e[31m✖ \e[0m]"
  fi

  # Ouverture de la partition chiffrée
  if gum spin --title "└── Accès a la partition." -- bash -c "
  {
  echo -e -n '$cryptpass' | sudo cryptsetup open /dev/${disk}2 root --key-file=-
  } >> ${LOG} 2>&1
  "; then
      echo -e "   └── Accès a la partition [\e[32m✔ \e[0m]"
  else
      echo -e "   └── Accès a la partition [\e[31m✖ \e[0m]"
  fi
}

# netoyage de la partition sélectioné
if gum spin --title "Nettoyage des partitions" -- bash -c "
{
umount -R /mnt
wipefs -a /dev/$disk
sgdisk --zap-all /dev/$disk
} >> ${LOG} 2>&1
"; then
    echo -e " * Nettoyage des partitions [\e[32m✔ \e[0m]"
else
    echo -e " * Nettoyage des partitions [\e[31m✖ \e[0m]"
fi

# création de partitions gpt et efi
if gum spin --title "Création des partitions" -- bash -c "
{
parted /dev/$disk -- mklabel gpt
parted /dev/$disk -- mkpart ESP fat32 1MiB 512MiB
parted /dev/$disk -- set 1 esp on
parted /dev/$disk -- mkpart primary btrfs 512MiB 100%
} >> ${LOG} 2>&1
"; then
    echo -e " * Création des partitions [\e[32m✔ \e[0m]"
else
    echo -e " * Création des partitions [\e[31m✖ \e[0m]" 
fi

# boot
if gum spin --title "formatage du boot" -- bash -c "
mkfs.fat -F32 /dev/${disk}1 >> ${LOG} 2>&1
"; then
    echo -e " * formatage du boot [\e[32m✔ \e[0m]"
else
    echo -e " * formatage du boot [\e[31m✖ \e[0m]"
fi

#root
disk_encrypt
if gum spin --title "formatage du root" -- bash -c "
mkfs.btrfs -f -L root /dev/mapper/root >> ${LOG} 2>&1
"; then
    echo -e " * formatage du root [\e[32m✔ \e[0m]"
else
    echo -e " * formatage du root [\e[31m✖ \e[0m]"
fi

#sous-volumes btrfs
if gum spin --title "Création des sous-volumes Btrfs" -- bash -c "
{
mount /dev/mapper/root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt
} >> ${LOG} 2>&1
"; then
    echo -e " * Création des sous-volumes Btrfs [\e[32m✔ \e[0m]"
else
    echo -e " * Création des sous-volumes Btrfs [\e[31m✖ \e[0m]"
fi

# Montage des partitions
echo -e " * + Montage des partitions "
mount -o subvol=@ /dev/mapper/root /mnt >> $LOG 2>&1
echo -e "   ├── /dev/mapper/root /mnt"
mkdir -p /mnt/{boot,home,snapshots} >> $LOG 2>&1
mount -o subvol=@home /dev/mapper/root /mnt/home >> $LOG 2>&1
echo -e "   ├── /dev/mapper/root /mnt/home"
mount -o subvol=@snapshots /dev/mapper/root /mnt/snapshots >> $LOG 2>&1
echo -e "   ├── /dev/mapper/root /mnt/snapshots"
mount /dev/${disk}1 /mnt/boot >> $LOG 2>&1
echo -e "   └── /dev/${disk}1 /mnt/boot"

if gum spin --title "installation des bases du système" -- bash -c "
pacstrap -K /mnt linux base base-devel linux-firmware neovim nano cryptsetup btrfs-progs dosfstools util-linux git unzip sbctl networkmanager sudo grub efibootmgr >> ${LOG} 2>&1
"; then
    echo -e " * installation des bases du système [\e[32m✔ \e[0m]"
else
    echo -e " * installation des bases du système [\e[31m✖ \e[0m]"
fi

if gum spin --title "génération du fstab" -- bash -c "
{
genfstab -U /mnt >> /mnt/etc/fstab
} >> ${LOG} 2>&1
"; then
    echo -e " * génération du fstab [\e[32m✔ \e[0m]"
else
    echo -e " * génération du fstab [\e[31m✖ \e[0m]"
fi

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

tzn() {
    cr ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    cr hwclock --systohc
}
export -f tzn

if gum spin --title "configuration timezone et horloge système" -- bash -c "
{
tzn
} >> ${LOG} 2>&1
"; then
    echo -e " * configuration timezone et horloge système [\e[32m✔ \e[0m]"
else
    echo -e " * configuration timezone et horloge système [\e[31m✖ \e[0m]"
fi

lcls() {
    cr sed -i "s/^#\(fr_FR.UTF-8 UTF-8\)/\1/" /etc/locale.gen
    cr locale-gen
    echo "LANG=fr_FR.UTF-8" > /mnt/etc/locale.conf
    echo "KEYMAP=fr" > /mnt/etc/vconsole.conf
}
export -f lcls

if gum spin --title "configuration locale et clavier" -- bash -c "
{
lcls
} >> $LOG 2>&1
"; then
    echo -e " * configuration locale et clavier [\e[32m✔ \e[0m]"
else
    echo -e " * configuration locale et clavier [\e[31m✖ \e[0m]"
fi

if gum spin --title "configuration du hostname" -- bash -c "
{
echo "archlinux" > /etc/hostname
} >> ${LOG} 2>&1
"; then
    echo -e " * configuration du hostname [\e[32m✔ \e[0m]"
else
    echo -e " * configuration du hostname [\e[31m✖ \e[0m]"
fi

if gum spin --title "installation des paquets" -- bash -c "
cr pacman -S --noconfirm ${PACKAGES} >> $LOG 2>&1
"; then
    echo -e " * installation des paquets $PACKAGES [\e[32m✔ \e[0m]"
else
    echo -e " * installation des paquets $PACKAGES [\e[31m✖ \e[0m]"
fi

dd if=/dev/urandom of=/mnt/crypto_keyfile.bin bs=512 count=8
chmod 000 /mnt/crypto_keyfile.bin
chown root:root /mnt/crypto_keyfile.bin
cryptsetup luksAddKey /dev/${disk}2 /mnt/crypto_keyfile.bin

if gum spin --title "configuration du mot de passe root" -- bash -c "
{
cr chpasswd <<<\"root:\"$PASSWD\"\"
} >> ${LOG} 2>&1
"; then
    echo -e " * configuration du mot de passe root [\e[32m✔ \e[0m]"
else
    echo -e " * configuration du mot de passe root [\e[31m✖ \e[0m]"
fi

if gum spin --title "création de l'utilisateur" -- bash -c "
cr useradd -m -G wheel \"$USER\" >> $LOG 2>&1
"; then
    echo -e " * création de l'utilisateur $USER [\e[32m✔ \e[0m]"
else
    echo -e " * création de l'utilisateur $USER [\e[31m✖ \e[0m]"
fi

if gum spin --title "configuration sudoers" -- bash -c "
{
cr chpasswd <<<\"\"$USER\":\"$PASSWD\"\"
} >> ${LOG} 2>&1
"; then
    echo -e " * configuration du mot de passe de l'utilisateur $USER [\e[32m✔ \e[0m]"
else
    echo -e " * configuration du mot de passe de l'utilisateur $USER [\e[31m✖ \e[0m]"  
fi

cr sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

cat << EOF > /mnt/etc/mkinitcpio.conf
FILES="/crypto_keyfile.bin"
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap block encrypt btrfs filesystems fsck)
EOF

UUID_GRUB=$(blkid -s UUID -o value /dev/${disk}2)

#cat << EOF > /mnt/etc/crypttab
#root UUID=${UUID_GRUB} /boot/secure/crypto_keyfile.bin luks,discard
#EOF

sed -i \
"s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=7\ cryptkey=rootfs:/crypto_keyfile.bin root=/dev/mapper/root\ cryptdevice=UUID=${UUID_GRUB}:root\ rootflags=subvol=@\"|" \
/mnt/etc/default/grub

sed -i \
"s|^#GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|" \
/mnt/etc/default/grub

if gum spin --title "génération des images initramfs" -- bash -c "
cr mkinitcpio -P >> ${LOG} 2>&1
"; then
    echo -e " * génération des images initramfs [\e[32m✔ \e[0m]"
else
    echo -e " * génération des images initramfs [\e[31m✖ \e[0m]"
fi

if gum spin --title "installation de grub" -- bash -c "
cr grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB >> ${LOG} 2>&1
"; then
    echo -e " * installation de grub [\e[32m✔ \e[0m]"
else
    echo -e " * installation de grub [\e[31m✖ \e[0m]"
fi

if gum spin --title "génération de la configuration de grub" -- bash -c "
cr grub-mkconfig -o /boot/grub/grub.cfg >> ${LOG} 2>&1
"; then
    echo -e " * génération de la configuration de grub [\e[32m✔ \e[0m]"
else
    echo -e " * génération de la configuration de grub [\e[31m✖ \e[0m]"
fi

if gum spin --title "activation des services" -- bash -c "
{
systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager && \
systemctl --root /mnt mask systemd-networkd
} >> ${LOG} 2>&1
"; then
    echo -e " * Activation des services [\e[32m✔ \e[0m]"
else
    echo -e " * Activation des services [\e[31m✖ \e[0m]"
fi

#umount -R /mnt
debug(){
cat /mnt/etc/default/grub | grep GRUB_CMDLINE_LINUX_DEFAULT
cat /mnt/etc/locale.gen | grep fr_FR.UTF-8
cat /mnt/etc/mkinitcpio.conf
cat /mnt/etc/fstab
cat /mnt/etc/crypttab
cat /mnt/etc/mkinitcpio.d/linux.preset
ls /mnt/boot
}
debug