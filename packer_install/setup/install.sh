#!/usr/bin/bash
set -eu

echo "Téléchargement de la configuration Archinstall"
curl -fsSL http://{{ .HTTPIP }}:{{ .HTTPPort }}/user_configuration.json -o user_configuration.json

echo "Lancement de l'installation automatisée"
archinstall --config user_configuration.json

echo "Installation terminée"