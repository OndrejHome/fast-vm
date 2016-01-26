#!/bin/bash
LOG=/tmp/fast-vm-debug.log

function want_to_continue {
	echo -n "Do you want to continue? (y/n)"
	read answer
	
	if [ ! "$answer" == "y" ]; then
		echo "ending setup, no changes made"
		exit 0
	fi
}

echo "### 2 ### libvirt NAT network setup"
## network name
echo -n "Libvirt network/Bridge network [fast-vm-nat]: "
read net_name

if [ -z "$net_name" ]; then
	echo "[info] using default name 'fast-vm-nat'"
	net_name="fast-vm-nat"
fi
## subnet number
echo -n "Subnet (192.168.XXX.0/24) number [0-255, default 33]: "
read subnet_number

if [ -z "$subnet_number" ]; then
	echo "[info] using default subnet number 33 - 192.168.33.0/24"
	subnet_number="33"
fi

sed -e "s/NET_NAME/$net_name/g; s/SUBNET_NUMBER/$subnet_number/g" fast-vm.xml > /tmp/fast-vm-net-define.xml
## summary 
echo "New libvirt network would be configured from file /tmp/fast-vm-net-define.xml"
want_to_continue

virsh net-define /tmp/fast-vm-net-define.xml >> $LOG 2>&1
if [ ! "$?" -eq "0" ]; then 
	echo "[err] Error creating libvirt network, aborting"
	exit 1
fi
virsh net-autostart "$net_name" >> $LOG 2>&1
if [ ! "$?" -eq "0" ]; then 
	echo "[err] Error marking libvirt network as autostarted, aborting"
	exit 1
fi
virsh net-start "$net_name" >> $LOG 2>&1
if [ ! "$?" -eq "0" ]; then 
	echo "[err] Error starting libvirt network, aborting"
	exit 1
fi
## changing configuration file
echo "adding values to configuration file ~/.fast-vm/config"
if [ ! -d "$HOME/.fast-vm" ]; then 
	mkdir "$HOME/.fast-vm"
fi
echo "# libvirt_setup $(date)" >> $HOME/.fast-vm/config
echo "LIBVIRT_NETWORK=$net_name" >> $HOME/.fast-vm/config
echo "SUBNET_NUMBER=$subnet_number" >> $HOME/.fast-vm/config

echo "### 2 ### DONE"
