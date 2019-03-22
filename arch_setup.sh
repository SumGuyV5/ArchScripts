#!/bin/sh
if [ `whoami` != root ]; then 
  echo "Please run as root."
  exit 1
fi

UPDATE=false

AURMAN=false

OPENSSH=false

VMWARE=false
BHYVE=false

GNOME=false
GNOMEEX=false

KDE=false
KDEEX=false

XFCE=false
XFCEEX=false

DIS=false
DISPLAYMAN=gdm

GDM=false
SDDM=false
LIGHTDM=false
NONE=false

FIREFOX=false
CHROME=false
WINE=false

SUDO=false

USERS_SUDO=""

REBOOT=false

HELP=false

OPT=false

while getopts UoyvgkxEd:fcwsu:Rh option
do
  case "${option}"
  in    
  U) UPDATE=true;;
  a) AURMAN=true;;
  o) OPENSSH=true;;
  v) VMWARE=true;;
  b) BHYVE=true;;
  g) GNOME=true;;
  k) KDE=true;;
  x) XFCE=true;;
  E) GNOMEEX=true
      KDEEX=true
      XFCEEX=true;;
  d) DIS=true
     DISPLAYMAN=$OPTARG;;
  f) FIREFOX=true;;
  c) CHROME=true;;
  w) WINE=true;;
  s) SUDO=true;;
  u) SUDO=true
    USERS_SUDO=$OPTARG;;
  R) REBOOT=true;;
  h) HELP=true;;
  esac
  OPT=true
done

header() {
  HEADER=$1
  STRLENGTH=$(echo -n $HEADER | wc -m)
  DISPLAY="  " #65
  center=`expr $STRLENGTH / 2`
  max=`expr 33 - $center`
  echo $max
  for i in $(seq 1 $max)
  do
    DISPLAY="${DISPLAY}-"    
  done
  DISPLAY="${DISPLAY} "$HEADER" "
  
  STRLENGTH=$(echo -n $DISPLAY | wc -m)
  max=`expr 65 - $STRLENGTH`
  for i in $(seq 1 $max)
  do
    DISPLAY="${DISPLAY}-"
  done
    
  clear
  echo "  =================================================================="
  echo "$DISPLAY"
  echo "  =================================================================="
  echo ""
}

system_start() {
  systemctl start $1
  systemctl enable $1
}

system_stop()  {
  systemctl stop $1
  systemctl disable $1
}

download() {
  DOWNLOAD=$1
  if [ -f $DOWNLOAD ]; then
    echo "  already download."
  else
    curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/$DOWNLOAD
  fi
}

aur_download_build() {
  AUR=$1

  pac_man base-devel

  cd /tmp

  echo "$AUR downloading....."
  download $AUR.tar.gz

  echo "$AUR untar......"
  tar -xvzf $AUR.tar.gz

  chmod 777 $AUR
  cd $AUR

  echo "$AUR PKGBUILD....."
  su -s /bin/sh -c 'makepkg -si --noconfirm' nobody

  echo "$AUR installing....."
  pacman -U --noconfirm --needed *xz
}

pac_man() {
  DOWNLOAD=$@
  echo "Running Pacman... Download ${DOWNLOAD}"
  pacman -S --noconfirm --needed $DOWNLOAD
}

pac_man_rm() {
  REMOVE=$@
  pacman -R --noconfirm $REMOVE
}

help() {
  header "Help"
  echo "If you pass this script no options it will ask you what software you wish to install."
  echo ""
  echo "-U updates the system with pacman -Syyu --noconfirm --needed."
  echo "-a installs aurman."
  echo "-v installs open-vm-tools."
  echo "-b installs fbdev drivers and edits xorg.conf. need if you are runing on bhyve."
  echo "-g installs Gnome."
  echo "-k installs KDE."
  echo "-x installs XFCE."
  echo "-E installs extras for all windows managers you choose to install."
  echo "-d select and install a display manager. GDM(Gnome), SDDM(KDE), LightDM(XFCE). ie -d lightdm will select and install LightDM as your display manager."
  echo "-f installs Firefox."
  echo "-c installs Chrome."
  echo "-w installs Wine."
  echo "-s installs sudo."
  echo "-u add users to sudo group. This will install sudo if not already installed. ie -u richard will add user richard to group sudo."
  echo "-R Reboots computer after excuting the script."
  echo "-h this Help Text."
}

updatesystem() {
  if [ $UPDATE = true ]; then
    echo "Updating System."
    echo ""
    pacman -Syyuu --noconfirm --needed
  fi
}

aurman_install() {
  if [ $AURMAN = true ]; then
    echo "    Installing... aurman."
    echo ""
    
    gpg --recv-key 465022E743D71E39
    aur_download_build aurman
  fi
}

