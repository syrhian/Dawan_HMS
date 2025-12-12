#!/bin/bash
## --------------------------------------- Logo ---------------------------------------
    logo() {
    RED="\e[31m"
    WHITE="\e[97m"
    BLUE="\e[94m"
    RESET="\e[0m"

    echo -e "${RED}                            @@@@@@@          ";
    echo -e "${RED}                      @@@@@@@@@@@@@          ";
    echo -e "${RED}                  @@@@@@@@@@@@@@@@@@         ";
    echo -e "${RED}            @@@@@@@@@@@@@@@@@@@@@@@@@        ";
    echo -e "${RED}        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       ";
    echo -e "${RED}    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       ";
    echo -e "${RED}    @@@@@@@@@@@@@@@@${WHITE}%%${RED}@@@@@@@@@@@@@@@@@                   ${RESET}${BLUE}╔══════════════════════════════════════════════════════════════╗";
    echo -e "${RED}    @@@@@@@@@@@@@@@@${WHITE}%%%${RED}@@@@@@@@@@@@@@@@                   ${RESET}${BLUE}║                                                              ║";
    echo -e "${RED}    @@@@@@@@@@@@@@@@${WHITE}%%%${RED}@@@@@@@@@@@@@@@@@                  ${RESET}${BLUE}║  ██████╗  █████╗ ██╗    ██╗ █████╗ ██████╗  ██████╗██╗  ██╗  ║";
    echo -e "${RED}     @@@@@@@@@@@@@@${WHITE}%%${RED}@${WHITE}%${RED}@@@@${WHITE}%%%${RED}@@${WHITE}%%%${RED}@@@@@@                 ${RESET}${BLUE}║  ██╔══██╗██╔══██╗██║    ██║██╔══██╗██╔══██╗██╔════╝██║  ██║  ║";
    echo -e "${RED}      @@@@@@@@@@@@@${WHITE}%%${RED}@${WHITE}%${RED}@@@@@@@@@@${WHITE}%${RED}@@@@@@@                 ${RESET}${BLUE}║  ██║  ██║███████║██║ █╗ ██║███████║██████╔╝██║     ███████║  ║";
    echo -e "${RED}      @@@@@@@@@@@@@@@@${WHITE}%%${RED}@@@@@@${WHITE}%%%${RED}@@@@@@@@@                ${RESET}${BLUE}║  ██║  ██║██╔══██║██║███╗██║██╔══██║██╔══██╗██║     ██╔══██║  ║";
    echo -e "${RED}       @@@@@@@${WHITE}%${RED}@@@@@@@@@@@@${WHITE}%%%${RED}@@@@@@@@@@@@@               ${RESET}${BLUE}║  ██████╔╝██║  ██║╚███╔███╔╝██║  ██║██║  ██║╚██████╗██║  ██║  ║";
    echo -e "${RED}       @@@@@@${WHITE}%%${RED}@@@@@@${WHITE}%%%%%%${RED}@@@@@@@@@@@@@@@@               ${RESET}${BLUE}║  ╚═════╝ ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝  ║";
    echo -e "${RED}        @@@@@${WHITE}%%%%%%%%${RED}@@@@@@@@@@@@@@@@@@@@@@@              ${RESET}${BLUE}║                                                              ║";
    echo -e "${RED}         @@@@@${WHITE}%%%${RED}@@@@@@@@@@@@@@@@@@@@@@@@@@@              ${RESET}${BLUE}╚══════════════════════════════════════════════════════════════╝";
    echo -e "${RED}          @@@@@@${WHITE}%%%%%%%%%%%${RED}@@@@@@@@@@@@@@@@@@";
    echo -e "${RED}          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ";
    echo -e "${RED}           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@     ";
    echo -e "${RED}           @@@@@@@@@@@@@@@@@@@@@@@@@         ";
    echo -e "${RED}            @@@@@@@@@@@@@@@@@@               ";
    echo -e "${RED}             @@@@@@@@@@@@@                   ";
    echo -e "${RED}             @@@@@@@                         ${RESET}";
    echo ""
    echo ""
    echo -e "${RED}================================================= ${BLUE}Début script d'installation ${RED}=================================================${RESET}"
    }
    logo

