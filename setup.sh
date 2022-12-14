#!/bin/sh

#/!\
# Executer le script en tant que root : chmod +x setup.sh && sudo ./setup.sh
#/!\

apt -y install --reinstall libappstream4
apt -y update
apt -y install isc-dhcp-server ssh nmap fping


echo "INTERFACESv4='ens4'" > /etc/default/isc-dhcp-server

printf "default-lease-time 600;\n\
max-lease-time 7200;\n\
subnet $1.0 netmask 255.255.255.0 {
    range $1.2 $1.254;\n\
    option routers $1.1;\n\
    option domain-name-servers 194.167.156.13;\n\
}\n" > /etc/dhcp/dhcpd.conf

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# On redémarre les services pour être sûr que les configurations sont bien appliquées
systemctl restart networking isc-dhcp-server

iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
