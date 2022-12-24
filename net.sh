#!/bin/sh

printf 'Adresse IP du serveur (côté routeur):'
read -r ip
printf '\nAdresse IP du serveur (côté réseau local):'
read -r ip_lan
printf '\nAdresse IP de la passerelle:'
read -r passerelle
printf '\nAdresse IP du serveur DNS:'
read -r dns

# On configure les deux cartes réseau
nmcli con mod Connexion\ filaire\ 1 ipv4.addresses "$ip"/24 ipv4.gateway "$passerelle" ipv4.dns "$dns" ipv4.method manual
nmcli con mod Connexion\ filaire\ 2 ipv4.addresses "$ip_lan"/24 ipv4.gateway "$ip" ipv4.dns "$dns" ipv4.method manual

# On relance les deux connexions
nmcli con down Connexion\ filaire\ 1
nmcli con up Connexion\ filaire\ 1
nmcli con down Connexion\ filaire\ 2
nmcli con up Connexion\ filaire\ 2

# Exportation du proxy
export http_proxy=http://cache.univ-pau.fr:3128
export https_proxy=http://cache.univ-pau.fr:3128
