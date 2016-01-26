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

#################################
echo "### 1 ### LVM thin pool setup"
## VG for thin pool
echo -n "VG for lvm thin pool []: "
read vg_of_thin_pool

if [ -z "$vg_of_thin_pool" ]; then
	echo "[err] VG cannot be empty"
	exit 1
fi
vgdisplay "$vg_of_thin_pool" >> $LOG 2>&1
vg_ret="$?"

if [ ! "$vg_ret" == "0" ]; then
	echo "[err] cannot use VG '$vg_of_thin_pool', vgdisplay exited with $vg_ret"
	exit 1
fi
## thin pool name
echo -n "LVM thin pool name [fast-vm-pool]: "
read thin_pool_name

if [ -z "$thin_pool_name" ]; then
	echo "[info] using default LVM thin pool name 'fast-vm-pool'"
	thin_pool_name="fast-vm-pool"
fi
lvdisplay "$vg_of_thin_pool/$thin_pool_name" >> $LOG 2>&1
lvp_ret="$?"

if [ "$lvp_ret" == "0" ]; then
	echo "[err] LV with name $thin_pool_name already exists in the VG '$vg_of_thin_pool', use different name"
	exit 1
fi
## size
echo -n "LVM thin pool size [50G]: "
read thin_pool_size

if [ -z "$thin_pool_size" ]; then
	echo "[info] using default size of 50G"
	thin_pool_size="50G"
fi
## summary
echo "Following commands would be executed to create thin pool:"
echo "  lvcreate -n $thin_pool_name -L $thin_pool_size $vg_of_thin_pool"
echo "  lvconvert --type thin-pool $vg_of_thin_pool/$thin_pool_name"
want_to_continue

## create thin pool
lvcreate -n $thin_pool_name -L $thin_pool_size $vg_of_thin_pool >> $LOG 2>&1
if [ ! "$?" -eq "0" ]; then 
	echo "[err] Error while creating LV for thin pool, aborting"
fi
lvconvert --type thin-pool $vg_of_thin_pool/$thin_pool_name 
if [ ! "$?" -eq "0" ]; then 
	echo "[err] Error while converting LV into thin pool, aborting"
fi
###################
if [ ! -f fast-vm.xml ]; then
	echo "default fast-vm.xml file missing, exiting"
	exit 1
fi

## changing configuration file
echo "adding values to configuration file ~/.fast-vm/config"
if [ ! -d "$HOME/.fast-vm" ]; then 
	mkdir "$HOME/.fast-vm"
fi
echo "# thin_lvm_setup $(date)" >> $HOME/.fast-vm/config
echo "THINPOOL_VG=$vg_of_thin_pool" >> $HOME/.fast-vm/config
echo "THINPOOL_LV=$thin_pool_name" >> $HOME/.fast-vm/config

echo "### 1 ### DONE"
