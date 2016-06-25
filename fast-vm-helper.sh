#!/bin/sh
# fast-vm helper script for privileged root actions

DEBUG_LOG=/tmp/fast-vm-helper.debug.log
if [ ! $(whoami) = 'root' ];
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

check_empty () {
	var_name="$1"
	var_value="$2"
	if [ -z "$var_value" ]; then
		echo "[err] variable $var_name not declared in global configuration"
		echo "      run configure-fast-vm again or fix manually"
		exit 2
	fi
}

check_empty "VM_PREFIX" "$VM_PREFIX"
check_empty "THINPOOL_VG" "$THINPOOL_VG"
check_empty "THINPOOL_LV" "$THINPOOL_LV"
check_empty "LIBVIRT_NETWORK" "$LIBVIRT_NETWORK"
check_empty "SUBNET_NUMBER" "$SUBNET_NUMBER"
check_empty "FASTVM_GROUP" "$FASTVM_GROUP"

read action arg1 arg2 arg3

case "$action" in
	lvcreate)
		arg2=$(echo "$arg2"|egrep '^[a-zA-Z0-9.-]+$')
		if [ -z "$arg2" ]; then
			echo "[err] LV name validation failed"
			exit 1
		fi
		arg3=$(echo "$arg3"|egrep '^[a-zA-Z0-9.-]+$')
		if [ "$arg1" = "newvm" ]; then
			if  [ -z "$arg3" ] || [ ! -b "/dev/$THINPOOL_VG/$VM_PREFIX$arg2" ]; then
				echo "[err] newvm LV name validation failed"
				exit 1
			fi
		fi

		case "$arg1" in
			base)
				lvcreate -n $VM_PREFIX$arg2 -V 10G --thinpool $THINPOOL_VG/$THINPOOL_LV >>$DEBUG_LOG 2>&1
			;;
			newvm)
				lvcreate -k n -s --thinpool $THINPOOL_VG/$THINPOOL_LV /dev/$THINPOOL_VG/$VM_PREFIX$arg2 --name $VM_PREFIX$arg3 >>$DEBUG_LOG 2>&1
			;;
			*)
				echo "[err] wrong action for lvcreate"
				exit 1
		esac
		;;
	lvremove)
		arg1=$(echo "$arg1" | egrep "/dev/$THINPOOL_VG/$VM_PREFIX[a-zA-Z0-9.-]+$")
		if [ -z "$arg1" ] || [ ! -b "$arg1" ]; then
			echo "[err] LV not found, not a block device or not allowed to be removed"
			exit 1
		fi

		lvremove -f "$arg1" >>$DEBUG_LOG 2>&1
		;;
	chgrp)
		arg1=$(echo "$arg1" | egrep "/dev/$THINPOOL_VG/$VM_PREFIX[a-zA-Z0-9.-]+$")
		if [ -z "$arg1" ] || [ ! -b "$arg1" ]; then
			echo "[err] LV not found, not a block device or not allowed to be chgrp"
			exit 1
		fi

		chgrp $FASTVM_GROUP "$arg1" >>$DEBUG_LOG 2>&1
		;;
	dhcp_release)
		PATH="$PATH:/usr/sbin" which dhcp_release >/dev/null 2>&1
		if [ "$?" -eq '0' ]; then
			arg2=$(echo "$arg2"| egrep '^[0-9]+$')
			arg3=$(echo "$arg3"| egrep '^[a-f0-9]{2,2}:[a-f0-9]{2,2}:[a-f0-9]{2,2}:[a-f0-9]{2,2}:[a-f0-9]{2,2}:[a-f0-9]{2,2}$')
			if [ -z "$arg2" ] || [ -z "$arg3" ] || [ "$arg2" -lt 20 ] || [ "$arg2" -gt 220 ]; then
				echo "[err] validation of VM number or mac address failed"
				exit 1
			fi

			dhcp_release "$LIBVIRT_NETWORK" "192.168.$SUBNET_NUMBER.$arg2" "$arg3" >>$DEBUG_LOG 2>&1
		else
			printf "[wrn] dhcp_release not found, to reuse the same VM number you would need to delete DHCP leases file for $LIBVIRT_NETWORK network and restart this network in the libvirt.\nhttp://lists.thekelleys.org.uk/pipermail/dnsmasq-discuss/2007q1/001094.html\n"
		fi

		;;
	*)
		echo "[err] unknown action"
		exit 3
		;;
esac
