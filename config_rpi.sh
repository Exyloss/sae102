#!/bin/sh

# Téléchargement de Raspberry Pi OS Lite
wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-09-26/2022-09-22-raspios-bullseye-armhf-lite.img.xz

# Décrompression de l'image de l'OS
unxz raspios_lite_armhf-2022-09-26/2022-09-22-raspios-bullseye-armhf-lite.img.xz

# On montre les disques détéctés à l'utilisateur
lsblk
printf "Disque de la carte SD:"
read -r sd

# Ecriture de l'OS sur la carte SD
sudo dd if=https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-09-26/2022-09-22-raspios-bullseye-armhf-lite.img.xz of="$sd" bs=1M status=progress

# Montage de la carte SD
sudo mkdir /mnt
sudo mount /dev/sdb1 /mnt
sudo mount /dev/sdb2 /mnt/boot

# Activation et configuration SSH
sudo touch /mnt/boot/ssh
sudo echo "PermitRootLogin no" | tee -a /mnt/etc/ssh/sshd_config

# Mise à jour d'openssl
sudo apt install openssl

# Configuration mot de passe pi
echo "Veuillez rentrer le mot de passe de l'utilisateur pi"
pass_hash=$(openssl passwd -6)
sudo sed -i "s/\*/$pass_hash/g" /mnt/etc/shadow

# Démontage de la carte
sudo umount -R /mnt
