#!/bin/bash

echo "##==>> fast-vm setup script"
echo "copying fast-vm into /usr/local/sbin/fast-vm"
cp fast-vm /usr/local/sbin
echo "## running configuration scripts for initial setup"

cmds="lvcreate lvconvert gunzip virsh virt-edit"

for i in $cmds
do
	which "$i" >/dev/null 2>&1
	if [ ! "$?" -eq "0" ];
	then
		echo "command $i not found, please install it before continuing"
		exit 1
	fi
done

. setup-general.sh
. setup-thin-lvm.sh
. setup-libvirt-net.sh
