#!/usr/bin/env bash
# Wizard Gum avec navigation Retour/Suivant + récap + génération JSON
set -euo pipefail

disks=$(lsblk -o NAME,SIZE,MODEL | grep -E "sd|vd|nvme" | awk '{print NR "  /dev/"$1"  "$2"  "$3}')
cgdsk_nmbr=" "
#cgdrive="$(echo "${disks}" | awk "\$1 == ${cgdsk_nmbr} {print \$2}")"
# cgdisk "${cgdrive}"

##### gum style

# Style
export FOREGROUND=11
export ALIGN=center
export WIDTH=80
export BORDER=none

# Choose
export GUM_CHOOSE_CURSOR="> "
export GUM_CHOOSE_CURSOR_FOREGROUND=135
export GUM_CHOOSE_HEIGHT=5

# Confirm
export GUM_CONFIRM_SELECTED_BACKGROUND=135


# Valeurs par défaut
AUDIO="pipewire"
BT="false"
SYS_LANG="fr_FR.UTF-8"
KB_LAYOUT="fr"
HOSTNAME="archlinux"
BOOTLOADER="Grub"
DISK="/dev/sda"
WIPE="true"
BOOT_SIZE="1"              # GiB
ROOT_SIZE="237949157376"   # Bytes (exemple)
KERNEL="linux"
TIMEZONE="Europe/Paris"
SWAP="true"
NTP="true"
PACKAGES="openssh linux-firmware"
PACKAGES_JSON='["openssh","linux-firmware"]'
RECAP="iso"
PROFILE="Server"
GFX_DRIVERS="Nvidia (open kernel module for newer GPUs, Turing+)"
GREETER="sddm"



dhcp_ip() {
  gum style "==== Configuration IP dynamique (DHCP) ===="
  echo

  if gum confirm "utiliser DHCP ?"; then
    IFACE=$(gum input --placeholder "ex: ens33" --header "Interface réseau :")
    RECAP="dhcp sur [${IFACE}]"
    JSNETWORK=$(cat <<EOF
"network_config": {
  "nics": [
    {
      "dhcp": true,
      "dns": null,
      "gateway": null,
      "iface": "${IFACE}",
      "ip": null
    }
  ],
  "type": "manual"
}
EOF
  )
  else
    manual_ip
  fi
}

manual_ip() {
  gum style "==== Configuration IP statique ===="
  echo
  IFACE=$(gum input --placeholder "ex: ens33" --header "Interface réseau :")
  STATIC_IP=$(gum input --placeholder "ex: 192.168.10.10/24" --header "Adresse IP statique :")
  GATEWAY=$(gum input --placeholder "ex: 192.168.10.1" --header "Passerelle (Gateway) :")
  DNS=$(gum input --placeholder "ex: 8.8.8.8" --header "Serveur DNS :")
  RECAP="manuel IP : ${STATIC_IP} | GW : ${GATEWAY} | DNS : ${DNS} sur [${IFACE}]"

  JSNETWORK=$(cat <<EOF
"network_config": {
    "nics": [
        {
            "dhcp": false,
            "dns": [
                "$DNS"
            ],
            "gateway": "$GATEWAY",
            "iface": "$IFACE",
            "ip": "$STATIC_IP"
        }
    ],
    "type": "manual"
}
EOF
)
}

audio_bt() {
  gum style "==== Choisir le serveur audio ===="
  echo
  AUDIO=$(gum choose "pipewire" "pulseaudio" --selected "$AUDIO" --header "Serveur audio :")
  BT=$(gum choose "true" "false" --selected "$BT" --header "Activer le support Bluetooth ?")
}


