# Packer (Docker) – Arch Linux

Arborescence Packer minimaliste pour construire une image Docker basée sur Arch Linux, provisionnée avec un utilisateur non-root et des outils de base.

## Structure
- `versions.pkr.hcl` – Déclare le plugin Docker Packer
- `variables.pkr.hcl` – Variables (image de base, nom/tag, user)
- `main.pkr.hcl` – Source Docker, provision et tag
- `scripts/setup.sh` – Configuration système et packages
- `Makefile` – Cibles pratiques (init/validate/build/run)

## Pré-requis
- Packer >= 1.11
- Docker installé et démarré

## Utilisation
```bash
cd HMS/arch-docker-packer
# Initialiser les plugins
packer init .
# Valider la config
packer validate .
# Construire l'image
packer build .
```

Par défaut, l'image résultante est taggée `hms/arch-devops:latest`.

## Variables utiles
Vous pouvez surcharger via un fichier `auto.pkrvars.hcl` ou des flags `-var`:
```hcl
base_image = "archlinux:latest"
image_name = "hms/arch-devops"
image_tag  = "latest"
username   = "dawan"
uid        = 1000
gid        = 1000
```

## Lancer un conteneur
```bash
# Lancer un shell interactif dans l'image créée
docker run --rm -it hms/arch-devops:latest zsh
```

## Notes
- Ajustez `scripts/setup.sh` pour ajouter des outils (kubectl, helm, etc.).
- Pour publier: ajoutez un post-processor `docker-push` si nécessaire.
