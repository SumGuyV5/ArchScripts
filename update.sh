#!/bin/sh
if [ `whoami` = root ]; then 
  echo "Please do not run as root."
  exit 1
fi

sudo pacman -Syyu --noconfirm

if [ -f /usr/bin/aurman ]; then
  aurman -Syu --aur --noconfirm
fi