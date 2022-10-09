#!/bin/bash
set -x
set -euf -o pipefail

# Select CPU

PS3="Install microcodes for CPU: "
UCODE_PACKAGE=""
select opt in "AMD" "Intel" "Skip"; do
    case $opt in
    "AMD")
        UCODE_PACKAGE="amd-ucode"
        break
        ;;
    "Intel")
        UCODE_PACKAGE="intel-ucode"
        break
        ;;
    "Skip")
        break
        ;;
    *)
    echo "Invalid option"
    esac
done

# System time

ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Locale

sed -i "s/#en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Hosts

read -p "Enter hostname (default 'arch'): " HOSTNAME
HOSTNAME=${HOSTNAME:-"arch"}

echo "$HOSTNAME" >> /etc/hostname

echo "127.0.0.1	localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1	${HOSTNAME}" >> /etc/hosts

# Packages

pacman -S --noconfirm networkmanager btrfs-progs sudo "$UCODE_PACKAGE"

# Services

systemctl enable NetworkManager
systemctl mask NetworkManager-wait-online

# Bootloader

bootctl install

rm /boot/loader/loader.conf
echo "default arch.conf" >> /boot/loader/loader.conf
echo "timeout 0" >> /boot/loader/loader.conf
echo "console-mode auto" >> /boot/loader/loader.conf
echo "editor no" >> /boot/loader/loader.conf

echo "title Arch Linux" >> /boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf

if [[ -n $UCODE_PACKAGE ]]
then
    echo "initrd /${UCODE_PACKAGE}.img" >> /boot/loader/entries/arch.conf
fi

echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf
echo "options root=LABEL=ROOT rootflags=subvol=@ rw" >> /boot/loader/entries/arch.conf

# User

read -p "Enter user name: " USER
useradd -m -G wheel "$USER"
passwd "$USER"

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Disable root

passwd -l root

# Remove this script

rm -- "$0"
