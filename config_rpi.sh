#!/bin/sh

if [ ! -e "2022-09-22-raspios-bullseye-armhf-lite.img" ]; then
    # Téléchargement de Raspberry Pi OS Lite
    wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-09-26/2022-09-22-raspios-bullseye-armhf-lite.img.xz || exit 1
    # Décrompression de l'image de l'OS
    echo "Décompression de l'image en cours..."
    unxz 2022-09-22-raspios-bullseye-armhf-lite.img.xz || exit 1
fi

# On montre les disques détéctés à l'utilisateur
lsblk
printf "Disque de la carte SD (sans le /dev/):"
read -r sd

# Ecriture de l'OS sur la carte SD
echo "Ecriture de l'image sur la carte SD en cours..."
sudo dd if=2022-09-22-raspios-bullseye-armhf-lite.img of=/dev/"$sd" bs=1M status=progress || exit 1

# Montage de la carte SD
if grep -q "^/dev/$sd" /proc/mounts; then
    mpboot=$(grep "^/dev/${sd}1" /proc/mounts | cut -d ' ' -f 2)
    mproot=$(grep "^/dev/${sd}2" /proc/mounts | cut -d ' ' -f 2)
else
    [ -d /mnt ] || sudo mkdir /mnt /mnt/boot
    sudo mount /dev/"$sd"2 /mnt || exit 1
    sudo mount /dev/"$sd"1 /mnt/boot || exit 1
    mpboot="/mnt/boot"
    mproot="/mnt"
fi


# Activation et configuration SSH
sudo touch "${mpboot}/ssh"
echo "PermitRootLogin no" | sudo tee -a "${mproot}/etc/ssh/sshd_config" || exit 1

# Mise à jour d'openssl
distro=$(grep "^ID=" /etc/os-release | cut -d '=' -f 2 )
case "$distro" in
    "ubuntu"|"debian") sudo apt install openssl || exit 1 ;;
    "arch") sudo pacman -Sy openssl ;;
esac

# Configuration mot de passe pi
echo "Veuillez rentrer le mot de passe de l'utilisateur pi"
pass_hash=$(openssl passwd -6) || exit 1
sudo sed -i "s|pi:\*:|pi:${pass_hash}:|g" "${mproot}/etc/shadow" || exit 1

# Démontage de la carte
sudo umount -R "${mpboot}" || exit 1
sudo umount -R "${mproot}" || exit 1
