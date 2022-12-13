#!/bin/sh

# On configure les deux cartes réseau
nmcli con mod Connexion\ filaire\ 1 ipv4.addresses "$1"/24 ipv4.gateway 10.2.18.1 ipv4.dns 1.1.1.1 ipv4.method manual
nmcli con mod Connexion\ filaire\ 2 ipv4.addresses 192.168.36.1/24 ipv4.gateway "$1" ipv4.dns 1.1.1.1 ipv4.method manual

# On relance les deux connexions
nmcli con down Connexion\ filaire\ 1
nmcli con up Connexion\ filaire\ 1
nmcli con down Connexion\ filaire\ 2
nmcli con up Connexion\ filaire\ 2

# Exportation du proxy
export http_proxy=http://cache.univ-pau.fr:3128
export https_proxy=http://cache.univ-pau.fr:3128
