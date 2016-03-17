#!/bin/bash

if [ "$(whoami)" != "root" ]; then
	echo "this must be run as root"
	exit 1
fi
echo "##==>> fast-vm setup script"

if [ -f "/usr/local/bin/fast-vm" ]; then
	echo "[??] File /usr/local/bin/fast-vm already present, do you want to just update fast-vm without running configuration? [yes] "
	read just_upgrade

	if [ -z "$just_upgrade" ] || [ "$just_updagrade" == "yes" ]; then
		echo "[info] setup will only update fast-vm scripts and then exit without reconfiguration"
	fi
fi
if [ -f "/usr/local/sbin/fast-vm" ]; then
	echo "[info] removing old root-only version of fast-vm from /usr/local/sbin/fast-vm"
	rm -f /usr/local/sbin/fast-vm
fi
echo "copying fast-vm into /usr/local/bin/fast-vm"
cp fast-vm /usr/local/bin/fast-vm

bash_completion_dir=$(pkg-config --variable=completionsdir bash-completion 2>/dev/null|head -1)
if [ -d "$bash_completion_dir" ]; then
	cp fast-vm.bash_completion $bash_completion_dir/fast-vm
fi

if [ ! -d /usr/local/libexec ]; then mkdir /usr/local/libexec; fi
cp fast-vm-helper.sh /usr/local/libexec/fast-vm-helper.sh

cp fast-vm-sudoers /etc/sudoers.d/fast-vm-sudoers

echo "!! IMPORTANT !!"
echo "User that would use fast-vm must be in group 'libvirt'."
echo "You can easily add user to libvirt group using command below"
echo "  # usermod -a -G libvirt <user>"

echo "## checking for requirements"
cmds="lvcreate lvconvert gunzip virsh virt-edit sudo"

for i in $cmds
do
	which "$i" >/dev/null 2>&1
	if [ ! "$?" -eq "0" ];
	then
		echo "command $i not found, please install it before continuing"
		exit 1
	fi
done

if [ -f /etc/fast-vm.conf ] && [ -z "$just_upgrade" ] || [ "$just_updagrade" == "yes" ]; then
	echo "[info] Update complete"
	exit 0
fi

echo "## running configuration scripts for initial setup"
## new configuration script
. configure-fast-vm.sh
