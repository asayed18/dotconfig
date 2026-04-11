#! /bin/bash

VERSION=latest

while getopts ":v:" opt; do
  case $opt in
    v)
      VERSION=$OPTARG
      echo "-v was triggered, Parameter: $VERSION" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
IMAGE=/boot/vmlinuz-$VERSION

tar xvf $1 --strip-components=1 -C ~/temp/ 
cd ~/temp/
cp /boot/config-$(uname -r) ./.config
make localmodconfig -y
make -j12
sudo make modules_install -j12
cp ./arch/x86/boot/bzImage $IMAGE
sudo dracut --force --hostonly --kernel-image $IMAGE
sudo update-grub


# Cleaning
cd ..
rm -rf ./temp
#