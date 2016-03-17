#!/bin/bash
# fast-vm helper script for privileged root actions

DEBUG_LOG=/tmp/fast-vm-helper.debug.log
if [ ! $(whoami) == 'root' ];
then
        echo "[err] this must be run as root"
        exit 1
fi
if [ ! -f '/etc/fast-vm.conf' ]; then
	echo "[err] global configuration file /etc/fast-vm.conf not found"
	exit 1
fi
# load global configuration file
. /etc/fast-vm.conf

function check_empty {
	var_name="$1"
	var_value="$2"
	if [ -z "$var_value" ]; then
		echo "[err] variable $var_name not declared in global configuration"
		echo "      run configure-fast-vm.sh again or fix manually"
		exit 2
	fi
}

check_empty "VM_PREFIX" "$VM_PREFIX"
check_empty "THINPOOL_VG" "$THINPOOL_VG"
check_empty "THINPOOL_LV" "$THINPOOL_LV"

read action arg1 arg2 arg3

case "$action" in
	lvcreate)
		if [ -z "$arg2" ]; then
			echo "[err] lvcreate requires 2/3 arguments"
			exit 1
		fi
		if [ "$arg1" == "base" ]; then
			lvcreate -n $VM_PREFIX$arg2 -V 10G --thinpool $THINPOOL_VG/$THINPOOL_LV >>$DEBUG_LOG 2>&1
		fi
		if [ "$arg1" == "newvm" ] && [ ! -z "$arg3" ]; then
			lvcreate -k n -s --thinpool $THINPOOL_VG/$THINPOOL_LV /dev/$THINPOOL_VG/$VM_PREFIX$arg2 --name $VM_PREFIX$arg3 >>$DEBUG_LOG 2>&1
		fi
		;;
	lvremove)
		if [ ! -b "$arg1" ]; then
			echo "[err] LV not found or not a block device"
			exit 1
		fi
		if [[ "$arg1" =~ /dev/$THINPOOL_VG/$VM_PREFIX ]]; then
			lvremove -f "$arg1" >>$DEBUG_LOG 2>&1
		else
			echo "[err] selected block device is not allowed to be removed"
			exit 1
		fi
		;;
	chgrp)
		if [ ! -b "$arg1" ]; then
			echo "[err] LV not found or not a block device"
			exit 1
		fi
		if [[ "$arg1" =~ /dev/$THINPOOL_VG/$VM_PREFIX ]]; then
			chgrp libvirt "$arg1" >>$DEBUG_LOG 2>&1
		else
			echo "[err] selected block device is not allowed for group change"
			exit 1
		fi
		;;
	dhcp_release)
		if [ -z "$arg3" ]; then
			echo "[err] dhcp_release requires 3 arguments"
			exit 1
		fi
		#FIXME validation of arguments for dhcp_release
		dhcp_release "$arg1" "$arg2" "$arg3" >>$DEBUG_LOG 2>&1
		;;
	*)
		echo "[err] unknown action"
		exit 3
		;;
esac