open_ssh() {
  if [ $OPENSSH = true ]; then
    echo "    Installing... openssh."
    echo ""
    
    pac_man openssh
  fi
}

vmware() {
  if [ $VMWARE = true ]; then
    echo "Installing... open-vm-tools."
    echo ""
    
    pac_man open-vm-tools xf86-input-vmmouse xf86-video-vmware mesa
    pac_man gtkmm3 libxtst
    
    system_start vmtoolsd
  fi
}

gnome() {
  if [ $GNOME = true ]; then
    echo "Installing... Gnome."
    echo ""
    
    pac_man gnome
    
    if [ $GNOMEEX = true ]; then
      echo "Installing... Gnome Extras."
      echo ""
      
      pac_man gnome-extra
    fi
  fi
}

kde() {
  if [ $KDE = true ]; then
    echo "Installing... KDE."
    echo ""
    
    pac_man plasma
  
    pac_man extra/ark extra/dolphin extra/konsole
    
    if [ $KDEEX = true ]; then
      echo "Installing... KDE Extras."
      echo ""
      
      pac_man extra
    fi
  fi
}

xfce() {
  if [ $XFCE = true ]; then
    echo "Installing... XFCE."
    echo ""
    
    pac_man xfce4
  
    pac_man ttf-dejavu ttf-liberation noto-fonts alsa-utils
    
    amixer set Master 100%
    amixer set PCM 100%
    amixer set Master unmute
    amixer set PCM unmute
    
    alsactl store 0
    
    if [ $XFCEEX = true ]; then
      echo "Installing... XFCE Extras."
      echo ""
      
      pac_man xfce4-goodies
    fi
  fi
}

#check to see if we are running on bhyve install fbdev video drivers and edit the xorg.conf
bhyve() {
  if [ $BHYVE = true ]; then
    pac_man dmidecode  
    dmidecode -t bios | grep 'Vendor: BHYVE'
    if [ $? = 0 ]; then
      pac_man xf86-video-fbdev
      Xorg -configure
      cp /root/xorg.conf.new /usr/share/X11/xorg.conf.d/xorg.conf
      if [ -f /usr/share/X11/xorg.conf.d/xorg.conf ]; then
        sed -i.bak 's/Driver      "modesetting"/Driver      "fbdev"/gi' /usr/share/X11/xorg.conf.d/xorg.conf
              
      fi
    fi
    pac_man_rm
  fi
}

display_man() {
  if [ $NONE = true ]; then
    return
  fi
  
  if [ $DIS = true ]; then
    case $DISPLAYMAN in
      [Gg]* ) GDM=true;;
      [Ss]* ) SDDM=true;;
      [Ll]* ) LIGHTDM=true;;
    esac
  fi
  
  if [ $GDM = true ]; then
    pac_man gdm
    system_start gdm
    system_stop sddm
    system_stop lightdm
  else
    if [ $SDDM = true ]; then
      pac_man sddm
      system_start sddm
      system_stop gdm
      system_stop lightdm
    else
      if [ $LIGHTDM = true ]; then
        system_stop sddm
        system_stop gdm
        pac_man lightdm lightdm-gtk-greeter
        pac_man xorg-server
        system_start lightdm
#      else
#        pacman -Q gdm
#        if [ $? = 0 ]
#        then
#          GDM=true
#        fi
#        pacman -Q sddm
#        if [ $? = 0 ]
#        then
#          SDDM=true
#        fi
#        pacman -Q xfdesktop
#        if [ $? = 0 ]
#        then
#          LIGHTDM=true
#        fi
#        #Recall
#        display_man
      fi
    fi   
  fi  
}

firefox() {
  if [ $FIREFOX = true ]; then
    echo "Installing... Firefox."
    echo ""
    
    pac_man firefox
  fi
}

chrome() {
  if [ $CHROME = true ]; then
    echo "Installing... Chrome."
    echo ""

    pac_man alsa-lib gtk3 libcups libxss libxtst nss
    
    aur_download_build "google-chrome"
  fi
}

wine() {
  if [ $WINE = true ]; then
    echo "Installing... Wine."
    echo ""
    
    sed -i.bak '/^#\[multilib\]/,/^#Include/{s/#//g}' /etc/pacman.conf

    updatesystem
    
    pac_man wine wine_gecko wine-mono
  fi  
}

sudo_install() {
  if [ $SUDO = true ]; then
    pac_man sudo
    
    sed -i.bak '/^# %sudo/s/^#//g' /etc/sudoers
  fi
}

add_sudo_user() {
  if [ ! -z $SUDO_USER ]; then
    [ $(getent group sudo) ] || groupadd sudo
    usermod -a -G sudo $USER_USER
  fi
}

