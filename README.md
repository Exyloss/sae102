---
title: \Huge Compte-rendu de la SAE-1.02
author: Antonin PONS
date: 12 Janvier 2023 \pagebreak
geometry: margin=2cm
toc: true
toc-title: Sommaire
output: pdf_document
fontsize: 5em
lang: fr
header-includes:
  - \usepackage{titling}
  - \setlength{\droptitle}{7cm} 
---

\vspace{2cm}

---

\vspace{2cm}

Durant ce compte-rendu, je vous montrerais comment configurer un serveur DHCP afin de pouvoir 
connecter automatiquement un Raspberry Pi au réseau de l'IUT et à internet. Nous aborderons 
différentes méthodes pour réaliser ces tâches, nous utiliserons tout d'abord les interfaces 
graphiques pour simplifier les configurations, mais nous utiliserons aussi le terminal afin 
d'automatiser ces opérations.

\pagebreak

# 1. Création de la VM

Configuration de la VM sur vi4rt.univ-pau.fr :

```
Nouvelle machine virtuelle

Nom de la machine   ubuntu
Disque dur          Ubuntu 18.04 (15.00Go)
Lecteur CD/DVD      Vide
Lecteur CD/DVD 2    Vide
Booster sur le      [ ]
         CDROM
Processeur(s)       2 vcpus
Memoire vive        2G
Cartes reseaux      2
Carte 1 attachee a  bridge1
Carte 2 attachee a  pass1
Dupliquer le port   [ ]
serie dans la VM

Options avancées (utiliser en connaissance de causes)

Ne pas utiliser virtio [ ]

```

# 2. Installation de Raspberry Pi OS

## 2.1. Montage de la carte SD sur la VM

Pour monter une carte sd branchée sur une machine physique, il suffit d'activer le périphérique
dans Remote Viewer en allant dans Fichier > Sélection du périphérique USB.

## 2.2. Avec RPi-imager

Afin de flasher la carte SD du Raspberry avec le système d'exploitation adapté, nous allons 
utiliser le logiciel fournit par Raspberry Pi nommé `rpi-imager`. Ce logiciel permet d'installer 
Raspberry Pi OS 32 bits et de configurer le Raspberry avant son allumage. Pour flasher la carte sd
du Raspberry, il suffit de sélectionner le système d'exploitation «Raspberry Pi OS 32 bits», d'ajouter
la micro-sd en tant que support de stockage, de modifier les paramètres par défaut en cliquant sur 
la roue dentée et enfin de cliquer sur le bouton écrire.

Paramètres à renseigner :

```
[X] Enable SSH
    (X) Use password authentification
    ( ) Allow public key authentification only
[X] Set username and password
    Username : pi
    Password : **** (modifier selon l'envie)
[ ] Configure wireless LAN
[ ] Set locale settings
```

## 2.3. Depuis le terminal

