#!/bin/sh

nmcli con mod Connexion\ Filaire\ 1 ipv4.addresses 10.2.18.36/24 ipv4.gateway 10.2.18.1 ipv4.dns 1.1.1.1 ipv4.method manual
nmcli con mod Connexion\ Filaire\ 2 ipv4.addresses 192.168.36.1/24 ipv4.gateway 10.2.18.36 ipv4.dns 1.1.1.1 ipv4.method manual

export http_proxy=http://cache.univ-pau.fr:3128
export https_proxy=http://cache.univ-pau.fr:3128