## ------------------------------------- variables ---------------------------------------

## Set gum spinner style
export GUM_SPIN_PADDING="0 3"
export GUM_CHOOSE_PADDING="0 3"
export GUM_SPIN_SPINNER_FOREGROUND="51"
export GUM_CHOOSE_CURSOR_FOREGROUND="51"
export GUM_CHOOSE_HEADER_FOREGROUND="196"
export GUM_INPUT_PROMPT_FOREGROUND="51"
export GUM_INPUT_HEADER_FOREGROUND="196"
export GUM_INPUT_CURSOR_FOREGROUND="51"

## Log install file
LOG=arch_install.log

## gather avayable disks
export disk=$(lsblk -no NAME,TYPE,SIZE | awk '$2=="disk" {print $1, "(" $3 ")"}' | \
  gum choose --header "Sélectionner le disque à utiliser pour l'installation :" | awk '{print $1}')

## hostname
export HOSTNAME="dawarch"

## user credentials
export USER="dawan"
export PASSWD="p"

## packages to install
export PACKAGES="linux-headers btrfs-progs grub efibootmgr"
export PACSTRAP="linux base base-devel linux-firmware neovim nano cryptsetup btrfs-progs dosfstools util-linux git unzip sbctl networkmanager sudo grub efibootmgr"

##--------------------------------------- Fonctions ---------------------------------------

## chroot command
cr() {
    arch-chroot /mnt "$@"
}
export -f cr

## disk encryption
disk_encrypt() {
  while true; do
    cryptpass=$(gum input --password --header "Choix de la passphrase : ")
    confirm=$(gum input --password --header "Confirmer la passphrase : ")
    if [ "$cryptpass" != "$confirm" ]; then
      gum spin -a right --spinner dot --spinner.foreground "196" --title "❌ Les passphrases ne correspondent pas, réessayez..." -- bash -c 'read -n 1 -s'
    else
      break
    fi
  done

  # Chiffrement LUKS
  if CRYPTPASS="$cryptpass" DISK="$disk" LOG="$LOG" \
     gum spin --title "Chiffrement avec LUKS ..." -- bash -e -c '
    {
      printf %s "$CRYPTPASS" | cryptsetup luksFormat "/dev/${DISK}2" --batch-mode --key-file=-
    } >> "$LOG" 2>&1
  '; then
    echo -e " [\e[32m✔ \e[0m] + Chiffrement avec LUKS"
  else
    echo -e " [\e[31m✖ \e[0m] + Chiffrement avec LUKS"
    return 1
  fi

  # Ouverture de la partition chiffrée
  if CRYPTPASS="$cryptpass" DISK="$disk" LOG="$LOG" \
     gum spin --title "└── Accès a la partition" -- bash -e -c '
    {
      printf %s "$CRYPTPASS" | cryptsetup open "/dev/${DISK}2" root --key-file=-
    } >> "$LOG" 2>&1
  '; then
    echo -e " [\e[32m✔ \e[0m] └── Accès a la partition"
  else
    echo -e " [\e[31m✖ \e[0m] └── Accès a la partition"
    return 1
  fi
}

## débug
debug(){
    cat /mnt/etc/default/grub | grep GRUB_CMDLINE_LINUX_DEFAULT
    cat /mnt/etc/locale.gen | grep fr_FR.UTF-8
    cat /mnt/etc/mkinitcpio.conf
    cat /mnt/etc/fstab
    cat /mnt/etc/crypttab
    cat /mnt/etc/mkinitcpio.d/linux.preset
    ls /mnt/boot
}
##--------------------------------------- gum spinners ---------------------------------------

## netoyage de la partition sélectioné
if gum spin --title "Nettoyage des partitions" -- bash -c "
{
umount -R /mnt
wipefs -a /dev/$disk
sgdisk --zap-all /dev/$disk
} >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Nettoyage des partitions"
else
    echo -e " [\e[31m✖ \e[0m] Nettoyage des partitions"
