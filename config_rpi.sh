#!/bin/sh

# Téléchargement de Raspberry Pi OS Lite
wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-09-26/2022-09-22-raspios-bullseye-armhf-lite.img.xz || exit 1

# Décrompression de l'image de l'OS
echo "Décompression de l'image en cours..."
unxz 2022-09-22-raspios-bullseye-armhf-lite.img.xz || exit 1

# On montre les disques détéctés à l'utilisateur
lsblk
printf "Disque de la carte SD:"
read -r sd

# Ecriture de l'OS sur la carte SD
echo "Ecriture de l'image sur la carte SD en cours..."
sudo dd if=2022-09-22-raspios-bullseye-armhf-lite.img of=/dev/"$sd" bs=1M status=progress || exit 1

# Montage de la carte SD
[ -d /mnt ] || sudo mkdir /mnt
sudo mount /dev/"$sd"2 /mnt || exit 1
sudo mount /dev/"$sd"1 /mnt/boot || exit 1

# Activation et configuration SSH
sudo touch /mnt/boot/ssh
echo "PermitRootLogin no" | sudo tee -a /mnt/etc/ssh/sshd_config || exit 1

# Mise à jour d'openssl
distro=$(grep "^ID=" /etc/os-release | cut -d '=' -f 2 )
case "$distro" in
    "ubuntu"|"debian") sudo apt install openssl || exit 1 ;;
    "arch") sudo pacman -Sy openssl ;;
esac

# Configuration mot de passe pi
echo "Veuillez rentrer le mot de passe de l'utilisateur pi"
pass_hash=$(openssl passwd -6) || exit 1
sudo sed -i "s|pi:\*:|pi:${pass_hash}:|g" /mnt/etc/shadow || exit 1

# Démontage de la carte
sudo umount -R /mnt || exit 1