reboot_com() {
  if [ $REBOOT = true ]; then
    echo "Rebooting..."
    echo ""
    
    reboot
  fi
}

question() {
  HEADER=$1
  QUESTION=$2
  RTN=0
  
  header "$HEADER"
  echo "    $QUESTION? [Y/N]"
  
  read yesno
  
  case $yesno in
    [Yy]* ) RTN=1;;
    [Nn]* ) RTN=0;;
  esac
  
  return $RTN
}

questionDis() {
  HEADER=$1
  QUESTION=$2
  RTN=0
  
  header "$HEADER"
  echo "    $QUESTION? [S/G/L/N]"
  
  read yesno
  
  case $yesno in
    [Ss]* ) SDDM=true;;
    [Gg]* ) GDM=true;;
    [Ll]* ) LIGHTDM=true;;
    [Nn]* ) NONE=true;;
    * ) NONE=true;;
  esac
}

question_adduser() {
  echo "Add user to group 'sudo'? [Y/N]"
  read yesno
  
  case $yesno in
    [Yy]* );;
    [Nn]* ) return;;
    * ) return;;
  esac
  
  END=false
  while [ $END = false ]
  do
    echo "Enter user to add to group 'sudo' or leave blank to exit."
    read USER_ADD
    
    if id "$USER_ADD" >/dev/null 2>&1; then
      echo "user does exist."
      [ $(getent group sudo) ] || groupadd sudo
      usermod -a -G sudo $USER_ADD
    else
      echo "user does not exist."
      echo "    would you like to exit? [Y/N]"
      
      read yesno
      
      case $yesno in
        [Yy]* ) END=true;;
        [Nn]* ) ;;
        * ) return;;
      esac
    fi    
  done  
}

ask_questions() {
  question "Update System." "Would you like to update the system"
  if [ "$?" = 1 ]; then
    UPDATE=true
  fi
  
  question "aurman install." "Would you like to install aurman"
  if [ "$?" = 1 ]; then
    AURMAN=true
  fi
  
  question "openssh install." "Would you like to install OpenSSH"
  if [ "$?" = 1 ]; then
    OPENSSH=true
  fi
  
  question "Install open-vm-tools." "Would you like to install open-vm-tools"
  if [ "$?" = 1 ]; then
    VMWARE=true
  fi
  
  question "Install on bhyve." "Are you running Arch on bhyve?"
  if [ "$?" = 1 ]; then
    BHYVE=true
  fi
  
  question "Install Gnome." "Would you like to install Gnome"
  if [ "$?" = 1 ]; then
    GNOME=true
    question "Install Gnome Extras." "Would you like to install Gnome Extras"
    if [ "$?" = 1 ]; then
      GNOMEEX=true
    fi
  fi
  
  question "Install KDE." "Would you like to install KDE"
  if [ "$?" = 1 ]; then
    KDE=true
    question "Install KDE Extras." "Would you like to install KDE Extras"
    if [ "$?" = 1 ]; then
      KDEEX=true
    fi
  fi
  
  question "Install XFCE." "Would you like to install XFCE"
  if [ "$?" = 1 ]; then
    XFCE=true
    question "Install XFCE Extras." "Would you like to install XFCE Extras"
    if [ "$?" = 1 ]; then
      XFCEEX=true
    fi
  fi
  
  questionDis "Display Manager." "What display manager would you like to use sddm(KDE) gdm(Gnome) lightdm(XFCE) or (None) to install no display manager"
    
  question "Install Firefox." "Would you like to install Firefox"
  if [ "$?" = 1 ]; then
    FIREFOX=true
  fi
  
  question "Install Chrome." "Would you like to install Chrome"
  if [ "$?" = 1 ]; then
    CHROME=true
  fi
  
  question "Install Wine." "Would you like to install Wine"
  if [ "$1" = 1 ]; then
    WINE=true
  fi
  
  question "Install sudo." "Would you like to install sudo"
  if [ "$?" = 1 ]; then
    SUDO=true
  fi
  
  question_adduser  
  
  question "Reboot Computer." "Would you like to Reboot the Computer"
  if [ "$?" = 1 ]; then
    REBOOT=true
  fi
}

execute_selection() {
  header "Installing..."
  
  updatesystem
  
  aurman_install
  
  open_ssh
  
  vmware
  
  bhyve
  
  gnome
  
  kde
  
  xfce
  
  display_man
  
  firefox
  
  chrome
  
  wine
  
  sudo_install
  
  add_sudo_user
  
  reboot_com
}

#------------------------------------------
#-    Main
#------------------------------------------
if [ $HELP = true ]; then
  help
  exit 1
fi

#If no flags have been passed we ask the user what they would like to do.
if [ $OPT = false ]; then
  ask_questions
fi

execute_selection