fi

## partitions gpt et efi
if gum spin --title "Création des partitions" -- bash -c "
{
parted /dev/$disk -- mklabel gpt
parted /dev/$disk -- mkpart ESP fat32 1MiB 512MiB
parted /dev/$disk -- set 1 esp on
parted /dev/$disk -- mkpart primary btrfs 512MiB 100%
} >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Création des partitions"
else
    echo -e " [\e[31m✖ \e[0m] Création des partitions"
fi

## formatage du boot
if gum spin --title "Formatage du boot" -- bash -c "
mkfs.fat -F32 /dev/${disk}1 >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Formatage du boot"
else
    echo -e " [\e[31m✖ \e[0m] Formatage du boot"
fi

## formatage du root
disk_encrypt
if gum spin --title "Formatage du root" -- bash -c "
mkfs.btrfs -f -L root /dev/mapper/root >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Formatage du root"
else
    echo -e " [\e[31m✖ \e[0m] Formatage du root"
fi

## créations de sous-volumes btrfs
if gum spin --title "Création des sous-volumes Btrfs" -- bash -c "
{
mount /dev/mapper/root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt
} >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Création des sous-volumes Btrfs"
else
    echo -e " [\e[31m✖ \e[0m] Création des sous-volumes Btrfs"
fi

## Montage des partitions
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

## pacstrap des bases du système
if gum spin --title "Installation des bases du système" -- bash -c "
pacstrap -K /mnt ${PACSTRAP} >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Installation des bases du système"
else
    echo -e " [\e[31m✖ \e[0m] Installation des bases du système"
fi

## génération du fstab [automatique]
if gum spin --title "Génération du fstab" -- bash -c "
{
genfstab -U /mnt >> /mnt/etc/fstab
} >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Génération du fstab"
else
    echo -e " [\e[31m✖ \e[0m] Génération du fstab"
fi

## Configuration du chemin vers les images initramfs
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

## Configuration timezone et horloge système
tzn() {
    cr ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    cr hwclock --systohc
}
export -f tzn

if gum spin --title "Configuration timezone et horloge système" -- bash -c "
{
tzn
} >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Configuration timezone et horloge système"
else
    echo -e " [\e[31m✖ \e[0m] Configuration timezone et horloge système"
fi

## Configuration locales et clavier
lcls() {
    cr sed -i "s/^#\(fr_FR.UTF-8 UTF-8\)/\1/" /etc/locale.gen
    cr locale-gen
    echo "LANG=fr_FR.UTF-8" > /mnt/etc/locale.conf
    echo "KEYMAP=fr" > /mnt/etc/vconsole.conf
}
export -f lcls

if gum spin --title "Configuration locales et clavier" -- bash -c "
{
lcls
} >> $LOG 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Configuration locales et clavier [fr_FR.UTF-8][azerty]"
else
    echo -e " [\e[31m✖ \e[0m] Configuration locales et clavier"
fi

## configuration du hostname
if gum spin --title "Configuration du hostname" -- bash -c "
{
echo ${HOSTNAME} > /etc/hostname
} >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Configuration du hostname ${HOSTNAME}"
else
    echo -e " [\e[31m✖ \e[0m] Configuration du hostname"
fi

## installation des paquets supplémentaires
if gum spin --title "Installation des paquets" -- bash -c "
cr pacman -S --noconfirm ${PACKAGES} >> $LOG 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Installation des paquets $PACKAGES"
else
    echo -e " [\e[31m✖ \e[0m] Installation des paquets $PACKAGES"
fi

## création et ajout de la clé de chiffrement
crypto_keyfile() {
    # $1 = passphrase, $2 = disque (ex: sda)
    # créer le keyfile dans le système cible
    dd if=/dev/urandom of=/mnt/crypto_keyfile.bin bs=512 count=8 status=none
    chmod 000 /mnt/crypto_keyfile.bin
    chown root:root /mnt/crypto_keyfile.bin
    # ajouter la clé au LUKS (auth avec la passphrase)
    printf "%s" "$1" | cryptsetup luksAddKey "/dev/${2}2" /mnt/crypto_keyfile.bin
}
export -f crypto_keyfile

