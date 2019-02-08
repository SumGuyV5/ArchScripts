#!/bin/sh
if [ `whoami` == root ]; then 
  echo "Please run as user."
  exit 1
fi
if [ -z "$1" ]; then
  echo "pass the aur you wish to download."
  exit 1
fi

KEEP=false;
HELP=false;
AURS=""

while getopts kh option
do
  case "${option}"
  in    
  k) KEEP=true;;
  h) HELP=true;;
  *) AURS="${option};";;
  esac
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
    DISPLAY+="-"    
  done
  DISPLAY+=" "$HEADER" "
  
  STRLENGTH=$(echo -n $DISPLAY | wc -m)
  max=`expr 65 - $STRLENGTH`
  for i in $(seq 1 $max)
  do
    DISPLAY+="-"
  done
    
  clear
  echo "  =================================================================="
  echo "$DISPLAY"
  echo "  =================================================================="
  echo ""
}

help() {
  header "Help"
  echo "-k this flag will tell the script keep and not to delete the tmp fold. The tmp folder has the download aur and working files."
  echo "-h this Help Text."  
}

pac_man() {
  DOWNLOAD=$@
  echo "Running Pacman... Download ${DOWNLOAD}"
  sudo pacman -S --noconfirm --needed $DOWNLOAD
}

download() {
  DOWNLOAD=$1
  if [ -f $DOWNLOAD ]; then
    echo "  already download."
  else
    curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/$DOWNLOAD
  fi
}

if [ $HELP = true ]; then
  help
  exit 1
fi

#Is there a better way to do this?
if [ $KEEP = true ]; then
  AUR=$2
else
  AUR=$1
fi

# ask for password up-front.
sudo -v
# Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

pac_man base-devel

if [ ! -d "tmp" ]; then
  mkdir tmp
fi

cd tmp

echo "$AUR downloading....."
download $AUR.tar.gz

echo "$AUR untar......"
tar -xvzf $AUR.tar.gz

chmod 0777 $AUR
cd $AUR

echo "$AUR PKGBUILD....."
makepkg -si --noconfirm

echo "$AUR installing....."
sudo pacman -U --noconfirm --needed *xz

#delete the tmp folder.
if [ $KEEP = true ]; then
  rm -R tmp
fi