Pour cette partie, nous installerons et configurerons Raspberry Pi OS à l'aide d'un terminal. 
Tout d'abord, nous allons télécharger le fichier image de Raspberry Pi OS 
[ici](https://www.raspberrypi.com/software/operating-systems/) en sélectionnant «Raspberry Pi OS 
with desktop» ou «Raspberry Pi OS Lite».

\pagebreak

Ensuite,
nous devons décompresser ce fichier, pour ce faire nous allons utiliser le programme `unxz` en lui
donnant comme argument le fichier compressé en XZ :

```bash
unxz ~/Téléchargements/2022-09-22-raspios-bullseye-armhf.img.xz
```

Alors, nous installons Raspberry Pi OS sur une carte SD à l'aide de la commande DD :

```bash
sudo dd if=~/Téléchargements/2022-09-22-raspios-bullseye-armhf.img of=/dev/sdb bs=1M status=progress 
```

Dans cette commande :

 - _if_ a comme valeur l'image d'entrée
 - _of_ a comme valeur le périphérique de sortie
 - _status=progress_ permet d'afficher des informations sur la progression de l'opération
 - _bs=1M_ permet de définir le nombre d'octets que l'on peut écrire en même temps à 1M.

Puis, pour éditer la configuration du Raspberry Pi, nous allons monter la carte SD (ici rattachée 
au disque _/dev/sdb_) à notre ordinateur :

```bash
sudo mount /dev/sdb2 /media/supervisor/rootfs
sudo mount /dev/sdb1 /media/supervisor/boot
```

Pour activer ssh au démarrage du Raspberry Pi, il nous suffit ce créer un fichier vide nommé _ssh_
dans le répertoire _/media/supervisor/boot_. Cependant la configuration de ssh n'est pas terminée. En effet, 
l'utilisateur pi n'ayant pas de mot de passe par défaut, la connexion ssh sera impossible avec
celui-ci.

Afin de générer ce mot de passe, nous pouvons utiliser la fonctionalité _passwd_ du programme
_OpenSSL_. Cette fonctionalité permet de générer un mot de passe suivant la norme de hachage du
fichier _/media/supervisor/rootfs/etc/shadow_. Selon la norme de ce fichier, le hash à générer 
doit être structuré comme ceci : 

`$[fonction de hachage]$[salage]$[mot de passe haché]`

La fonction de hachage est indiquée par un numéro, le numéro 1 représente md5, 5 représente 
SHA-256 et 6 représente SHA-512. Puis, le salage permet de contrer les attaques classiques comme 
la force brute. Enfin, la dernière valeur est le mot de passe haché par la fonction sélectionnée. 

Pour cette SAE, nous utiliserons la fonction SHA-512. Alors pour générer le hash suivant cette
norme, il est possible de lancer les commandes suivantes :

```bash
sudo apt install openssl # On met à jour openssl
openssl passwd -6
```

Il suffira de renseigner et de confirmer son mot de passe pour générer l'expression souhaitée.

Après avoir généré cette valeur, nous pouvons la placer dans le deuxième champ de la ligne de 
l'utilisateur pi du fichier _/etc/shadow_, les champs étant séparés par «:».

Ensuite, il suffit d'ajouter la ligne suivante au fichier _/media/supervisor/rootfs/etc/ssh/sshd_config_ afin
d'interdire la connexion SSH en tant que root :

```
PermitRootLogin no
```

enfin, nous pouvons démonter la carte SD du répertoire /media/supervisor :

```bash
sudo umount /media/supervisor/*
```

\pagebreak

# 3. Branchements efféctués

Les câbles verts représentent les connexions préétablies.

![schéma des branchements réalisés](img/dessin.png)

# 4. Configuration basique de la VM

## 4.1. Paramétrage des cartes réseau

### 4.1.1. Depuis l'interface graphique

Nous avons configuré les paramètres de réseau des deux cartes de la machine virtuelle. La carte 
bridge1 possède une adresse ip appartenant à la plage d'ip du poste utilisé et est connectée à la 
prise chromée afin d'accéder à internet. Ainsi, son adresse ip sera 10.2.18.36 et sa passerelle 
sera 10.2.18.1. Son masque et son DNS seront 255.255.255.0 et 194.167.156.13.

```
Méthode IPv4    ( ) Automatique (DHCP)  ( ) Réseau local seulement
                (X) Manuel              ( ) Désactiver

Adresses

|Adresse     |Masque de réseau |Passerelle|
|------------+-----------------+----------|
|10.2.18.36  |255.255.255.0    |10.2.18.1 |

DNS

[194.167.156.13]
```

La carte PASS1 aura comme adresse ip 192.168.36.1, celle-ci n'a pas d'importance, il faut simplement qu'elle n'appartienne
pas au réseau 10.2.18.0. Aussi, cette carte
n'a pas besoin de passerelle, elle sera réliée à la carte bridge1 par l'intermédiaire de l'ip_forward.
Son masque et son DNS sont les mêmes que ceux de bridge1.

\pagebreak

```
Méthode IPv4    ( ) Automatique (DHCP)  ( ) Réseau local seulement
                (X) Manuel              ( ) Désactiver

Adresses

|   Adresse   | Masque de réseau | Passerelle |
|-------------+------------------+------------|
|192.168.36.1 |255.255.255.0     |            |

DNS

[194.167.156.13]
```

### 4.1.2. Depuis le terminal

Il est aussi possible de configurer les cartes réseau depuis le terminal à l'aide de la commande 
`nmcli` du logiciel NetworkManager. Dans notre cas, les cartes bridge1 et pass1 sont rattachées
respectivement aux connexions «Connexion filaire 1» et «Connexion filaire 2».

Pour modifier leurs configurations, on peut utiliser ces commandes :

```bash
nmcli con mod Connexion\ filaire\ 1 ipv4.addresses 10.2.18.36/24 \
    ipv4.gateway 10.2.18.1 ipv4.dns 194.167.156.13 ipv4.method manual

nmcli con mod Connexion\ filaire\ 2 ipv4.addresses 192.168.36.1/24 \
    ipv4.dns 194.167.156.13 ipv4.method manual
```

Ensuite, nous pouvons relancer ces connexions afin d'appliquer les changements effectués :

```bash
nmcli con down Connexion\ filaire\ 1
nmcli con up Connexion\ filaire\ 1

nmcli con down Connexion\ filaire\ 2
nmcli con up Connexion\ filaire\ 2
```

## 4.2. Accès à internet depuis la VM

Enfin, pour accéder à internet, nous devons définir le proxy utilisé par la machine virtuelle 
comme étant celui de l'université :

```bash
export http_proxy="http://cache.univ-pau.fr:3128"
export https_proxy="http://cache.univ-pau.fr:3128"
```

On peut vérifier le fonctionnement de notre configuration en envoyant une requête HTTP
au serveur archlinux.org :

```bash
wget https://archlinux.org
```

# 5. Installation et configuration de DHCP

## 5.1. Installation

Avant de pouvoir installer DHCP, j'ai fait face à une erreur du gestionnaire de paquets 
d'Ubuntu 18.04 (voir figure en fin de partie). Après quelques recherches, cette erreur fut
résolue en rentrant la commande suivante :

```bash
sudo apt install --reinstall libappstream4
```

Alors, nous pouvons enfin mettre à jour les dépôts d'APT pour installer DHCP :

```bash
sudo apt update && sudo apt install isc-dhcp-server
```

![Capture d'écran de l'erreur renvoyée par apt](img/capture-erreur-apt.png)

## 5.2. Configuration

Désormais, nous allons configurer le serveur DHCP. Pour m'aider, j'ai utilisé la 
[documentation Ubuntu du paquet isc-dhcp-server](https://doc.ubuntu-fr.org/isc-dhcp-server).
Voici le contenu du fichier de configuration _/etc/dhcp/dhcpd.conf_ :

```
default-lease-time 600;
max-lease-time 7200;

subnet 192.168.36.0 netmask 255.255.255.0 {
    range 192.168.36.2 192.168.36.254;
    option routers 192.168.36.1;
    option domain-name-servers 194.167.156.13;
}
```

Les deux premières lignes de ce fichier indiquent que le serveur DHCP attribuera une ip au client
pour une durée de 600 secondes,
et si le client renseigne lui-même cette valeur, celle-ci ne peut pas dépasser 7200 secondes. 
Puis, les lignes restantes definissent l'adresse et le masque de réseau utilisés par le serveur, 
les adresses du routeur et du DNS fournies aux clients et les adresses IP
attribuables aux clients.

Puis, nous devons définir l'interface utilisée par le serveur DHCP. Pour ce faire, on peut éditer
le fichier _/etc/default/isc-dhcp-server_ :

```
INTERFACESv4="ens4"
```

Enfin, nous pouvons lancer le service DHCP et l'activer au démarrage à l'aide de la commande 
suivante :

```bash
sudo systemctl enable --now isc-dhcp-server.service
```

# 6. Récupération de l'addresse IP du Raspberry

## 6.1. Avec dhcpd.leases

Après avoir branché le Raspberry, il existe plusieurs méthodes pour récupérer son adresse ip.
Nous pouvons la récupérer à l'aide du fichier des baux généré par `isc-dhcp-server`.
Ce fichier est _/var/lib/dhcpd.leases_ et ressemble à ceci :

```
lease 192.168.36.2 {
  starts 4 2023/01/05 09:59:47;
  ends 4 2023/01/05 10:09:47;
  cltt 4 2023/01/05 09:59:47;
  binding state active;
  next binding state free;
  rewind binding state free;
  hardware ethernet e4:5f:01:1e:0c:0a;
  uid "\001\344_\001\036\014\012";
  set vendor-class-identifier = "dhcpcd-8.1.2:Linux-5.15.61-v7l+:armv7l:BCM2711";
  client-hostname "raspberrypi";
}
```

On peut bien voir que l'adresse IP 192.168.36.2 a été attribuée au Raspberry peu de temps après
l'avoir connecté.

## 6.2. Avec nmap

Installer nmap :

```bash
sudo apt install nmap
```

Utiliser nmap avec la commande suivante :

```bash
nmap -sP 192.168.36.0/24
```

Paramètre de la commande :

 - -sP: Ping Scan - Ne fait que déterminer si les hôtes sont en ligne

Cette commande donne le résultat suivant :

```
supervisor@ubuntu:~# nmap -sP 192.168.36.0/24

Starting Nmap 7.60 ( https://nmap.org ) at 2022-11-16 11:12 CET
Nmap scan report for 192.168.36.2
Host is up (0.00063s latency).
MAC Address: 08:8F:C3:2F:55:22 (Unknown)
Nmap scan report for ubuntu (192.168.36.1)
Host is up.
Nmap done: 256 IP addresses (2 hosts up) scanned in 3.75 seconds
```

## 6.3. Avec fping

Installer fping :

```bash
sudo apt install fping
```

Utiliser fping avec la commande suivante :

```
supervisor@ubuntu:~# fping -g 192.168.36.0/24 -q -a
192.168.36.1
192.168.36.2
```

Paramètres de la commande :

 - -g : génère une liste d'adresses IP à ping avec la notation CIDR
 - -q : cache les messages d'erreur
 - -a : affiche les systèmes en vie

# 7. Connexion SSH

Pour utiliser SSH, nous avons besoin de l'installer et de l'activer au démrrage :

```bash
sudo apt install ssh
sudo systemctl enable --now sshd.service
```

Enfin, nous pouvons nous connecter au Raspberry depuis le serveur DHCP à l'aide de cette
commande :

```bash
ssh pi@192.168.36.2
```

Cette commande permet d'ouvrir un shell sécurisé en tant que _pi_ sur la machine ayant comme 
addresse IP 192.168.36.1. SSH demande ensuite de renseigner un mot de passe, il suffira d'écrire
celui définit à l'installation de Raspberry Pi OS.

# 8. Accéder à internet depuis le Raspberry

Tout d'abord, pour permettre au Raspberry Pi de sortir de son réseau local, nous devons
transformer le serveur DHCP en une sorte de routeur. Pour ce faire, il faut décommenter
la ligne ci-dessous dans le fichier _/etc/sysctl.conf_ :

```
net.ipv4.ip_forward=1
```

Et recharger la configuration sysctl avec cette commande :

```bash
sudo sysctl -p
```

De plus, on doit activer le NAT sur notre passerelle afin que l'addresse IP du
Raspberry soit remplacée par celle de sa passerelle lors de l'envoi de paquets à l'exterieur du
réseau local.

Pour ce faire, j'ai décidé d'utiliser la commande `iptables` comme ceci :

```bash
iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
```

Explication de la commande :

 - La valeur _POSTROUTING_ de l'option -A permet d'executer le _MASQUERADE_ juste avant la sortie 
     du paquet de l'interface _ens3_.
 - La valeur _nat_ de l'option -t permet quand à elle de consulter la table quand un nouveau paquet
     passe par la passerelle.
 - L'argument ens3 de l'option -o est le nom de la carte réseau de sortie des paquets
 - L'algorithme _MASQUERADE_ de l'option -j permet à la passerelle de se souvenir des paquets 
     tranférés et de les modifier afin de changer leur IP source lors de leur envoi.
     Lors du retour du paquet, cet algorithme consulte sa table des connexions masquées 
     établies pour voir si le datagramme appartient effectivement
     à un appareil du réseau local. Si c'est le cas, il annule les modifications réalisées à 
     l'aller du datagramme et le transmet au réseau local.

La table de routage du serveur DHCP devrait ressembler à ceci :

```
supervisor@ubuntu2204:~$ ip route
default via 10.2.18.1 dev ens3 proto static metric 20102 
10.2.18.0/24 dev ens3 proto kernel scope link src 10.2.18.36 metric 102 
10.2.18.36 dev ens4 proto static scope link metric 20103 
192.168.36.0/24 dev ens4 proto kernel scope link src 192.168.36.1 metric 103
```

Enfin, afin de mettre à jour les interfaces réseau, il suffit de redémarrer le service 
`NetworkManager` :

```bash
sudo systemctl restart NetworkManager
```

Notre Raspberry peut alors pinguer un serveur distant, mais celui-ci ne peut pas émettre de requêtes HTTP en dehors du réseau de l'IUT.

Depuis la connexion SSH, nous devons alors exporter le proxy de l'IUT sur le Raspberry.

De plus, afin d'avoir des certificats SSL synchronisés à l'heure actuelle, nous devons mettre à jour
la date et l'heure système du Raspberry comme ceci:

```bash
sudo date -s '2023-01-13 23:59:00'
```

Cette commande définira la date au Vendredi 13 Janvier 2023 et l'heure à 23h59.

. Pour tester la connexion avec internet en HTTP, nous pouvons 
tenter de faire une requête HTTP au site web _archlinux.org_ :

```bash
curl -I https://archlinux.org/
```

Cette commande nous retourne l'en-tête HTTP de la réponse du serveur web _archlinux.org:443_.
Dans cet en-tête, on y lit en première ligne _HTTP/2 200_, le code 200 signifie que la requête 
HTTP est un succès, notre Raspberry Pi est donc bien connecté à internet, en plus de pouvoir émettre des requêtes HTTP.

\pagebreak


# 9. Scripts écrits

## 1. net.sh

```bash
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

chmod +x setup.sh && sudo ./setup.sh "$ip_lan"
```

\pagebreak

## 2. setup.sh

```bash

#!/bin/sh

#/!\
# Executer le script en tant que root : chmod +x setup.sh && sudo ./setup.sh ip_lan
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
systemctl restart NetworkManager isc-dhcp-server

iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
```

\pagebreak

## 3. config_rpi.sh

```bash
#!/bin/sh

if [ ! -e "2022-09-22-raspios-bullseye-armhf-lite.img" ]; then
    # Téléchargement de Raspberry Pi OS Lite
    wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-09-26/\
2022-09-22-raspios-bullseye-armhf-lite.img.xz || exit 1
    # Décrompression de l'image de l'OS
    echo "Décompression de l'image en cours..."
    unxz 2022-09-22-raspios-bullseye-armhf-lite.img.xz || exit 1
fi

# On montre les disques détéctés à l'utilisateur
lsblk
printf "Disque de la carte SD (sans le /dev/):"
read -r sd

if grep -q "^/dev/$sd" /proc/mounts; then
    sudo umount /dev/"${sd}"* 2>/dev/null
fi

# Ecriture de l'OS sur la carte SD
echo "Ecriture de l'image sur la carte SD en cours, ne pas interrompre le programme..."
sudo dd if=2022-09-22-raspios-bullseye-armhf-lite.img of=/dev/"$sd" bs=1M status=progress || exit 1

# Montage de la carte SD
[ -d /mnt ] || sudo mkdir /mnt /mnt/boot
sudo mount /dev/"$sd"2 /mnt || exit 1
sudo mount /dev/"$sd"1 /mnt/boot || exit 1

# Activation et configuration SSH
sudo touch /mnt/boot/ssh
echo "PermitRootLogin no" | sudo tee -a /mnt/etc/ssh/sshd_config || exit 1

# Mise à jour d'openssl
printf "Souhaitez-vous mettre à jour OpenSSL ? [O/n] "
read -r confirm
if [ "$confirm" = "o" ] || [ "$confirm" = "O" ]; then
    distro=$(grep "^ID=" /etc/os-release | cut -d '=' -f 2 )
    case "$distro" in
        "ubuntu"|"debian") sudo apt -y install openssl || exit 1 ;;
        "arch") sudo pacman -Sy openssl ;;
    esac
else
    echo "OpenSSL ne sera pas mit à jour"
fi
# Configuration mot de passe pi
echo "Veuillez rentrer le mot de passe de l'utilisateur pi"
pass_hash=$(openssl passwd -6) || exit 1
sudo sed -i "s|pi:\*:|pi:${pass_hash}:|g" /mnt/etc/shadow || exit 1

# Démontage de la carte
sudo umount -R /mnt || exit 1
echo "Installation terminée avec succès."
```

\pagebreak

# 10. Ressources utilisées

[Documentation Ubuntu isc-dhcp-server](https://doc.ubuntu-fr.org/isc-dhcp-server)

[Lire les baux des adresses IP](https://doc.ubuntu-fr.org/isc-dhcp-server#baux_leases)

[Acceder à internet depuis le client](https://memo-linux.com/configurer-un-simple-petit-routeur-nat-sous-debian-jessie/)

[Utiliser nmap](https://wiki.archlinux.org/title/Nmap)

[Utiliser fping](https://fping.org/fping.1.html)

[Configuration des cartes réseau avec nmcli](https://www.tecmint.com/nmcli-configure-network-connection/)

[Stockage des mots de passe dans le fichier /etc/shadow](https://unix.stackexchange.com/questions/557319/how-to-know-if-password-in-etc-shadow-is-hashed-with-sha-or-md)

[Génération des mots de passe avec OpenSSL](https://www.openssl.org/docs/man3.1/man1/openssl-passwd.html)