language() {
  gum style "==== Langue système et clavier ===="
  echo
  SYS_LANG=$(awk '{print $1}' /usr/share/i18n/SUPPORTED | grep -E 'UTF-8' | gum choose --header "Choisis ta langue (locale UTF-8)" --selected "$SYS_LANG")
  KB_LAYOUT=$(localectl list-keymaps | gum choose --header "Disposition du clavier :" --selected "$KB_LAYOUT")

  JSLOCALES=$(cat <<EOF
    {
      locale_config: {
        sys_lang: $SYS_LANG,
        sys_enc: "UTF-8",
        kb_layout: $KB_LAYOUT
      }
    }
EOF
  )
}

hostname() {
  gum style "==== Nom d'hôte ===="
  echo
  HOSTNAME=$(gum input --placeholder "archlinux" --value "$HOSTNAME" --header "Nom d'hôte :")

  JSHOSTNAME=$(cat <<EOF
    {
      hostname: $HOSTNAME
    }
EOF
)
}

bootloader() {
  gum style "==== Chargeur de démarrage ===="
  echo
  BOOTLOADER=$(gum choose "Grub" "systemd-boot" --selected "$BOOTLOADER" --header "Bootloader :")

  JSBOOTLOADER=$(cat <<EOF
    {
      bootloader: $BOOTLOADER
    }
EOF
    )
}

disk() {
  gum style "==== Disque cible et effacement ===="
  echo
  DISK=$(echo "${disks}" | gum choose --header "Disque cible :" --selected "$DISK")
  WIPE=$(gum choose "true" "false" --selected "$WIPE" --header "Effacer le disque (wipe) ?")
}

partitions() {
  gum style "==== Partitions ===="
  echo
  BOOT_SIZE=$(gum input --placeholder "1" --value "$BOOT_SIZE" --header "Taille /boot (GiB) :")
  ROOT_SIZE=$(gum input --placeholder "237949157376" --value "$ROOT_SIZE" --header "Taille de / (en octets) :")
}

kernel() {
  gum style "==== Noyau ===="
  echo
  KERNEL=$(gum choose "linux" "linux-lts" "linux-zen" --selected "$KERNEL" --header "Choisir un noyau :")

  JSKERNEL=$(cat <<EOF
    {
      kernels: [$KERNEL]
    }
EOF
    )
}

timezone() {
  gum style "==== Fuseau horaire ===="
  echo
  TIMEZONE=$(find /usr/share/zoneinfo -type f | sed 's|/usr/share/zoneinfo/||' | gum choose --header "Choisir un fuseau horaire :" --selected "$TIMEZONE")

  JSTIMEZONE=$(cat <<EOF
    {
      time_config: {
        timezone: $TIMEZONE
      }
    }
EOF
    )
}

ntp() {
  gum style "==== Swap et NTP ===="
  echo
  NTP=$(gum choose "true" "false" --selected "$NTP" --header "Activer NTP ?")

  JSNTP=$(cat <<EOF
    {
      "ntp_config": {
        "ntp": $NTP
      }
    }
EOF
    )
}

additionals_packages() {
  gum style "==== Paquets ===="
  echo
  PACKAGES=$(gum input --placeholder "openssh linux-firmware" --value "$PACKAGES" --header "Paquets (séparés par espace) :")
}

network() {
  gum style "==== Réseau ===="
  echo
  NETWORK_TYPE=$(gum choose "iso" "dhcp" "static" --selected "$NETWORK_TYPE" --header "Type de config réseau :")

  if [ "$NETWORK_TYPE" = "dhcp" ]; then
    dhcp_ip
  elif [ "$NETWORK_TYPE" = "static" ]; then
    manual_ip
  else
    RECAP="ISO"
    JSNETWORK=$(cat <<EOF
{
  "network_config": {
    "config_type": "iso"
  }
}
EOF
      )
  fi
}

profile_cfg() {
  gum style "==== Profil ===="
  echo
  GFX_DRIVERS=$(gum choose "Nvidia (open kernel module for newer GPUs, Turing+)" "Nvidia (open-source nouveau driver)" "Intel (open-source)" "AMD / ATI (open-source)" --selected "$GFX_DRIVERS")

  GREETER=$(gum choose "gdm" "lightdm-gtk-greeter" "lightdm-slick-greeter" "ly" "sddm" --selected "$GREETER")
}

