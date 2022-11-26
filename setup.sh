#!/bin/bash

sudo apt -y install --reinstall libappstream4
sudo apt -y update
sudo apt -y install isc-dhcp-server ssh
sudo cp etc/default/isc-dhcp-server /etc/default/
sudo cp etc/dhcp/dhcpd.conf /etc/dhcp/
sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sudo sysctl -p
sudo systemctl restart networking
sudo systemctl restart isc-dhcp-server
