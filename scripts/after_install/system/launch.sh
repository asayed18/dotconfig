#!/bin/sh

# please change user name if needed

mkdir /home/void/drives
mkdir /home/void/drives/#1_Games1
mkdir /home/void/drives/#1_Games2
mkdir /home/void/drives/#1_Games3
mkdir /home/void/drives/#2_Games4
mkdir /home/void/drives/#2_Local
mkdir /home/void/drives/#2_SPLITVOL
mkdir /home/void/drives/#3_Games
mkdir /home/void/drives/#3_Others
mkdir /home/void/drives/#3_Store
mkdir /home/void/drives/#nvme
mkdir /home/void/drives/#ssd
sudo cp fstab /etc/fstab
sudo cp rc.local /etc/rc.local
sudo cp environment /etc/environment
sudo cp 99-user-script /etc/zzz.d/resume/
sudo cp autohibernate.sh /usr/libexec/elogind/system-sleep/