show_summary() {
  gum style --border double --padding "1 1" --foreground 255 \
"Audio: $AUDIO
Bluetooth: $BT
Langue: $SYS_LANG
Clavier: $KB_LAYOUT
Hostname: $HOSTNAME
Bootloader: $BOOTLOADER
Disque: $DISK (wipe=$WIPE)
/boot: ${BOOT_SIZE}GiB
/: ${ROOT_SIZE} bytes
Kernel: $KERNEL
Timezone: $TIMEZONE
Swap: $SWAP
NTP: $NTP
réseau: $RECAP
Profil: $PROFILE
gfx_drivers: $GFX_DRIVERS
Greeter: $GREETER
Paquets: $PACKAGES" | cat
}

make_json() {
  gum style "==== Génération du JSON final ===="
  echo
  JSON=$(cat <<EOF
{
"app_config": {
    "audio_config": {
        "audio": "${AUDIO}"
    },
    "bluetooth_config": {
        "enabled": "${BT}"
    }
},
"archinstall-language": "English",
"auth_config": {},
"bootloader": "${BOOTLOADER}",
"custom_commands": [],
"disk_config": {
    "btrfs_options": {
        "snapshot_config": null
    },
    "config_type": "default_layout",
    "device_modifications": [
        {
            "device": "/dev/sda",
            "partitions": [
                {
                    "btrfs": [],
                    "dev_path": null,
                    "flags": [
                        "boot",
                        "esp"
                    ],
                    "fs_type": "fat32",
                    "mount_options": [],
                    "mountpoint": "/boot",
                    "obj_id": "bbf9d780-3e85-42fc-88c7-fcb32abcff80",
                    "size": {
                        "sector_size": {
                            "unit": "B",
                            "value": 512
                        },
                        "unit": "GiB",
                        "value": 1
                    },
                    "start": {
                        "sector_size": {
                            "unit": "B",
                            "value": 512
                        },
                        "unit": "MiB",
                        "value": 1
                    },
                    "status": "create",
                    "type": "primary"
                },
                {
                    "btrfs": [],
                    "dev_path": null,
                    "flags": [],
                    "fs_type": "ext4",
                    "mount_options": [],
                    "mountpoint": "/",
                    "obj_id": "17d3ecbe-b88c-4da0-ae88-f35616ad1d1c",
                    "size": {
                        "sector_size": {
                            "unit": "B",
                            "value": 512
                        },
                        "unit": "B",
                        "value": 106298343424
                    },
                    "start": {
                        "sector_size": {
                            "unit": "B",
                            "value": 512
                        },
                        "unit": "B",
                        "value": 1074790400
                    },
                    "status": "create",
                    "type": "primary"
                }
            ],
            "wipe": true
        }
    ],
    "disk_encryption": {
        "encryption_type": "luks_on_lvm",
        "lvm_volumes": [
            "9f00ec28-dd04-4dac-a467-eea32e94f18c"
        ],
        "partitions": []
    },
    "lvm_config": {
        "config_type": "default",
        "vol_groups": [
            {
                "lvm_pvs": [
                    "17d3ecbe-b88c-4da0-ae88-f35616ad1d1c"
                ],
                "name": "ArchinstallVg",
                "volumes": [
                    {
                        "btrfs": [],
                        "fs_type": "ext4",
                        "length": {
                            "sector_size": {
                                "unit": "B",
                                "value": 512
                            },
                            "unit": "GiB",
                            "value": 20
                        },
                        "mount_options": [],
                        "mountpoint": "/",
                        "name": "root",
                        "obj_id": "799b6652-4b82-420f-a9b4-5d395e3e6073",
                        "status": "create"
                    },
                    {
                        "btrfs": [],
                        "fs_type": "ext4",
                        "length": {
                            "sector_size": {
                                "unit": "B",
                                "value": 512
                            },
                            "unit": "B",
                            "value": 84823506944
                        },
                        "mount_options": [],
                        "mountpoint": "/home",
                        "name": "home",
                        "obj_id": "9f00ec28-dd04-4dac-a467-eea32e94f18c",
                        "status": "create"
                    }
                ]
            }
        ]
    }
},
"hostname": "${HOSTNAME}",
"kernels": [
    "${KERNEL}"
],
"locale_config": {
    "kb_layout": "${KB_LAYOUT}",
    "sys_enc": "UTF-8",
    "sys_lang": "${SYS_LANG}"
},
"mirror_config": {
    "custom_repositories": [],
    "custom_servers": [],
    "mirror_regions": {
        "France": [
            "http://mir.archlinux.fr/\$repo/os/\$arch",
            "http://archlinux.mirrors.ovh.net/archlinux/\$repo/os/\$arch",
            "https://archlinux.mirrors.ovh.net/archlinux/\$repo/os/\$arch",
            "http://mirror.archlinux.ikoula.com/archlinux/\$repo/os/\$arch",
            "http://arch.yourlabs.org/\$repo/os/\$arch",
            "https://arch.yourlabs.org/\$repo/os/\$arch",
            "http://mirror.lastmikoi.net/archlinux/\$repo/os/\$arch",
            "http://ftp.u-strasbg.fr/linux/distributions/archlinux/\$repo/os/\$arch",
            "http://archlinux.mailtunnel.eu/\$repo/os/\$arch",
            "https://archlinux.mailtunnel.eu/\$repo/os/\$arch",
            "https://mirror.wormhole.eu/archlinux/\$repo/os/\$arch",
            "http://fr.mirrors.cicku.me/archlinux/\$repo/os/\$arch",
            "https://fr.mirrors.cicku.me/archlinux/\$repo/os/\$arch",
            "https://mirror.thekinrar.fr/archlinux/\$repo/os/\$arch",
            "http://mirror.oldsql.cc/archlinux/\$repo/os/\$arch",
            "https://mirror.oldsql.cc/archlinux/\$repo/os/\$arch",
            "http://mirror.cyberbits.eu/archlinux/\$repo/os/\$arch",
            "https://mirror.cyberbits.eu/archlinux/\$repo/os/\$arch",
            "https://mirrors.eric.ovh/arch/\$repo/os/\$arch",
            "https://mirrors.jtremesay.org/archlinux/\$repo/os/\$arch",
            "http://archlinux.datagr.am/\$repo/os/\$arch",
            "http://mirror.bakertelekom.fr/Arch/\$repo/os/\$arch",
            "https://mirror.bakertelekom.fr/Arch/\$repo/os/\$arch",
            "http://mirrors.gandi.net/archlinux/\$repo/os/\$arch",
            "https://mirrors.gandi.net/archlinux/\$repo/os/\$arch",
            "http://mirror.theo546.fr/archlinux/\$repo/os/\$arch",
            "https://mirror.theo546.fr/archlinux/\$repo/os/\$arch",
            "http://archmirror.hogwarts.fr/\$repo/os/\$arch",
            "https://archmirror.hogwarts.fr/\$repo/os/\$arch",
            "http://mirror.its-tps.fr/archlinux/\$repo/os/\$arch",
            "https://mirror.its-tps.fr/archlinux/\$repo/os/\$arch",
            "http://mirror.rznet.fr/archlinux/\$repo/os/\$arch",
            "https://mirror.rznet.fr/archlinux/\$repo/os/\$arch",
            "http://arch.syxpi.fr/arch/\$repo/os/\$arch",
            "https://arch.syxpi.fr/arch/\$repo/os/\$arch",
            "https://elda.asgardius.company/archlinux/\$repo/os/\$arch",
            "http://f.matthieul.dev/mirror/archlinux/\$repo/os/\$arch",
            "https://f.matthieul.dev/mirror/archlinux/\$repo/os/\$arch",
            "http://mirror.peeres-telecom.fr/archlinux/\$repo/os/\$arch",
            "https://mirror.peeres-telecom.fr/archlinux/\$repo/os/\$arch",
            "http://mirror.trap.moe/archlinux/\$repo/os/\$arch",
            "https://mirror.trap.moe/archlinux/\$repo/os/\$arch",
            "https://mirror.smayzy.ovh/archlinux/\$repo/os/\$arch"
        ]
    },
    "optional_repositories": [
        "multilib"
    ]
  },
${JSNETWORK},
"ntp": "${NTP}",
"packages": [
    "${PACKAGES// /\",\"}"
],
"parallel_downloads": 0,
"profile_config": {
    "gfx_driver": "${GFX_DRIVERS}",
    "greeter": "${GREETER}",
    "profile": {
        "custom_settings": {
            "sshd": {}
        },
        "details": [
            "sshd"
        ],
        "main": "Server"
    }
},
"script": null,
"services": [],
"swap": "${SWAP}",
"timezone": "${TIMEZONE}",
"version": "3.0.9"
}
EOF
)
echo "$JSON" > archinstall_config.json
  gum style "✅ Fichier archinstall_config.json généré avec succès."
}