if DISK="$disk" CRYPTPASS="$cryptpass" LOG="$LOG" \
   gum spin --title "Création et ajout de la clé de chiffrement" -- bash -e -c '
{
  crypto_keyfile "$CRYPTPASS" "$DISK"
} >> "$LOG" 2>&1
'; then
    echo -e " [\e[32m✔ \e[0m] Création et ajout de la clé de chiffrement"
else
    echo -e " [\e[31m✖ \e[0m] Création et ajout de la clé de chiffrement"
fi


## configuration du mot de passe root
if gum spin --title "Configuration du mot de passe root" -- bash -c "
{
cr chpasswd <<<\"root:\"$PASSWD\"\"
} >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Configuration du mot de passe root"
else
    echo -e " [\e[31m✖ \e[0m] Configuration du mot de passe root"
fi

## création de l'utilisateur
if gum spin --title "Création de l'utilisateur" -- bash -c "
cr useradd -m -G wheel \"$USER\" >> $LOG 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Création de l'utilisateur $USER"
else
    echo -e " [\e[31m✖ \e[0m] Création de l'utilisateur $USER"
fi

## configuration du mot de passe utilisateur
if gum spin --title "Configuration sudoers" -- bash -c "
{
cr chpasswd <<<\"\"$USER\":\"$PASSWD\"\"
} >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Configuration du mot de passe de l'utilisateur $USER"
else
    echo -e " [\e[31m✖ \e[0m] Configuration du mot de passe de l'utilisateur $USER"
fi

## autorisation sudo pour le groupe wheel
cr sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

## configuration mkinitcpio.conf avec le keyfile et les hooks nécessaires
cat << EOF > /mnt/etc/mkinitcpio.conf
FILES="/crypto_keyfile.bin"
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap block encrypt btrfs filesystems fsck)
EOF

## --- varibales GRUB ---
UUID_GRUB=$(blkid -s UUID -o value /dev/${disk}2)

#cat << EOF > /mnt/etc/crypttab
#root UUID=${UUID_GRUB} /crypto_keyfile.bin luks,discard
#EOF

## configuration de grub pour le chiffrement au démarrage
sed -i \
"s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=7\ cryptkey=rootfs:/crypto_keyfile.bin root=/dev/mapper/root\ cryptdevice=UUID=${UUID_GRUB}:root\ rootflags=subvol=@\"|" \
/mnt/etc/default/grub

sed -i \
"s|^#GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|" \
/mnt/etc/default/grub

## génération des images initramfs
if gum spin --title "Génération des images initramfs" -- bash -c "
cr mkinitcpio -P >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Génération des images initramfs"
else
    echo -e " [\e[31m✖ \e[0m] Génération des images initramfs"
fi
## installation de grub
if gum spin --title "Installation de grub" -- bash -c "
cr grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Installation de grub"
else
    echo -e " [\e[31m✖ \e[0m] Installation de grub"
fi

## génération de la configuration de grub
if gum spin --title "Génération de la configuration de grub" -- bash -c "
cr grub-mkconfig -o /boot/grub/grub.cfg >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Génération de la configuration de grub"
else
    echo -e " [\e[31m✖ \e[0m] Génération de la configuration de grub"
fi

## activation des services
if gum spin --title "Activation des services" -- bash -c "
{
systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager && \
systemctl --root /mnt mask systemd-networkd
} >> ${LOG} 2>&1
"; then
    echo -e " [\e[32m✔ \e[0m] Activation des services"
else
    echo -e " [\e[31m✖ \e[0m] Activation des services"
fi

#umount -R /mnt

## -------------------------------- Debug section ---------------------------------------
## en cas d'utilisation penser a commenter umount -R /mnt avant
debug