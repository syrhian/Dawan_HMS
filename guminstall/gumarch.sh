#!/usr/bin/env bash
set -euo pipefail

if ! command -v gum &>/dev/null; then
    echo "❌ gum n'est pas installé. Installe-le avec : pacman -S gum"
    exit 1
fi

echo "=== 🧙 Générateur de configuration Archinstall v3 ==="

# --- App Config ---
function choose_audio() {
    gum choose "pipewire" "pulseaudio" --header "Choisir le serveur audio :"
AUDIO=$(gum choose "pipewire" "pulseaudio" --header "Choisir le serveur audio :")
}

# --- Langue / clavier ---
function choose_language() {
    SYS_LANG=$(gum choose "fr_FR.UTF-8" "en_US.UTF-8" --header "Langue système :")
KB_LAYOUT=$(gum choose "fr" "us" --header "Disposition du clavier :")
}

# --- Hostname ---
function choose_hostname() {
    HOSTNAME=$(gum input --placeholder "archlinux" --value "archlinux" --header "Nom d'hôte :")
}

# --- Bootloader ---
function choose_bootloader() {
    BOOTLOADER=$(gum choose "Grub" "systemd-boot" --header "Chargeur de démarrage :")
}

# --- Disque et partitions ---
function choose_disk() {
    DISK=$(gum input --placeholder "/dev/sda" --value "/dev/sda" --header "Disque cible :")
WIPE=$(gum choose "true" "false" --header "Wipe disk ?")
}

# Pour simplification, on fixe 2 partitions par défaut : /boot et /
function choose_partitions() {
    BOOT_SIZE=$(gum input --placeholder "1" --value "1" --header "Taille /boot (GiB) :")
ROOT_SIZE=$(gum input --placeholder "237949157376" --value "237949157376" --header "Taille / (B) :")
}

# --- Kernel ---
function choose_kernel() {
    KERNEL=$(gum choose "linux" "linux-lts" "linux-zen" --header "Choisir un noyau :")
}

# --- Timezone / NTP / Swap ---
function choose_timezone() {
    TIMEZONE=$(gum input --placeholder "Europe/Paris" --value "Europe/Paris" --header "Fuseau horaire :")
}

function choose_swap() {
    USE_SWAP=$(gum choose "true" "false" --header "Activer swap ?")
}

function choose_ntp() {
    USE_NTP=$(gum choose "true" "false" --header "Activer NTP ?")
}

# --- Packages ---
function choose_packages() {
    PACKAGES=$(gum input --placeholder "openssh linux-firmware" --value "openssh linux-firmware" --header "Paquets à installer (séparés par espace) :")
PACKAGES_JSON=$(echo "$PACKAGES" | jq -R 'split(" ")')
}

# --- Network ---
function choose_network() {
    NETWORK_TYPE=$(gum choose "iso" "dhcp" "static" --header "Type de configuration réseau :")
}

# --- Profile ---
function choose_profile() {
    PROFILE=$(gum choose "Server" "Desktop" --header "Profil d'installation :")
}

# --- Construction du JSON ---
function generate_json() {
    JSON=$(jq -n \
    --arg audio "$AUDIO" \
    --arg lang "$SYS_LANG" \
    --arg kb "$KB_LAYOUT" \
    --arg host "$HOSTNAME" \
    --arg boot "$BOOTLOADER" \
    --arg disk "$DISK" \
    --arg wipe "$WIPE" \
    --arg boot_size "$BOOT_SIZE" \
    --arg root_size "$ROOT_SIZE" \
    --arg kernel "$KERNEL" \
    --arg timezone "$TIMEZONE" \
    --arg swap "$USE_SWAP" \
    --arg ntp "$USE_NTP" \
    --argjson packages "$PACKAGES_JSON" \
    --arg network "$NETWORK_TYPE" \
    --arg profile "$PROFILE" \
'{
    "app_config": {"audio_config": {"audio": $audio}},
    "archinstall-language": "English",
    "auth_config": {},
    "bootloader": $boot,
    "custom_commands": [],
    "disk_config": {
        "btrfs_options": {"snapshot_config": null},
        "config_type": "default_layout",
        "device_modifications": [
            {
                "device": $disk,
                "partitions": [
                    {
                        "btrfs": [],
                        "dev_path": null,
                        "flags": ["boot"],
                        "fs_type": "fat32",
                        "mount_options": [],
                        "mountpoint": "/boot",
                        "obj_id": "",
                        "size": {"sector_size": {"unit": "B","value": 512}, "unit": "GiB","value": ($boot_size|tonumber)},
                        "start": {"sector_size": {"unit": "B","value": 512}, "unit": "MiB","value": 1},
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
                        "obj_id": "",
                        "size": {"sector_size": {"unit": "B","value": 512}, "unit": "B","value": ($root_size|tonumber)},
                        "start": {"sector_size": {"unit": "B","value": 512}, "unit": "B","value": 1074790400},
                        "status": "create",
                        "type": "primary"
                    }
                ],
                "wipe": ($wipe=="true")
            }
        ]
    },
    "hostname": $host,
    "kernels": [$kernel],
    "locale_config": {"kb_layout": $kb, "sys_enc": "UTF-8", "sys_lang": $lang},
    "mirror_config": {
        "custom_repositories": [],
        "custom_servers": [],
        "mirror_regions": {
            "France": [
                "http://mir.archlinux.fr/$repo/os/$arch",
                "http://archlinux.mirrors.ovh.net/archlinux/$repo/os/$arch"
            ]
        },
        "optional_reposit_
ies": []
    },
    "network_config": {"config_type": $network},
    "ntp_config": {"enable_ntp": ($ntp=="true")},
    "packages": $packages,
    "profile": $profile,
    "time_config": {"timezone": $timezone},
    "swap_config": {"enable_swap": ($swap=="true")}
}')
echo "$JSON" > archinstall_config.json
echo "✅ Fichier archinstall_config.json généré avec succès."
}