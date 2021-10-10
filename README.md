# ArchScripts
ArchLinux Scripts to make life easy.

## arch_setup.sh

Asks you questions about what packages you wish to install and setup.

```sh
arch_setup.sh -v -x -d lightdm -f -s -u richard -R
```

-v installs open-vm-tools. -x installs XFCE desktop environment. -d lightdm installs lightdm display manager. -f installs Firefox. -s installs sudo. -u richard adds user 'richard' to sudo group. -R restarts the computer.

## aur_download.sh

Downloads and installs aur packages from aur.

```sh
aur_download.sh aurman
```

Download and install pass in package.

## update.sh

Updates packages install using pacman and aurman.

```sh
update.sh
```

## wine.sh

Installs wine so you can run windows apps on linux.

```sh
wine.sh
```
