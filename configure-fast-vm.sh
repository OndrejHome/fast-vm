#!/bin/bash
config_file="/etc/fast-vm.conf"

# load defaults and old configuration if exists
if [ -f /usr/share/fast-vm/fast-vm.conf.defaults ]; then
	. /usr/share/fast-vm/fast-vm.conf.defaults
fi
if [ -f "$config_file" ]; then
	. $config_file
else
	touch $config_file
fi

function ask_question {
	question="$1"
	default_value="$2"
	config_variable="$3"

	# lets get meaningfull answer from user
	success=0
	while [ "$success" -eq 0 ];
	do
		echo -n "[?] $question [$default_value]: "
		read answer
		if [ -z "$default_value" ] && [ -z "$answer" ]; then
			echo "[err] You must provide value"
		else
			success=1
		fi
	done

	# and write the output into configuration file
	sed -i "/^$config_variable=/d" $config_file
	if [ -z "$answer" ]; then
		echo "$config_variable=$default_value" >> $config_file
	else
		echo "$config_variable=$answer" >> $config_file
	fi
}

success=0
while [ "$success" -eq 0 ];
do

	ask_question "VM name prefix in libvirt" "$VM_PREFIX" "VM_PREFIX"

	ask_question "VG for LVM thin pool" "$THINPOOL_VG" "THINPOOL_VG"
	ask_question "LVM thin pool name" "$THINPOOL_LV" "THINPOOL_LV"
	ask_question "LVM thin pool size" "$THINPOOL_SIZE" "THINPOOL_SIZE"

	ask_question "Libvirt network (bridge) name" "$LIBVIRT_NETWORK" "LIBVIRT_NETWORK"
	ask_question "Libvirt subnet number (192.168.XX.0/24)" "$SUBNET_NUMBER" "SUBNET_NUMBER"

	## reload the configuration file and check the system for changes
	. $config_file

	# LVM VG check
	if [ ! -d "/dev/$THINPOOL_VG" ]; then
		echo "[err] VG '$THINPOOL_VG' not found"
		continue
	fi

	# LVM thinpool LV check
	lvdisplay $THINPOOL_VG/$THINPOOL_LV >/dev/null 2>&1
	if [ ! "$?" -eq "0" ]; then
		echo "[wrn] LV '$THINPOOL_VG/$THINPOOL_LV' not found"
		echo "Following commands would be executed to create thin pool:"
		echo "  lvcreate -n $THINPOOL_LV -L $THINPOOL_SIZE $THINPOOL_VG"
		echo "  lvconvert --type thin-pool $THINPOOL_VG/$THINPOOL_LV"
		echo -n "[?] Create now? (y/n) "
		read answer
		if [ "$answer" == "y" ]; then
			echo "[inf] Creating ..."
			## create thin pool
			lvcreate -n $THINPOOL_LV -L $THINPOOL_SIZE $THINPOOL_VG
			if [ ! "$?" -eq "0" ]; then
				echo "[err] Error while creating LV for thin pool, aborting"
				exit 1
			fi
			lvconvert --type thin-pool $THINPOOL_VG/$THINPOOL_LV
			if [ ! "$?" -eq "0" ]; then
				echo "[err] Error while converting LV into thin pool, aborting"
				exit 1
			fi
			echo "[inf] LVM thinpool successfuly created"
		else
			echo "[wrn] fast-vm will not work without thinpool LV!"
		fi
	fi

	# check if the LV is a thinpool
	is_thin_pool=$(lvdisplay /dev/$THINPOOL_VG/$THINPOOL_LV 2>/dev/null|grep 'LV Pool'|wc -l)
	if [ ! "$is_thin_pool" -eq "2" ]; then
		echo "[err] LV /dev/$THINPOOL_VG/$THINPOOL_LV is not a thin pool"
		echo "To create a thinpool for fast-vm delete this LV a run the configuration again"
		exit 1
	fi

	# check for the libvirt network
	virsh --connect qemu:///system net-info "$LIBVIRT_NETWORK" 2>&1 >/dev/null
	if [ ! "$?" -eq "0" ]; then
		echo -n "[?] Network $LIBVIRT_NETWORK is not defined in libvirt, define now? (y/n) "
		read answer
		if [ "$answer" == "y" ]; then
			echo "[inf] Creating ..."
			tmp_file=$(mktemp --suffix=.xml)
			sed -e "s/NET_NAME/$LIBVIRT_NETWORK/g; s/SUBNET_NUMBER/$SUBNET_NUMBER/g" /usr/share/fast-vm/fast-vm-network.xml > $tmp_file
			virsh --connect qemu:///system net-define $tmp_file
			if [ ! "$?" -eq "0" ]; then
				echo "[err] Error creating libvirt network, aborting"
				exit 1
			fi
			virsh --connect qemu:///system net-autostart "$LIBVIRT_NETWORK"
			if [ ! "$?" -eq "0" ]; then
				echo "[err] Error marking libvirt network as autostarted, aborting"
				exit 1
			fi
			virsh --connect qemu:///system net-start "$LIBVIRT_NETWORK"
			if [ ! "$?" -eq "0" ]; then
				echo "[err] Error starting libvirt network, aborting"
				exit 1
			fi
			echo "[inf] fast-vm libvirt network created and autostarted"
		else
			echo "[wrn] fast-vm will not work without libvirt network!"
		fi
	fi

	is_subnet_number=$(virsh --connect qemu:///system net-dumpxml "$LIBVIRT_NETWORK" 2>/dev/null|grep 'ip address'|cut -d. -f3)
	if [ "$is_subnet_number" != "$SUBNET_NUMBER" ];then
		echo "[err] Libvirt network subnet is different from one provided in fast-vm configuration"
		echo "fix fast-vm configuration or libvirt network configuration"
		exit 1
	fi
	echo "[inf] fast-vm configured"
	success=1
done
