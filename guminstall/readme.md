# Dawarch – Installation Arch Linux automatisée (Gum)

script d'installation Arch Linux automatisée avec interface Gum.
- préparation du disque cible
- chiffrement (LUKS)
- sous volumes Btrfs
- Configuration de GRUB

Attention: ce script efface entièrement le disque sélectionné (formatage + repartitionnement). Utilisez-le en connaissance de cause

## Prérequis
- Environnement live Arch Linux (ISO officiel), avec accès réseau.
- Package Gum: `pacman -Sy gum`.

## Fichiers
- Script principal: [HMS/guminstall/dawarch.sh](HMS/guminstall/dawarch.sh)
- Log d’installation: `arch_install.log` (généré pendant l'utilisation du script)

## Variables configurables
- `HOSTNAME` -> nom de la machine
- `USER` -> Utilisateur additionnel (sudo)
- `PASSWD` -> Mot de passe root
- `USR_PASSWD` -> Mot de passe de l'utilisateur
- `PACSTRAP` -> liste des packets principaux (aucune modification nécessaire, éditez plutot `PACKAGES`)
- `PACKAGES` -> listes des packets additionels (éditez a la convenance séparé d'un espace) 


Modifiez ces valeurs en tête de [HMS/guminstall/dawarch.sh](HMS/guminstall/dawarch.sh) si besoin.

## Ce que fait le script
- Sélection du disque
- Nettoyage d'anciennes partitions
- Partitionnement GPT: ESP de 500 Mb + partition principale Btrfs avec le reste.
- Chiffrement LUKS de la partition Btrfs
- Formatage Btrfs, création des sous-volumes: `@`, `@home`, `@snapshots`.
- Montage des partitions
- Installation base (`pacstrap`) + paquets additionnels (`PACKAGES`).
- génération de config fstab, timezone, horloge, locales (fr_FR.UTF-8), keymap (fr), hostname.
- Création d’un keyfile `/crypto_keyfile.bin`, ajout au LUKS.
- Mots de passe root/utilisateur, sudoers (groupe wheel).
- Création des images initramfs.
- Configuration et installation de GRUB
- Activation des services réseau.

## Utilisation
1) Démarrez sur un ISO Arch connecté a internet
2) Installez Gum si nécessaire:
    ```bash
    pacman -Sy --noconfirm gum
    ```
3) Récupérez le script:
    ```bash
    wget https://raw.githubusercontent.com/syrhian/Dawan_HMS/refs/heads/main/guminstall/dawarch.sh
    ```
4) Rendez-le exécutable et lancez-le:
    ```bash
    chmod +x ./dawarch.sh
    ./dawarch.sh
    ```
5) Laissez vous guider par le menu.

## Log
Au terme de l’installation ou en cas d'erreur consultez `arch_install.log` a la racine d'exécution du script.

## Personnalisation de l’affichage (Gum)
Vous pouvez ajuster les couleurs via les variables d’environnement de gum en début de script


## Dépannage
- Chiffrement LUKS: assurez-vous que la partition est bien `/dev/<disk>2` et non montée. En cas d’échec, rejouez `wipefs -a` et `sgdisk --zap-all`.

## Sécurité
- Changez `PASSWD` et le mot de passe utilisateur. Les mots de passe par défaut `passw0rd` sont uniquement a des fins de tests.
- Conservez `/crypto_keyfile.bin` en sécurité; il est intégré dans l’initramfs. A la racine du système

## Remarques
- Le script termine par une section de debug affichant plusieurs fichiers clés.
décommentez la fonction et commentez la ligne `umount -R /mnt`