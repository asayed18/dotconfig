#!/bin/sh

# please change user name if needed

mkdir $HOME/drives
mkdir $HOME/drives/#1_Games1
mkdir $HOME/drives/#1_Games2
mkdir $HOME/drives/#1_Games3
mkdir $HOME/drives/#2_Games4
mkdir $HOME/drives/#2_Local
mkdir $HOME/drives/#2_SPLITVOL
mkdir $HOME/drives/#3_Games
mkdir $HOME/drives/#3_Others
mkdir $HOME/drives/#3_Store
mkdir $HOME/drives/#nvme
mkdir $HOME/drives/#ssd
sudo cp fstab /etc/fstab
sudo cp rc.local /etc/rc.local
sudo cp environment /etc/environment
sudo cp 99-user-script /etc/zzz.d/resume/
sudo cp autohibernate.sh /usr/libexec/elogind/system-sleep/