#!/bin/sh
if [ `whoami` != root ]; then 
  echo "Please run as a root."
  exit 1
fi

pacman -Syyu

sed -i.bak '/^#\[multilib\]/,/^#Include/{s/#//g}' /etc/pacman.conf

pacman -Syu --noconfirm --needed wine wine_gecko wine-mono

reboot