main_menu() {
  while true; do
    clear
    gum style "==== Menu principal - Archinstall ===="
    echo
    

    local pkg_count
    pkg_count=$(echo "$PACKAGES" | awk '{print NF}')

    local choice
    choice=$(gum choose \
      "1. Audio / Bluetooth [$AUDIO] / [$BT]" \
      "2. Langue/Clavier [$SYS_LANG,$KB_LAYOUT]" \
      "3. Hostname [$HOSTNAME]" \
      "4. Bootloader [$BOOTLOADER]" \
      "5. Disque [$DISK wipe=$WIPE]" \
      "6. Partitions [/boot=${BOOT_SIZE}GiB, /=${ROOT_SIZE}B]" \
      "7. Kernel [$KERNEL]" \
      "8. Timezone [$TIMEZONE]" \
      "9. Swap/NTP [swap=$SWAP ntp=$NTP]" \
      "10. Paquets ($pkg_count)" \
      "11. Réseau [$NETWORK_TYPE]" \
      "12. Profil [$PROFILE]" \
      "13. Récapitulatif" \
      "💾 Générer le JSON" \
      "❌ Quitter" \
      --header "Choisissez une section à modifier ou une action:")

    case "$choice" in
      "1. Audio / Bluetooth [$AUDIO] / [$BT]")
        audio_bt
        ;;
      "2. Langue/Clavier [$SYS_LANG,$KB_LAYOUT]")
        language
        ;;
      "3. Hostname [$HOSTNAME]")
        hostname
        ;;
      "4. Bootloader [$BOOTLOADER]")
        bootloader
        ;;
      "5. Disque [$DISK wipe=$WIPE]")
        disk
        ;;
      "6. Partitions [/boot=${BOOT_SIZE}GiB, /=${ROOT_SIZE}B]")
        partitions
        ;;
      "7. Kernel [$KERNEL]")
        kernel
        ;;
      "8. Timezone [$TIMEZONE]")
        timezone
        ;;
      "9. Swap/NTP [swap=$SWAP ntp=$NTP]")
        ntp
        ;;
      "10. Paquets ($pkg_count)")
        additionals_packages
        ;;
      "11. Réseau [$NETWORK_TYPE]")
        network
        ;;
      "12. Profil [$PROFILE]")
        profile_cfg
        ;;
      "13. Récapitulatif")
        show_summary
        gum confirm "Retour au menu principal ?" || continue
        ;;
      "💾 Générer le JSON")
        make_json
        exit 0
        ;;
      *)
        ;;
    esac
  done
}

# Lance le menu principal
main_menu




