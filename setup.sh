#!/bin/sh

printf 'Adresse IP du serveur (côté routeur):'
read -r ip
printf "\n3 premiers nombres de l'IP du serveur (côté réseau local):"
read -r ip_lan
printf '\nAdresse IP du routeur:'
read -r routeur
printf '\nAdresse IP du serveur DNS:'
read -r dns

# On configure les deux cartes réseau
nmcli con mod Connexion\ filaire\ 1 \
    ipv4.addresses "$ip"/24 \
    ipv4.gateway "$routeur" \
    ipv4.dns "$dns" \
    ipv4.method manual
nmcli con mod Connexion\ filaire\ 2 \
    ipv4.addresses "$ip_lan.1"/24 \
    ipv4.gateway "$ip" \
    ipv4.dns "$dns" \
    ipv4.method manual

# On relance les deux connexions
nmcli con down Connexion\ filaire\ 1
nmcli con up Connexion\ filaire\ 1
nmcli con down Connexion\ filaire\ 2
nmcli con up Connexion\ filaire\ 2

# Exportation du proxy
export http_proxy=http://cache.univ-pau.fr:3128
export https_proxy=http://cache.univ-pau.fr:3128

sudo -s

# Executer le script en tant que root : chmod +x setup.sh && sudo ./setup.sh
apt -y install --reinstall libappstream4
apt -y update
apt -y install isc-dhcp-server ssh nmap fping


echo "INTERFACESv4='ens4'" > /etc/default/isc-dhcp-server

printf "default-lease-time 600;\n\
max-lease-time 7200;\n\
subnet $ip_lan.0 netmask 255.255.255.0 {
    range $ip_lan.2 $ip_lan.254;\n\
    option routers $ip_lan;\n\
    option domain-name-servers 194.167.156.13;\n\
}\n" > /etc/dhcp/dhcpd.conf

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# On redémarre les services pour être sûr que les configurations sont bien appliquées
systemctl restart networking
systemctl restart isc-dhcp-server

iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
