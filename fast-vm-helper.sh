#!/bin/sh
# fast-vm helper script for privileged root actions

DEBUG_LOG_CMD="logger -p debug -t fast-vm-helper-dbg"
LOG_LEVEL=7
DISPLAY_LEVEL=7

## terminal colors
c_red=$(tput setaf 1)
c_yellow=$(tput setaf 3)
c_green=$(tput setaf 2)
c_cyan=$(tput setaf 6)
c_normal=$(tput sgr0)

## LOG priorities
P_DEBUG=7
P_INFO=6
P_NOTICE=5
P_WARNING=4
P_ERROR=3

# function for message output to display&logs based on LOG/DISPLAY level
pmsg () {
	priority="$1"
	message="$2"
	if [ "$LOG_LEVEL" -ge "$priority" ]; then
		printf "$USER | $message"|logger -p $priority --id -t fast-vm-helper
	fi
	if [ "$DISPLAY_LEVEL" -ge "$priority" ]; then
		case "$priority" in
			$P_DEBUG)
				printf "[${c_cyan}inf${c_normal}] $message"
				;;
			$P_INFO)
				printf "[${c_green}ok${c_normal}] $message"
				;;
			$P_WARNING)
				printf "[${c_yellow}wrn${c_normal}] $message"
				;;
			$P_ERROR)
				printf "[${c_red}err${c_normal}] $message"
				;;
			*)
				printf "[unk] $message"
				;;
		esac
	fi
}
if [ ! $(whoami) = 'root' ];
then
        pmsg $P_ERROR "this must be run as root\n"
        exit 1
fi
if [ ! -f '/etc/fast-vm.conf' ]; then
	pmsg $P_ERROR "global configuration file /etc/fast-vm.conf not found\n"
	exit 1
fi
# load global configuration file
. /etc/fast-vm.conf

check_empty () {
	var_name="$1"
	var_value="$2"
	if [ -z "$var_value" ]; then
                pmsg $P_ERROR "variable $var_name not declared in global configuration run configure-fast-vm again or fix manually\n"
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
			pmsg $P_ERROR "LV name validation failed\n"
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
				arg3=$(echo "$arg3"|egrep '^[0-9]+$')
				if  [ -z "$arg3" ]; then
					pmsg $P_ERROR "LV size validation failed\n"
					exit 1
				fi
				lvcreate -n $VM_PREFIX$arg2 -V ${arg3}G --thinpool $THINPOOL_VG/$THINPOOL_LV 2>&1|$DEBUG_LOG_CMD
			;;
			newvm)
				lvcreate -k n -s --thinpool $THINPOOL_VG/$THINPOOL_LV /dev/$THINPOOL_VG/$VM_PREFIX$arg2 --name $VM_PREFIX$arg3 2>&1|$DEBUG_LOG_CMD
			;;
			*)
				pmsg $P_ERROR "wrong action for lvcreate\n"
				exit 1
		esac
		;;
	lvremove)
		arg1=$(echo "$arg1" | egrep "/dev/$THINPOOL_VG/$VM_PREFIX[a-zA-Z0-9.-]+$")
		if [ -z "$arg1" ] || [ ! -b "$arg1" ]; then
			pmsg $P_ERROR "LV not found, not a block device or not allowed to be removed\n"
			exit 1
		fi

		lvremove -f "$arg1" 2>&1|$DEBUG_LOG_CMD
		;;
	lvresize)
		arg1=$(echo "$arg1" | egrep "/dev/$THINPOOL_VG/$VM_PREFIX[a-zA-Z0-9.-]+$")
		if [ -z "$arg1" ] || [ ! -b "$arg1" ]; then
			pmsg $P_ERROR "LV not found, not a block device or not allowed to be resized\n"
			exit 1
		fi
		arg2=$(echo "$arg2"|egrep '^[0-9]+$')
		if  [ -z "$arg2" ]; then
			pmsg $P_ERROR "LV size validation failed\n"
			exit 1
		fi

		lvresize -f -L ${arg2}G "$arg1" 2>&1|$DEBUG_LOG_CMD
		;;
	chgrp)
		arg1=$(echo "$arg1" | egrep "/dev/$THINPOOL_VG/$VM_PREFIX[a-zA-Z0-9.-]+$")
		if [ -z "$arg1" ] || [ ! -b "$arg1" ]; then
			pmsg $P_ERROR "LV not found, not a block device or not allowed to be chgrp\n"
			exit 1
		fi

		chgrp $FASTVM_GROUP "$arg1" 2>&1|$DEBUG_LOG_CMD
		;;
	dhcp_release)
		PATH="$PATH:/usr/sbin" which dhcp_release >/dev/null 2>&1
		if [ "$?" -eq '0' ]; then
			arg2=$(echo "$arg2"| egrep '^[0-9]+$')
			arg3=$(echo "$arg3"| egrep '^[a-f0-9]{2,2}:[a-f0-9]{2,2}:[a-f0-9]{2,2}:[a-f0-9]{2,2}:[a-f0-9]{2,2}:[a-f0-9]{2,2}$')
			if [ -z "$arg2" ] || [ -z "$arg3" ] || [ "$arg2" -lt 20 ] || [ "$arg2" -gt 220 ]; then
				pmsg $P_ERROR "validation of VM number or mac address failed\n"
				exit 1
			fi

			dhcp_release "$LIBVIRT_NETWORK" "192.168.$SUBNET_NUMBER.$arg2" "$arg3" 2>&1|$DEBUG_LOG_CMD
		else
			printf "[wrn] dhcp_release not found, to reuse the same VM number you would need to delete DHCP leases file for $LIBVIRT_NETWORK network and restart this network in the libvirt.\nhttp://lists.thekelleys.org.uk/pipermail/dnsmasq-discuss/2007q1/001094.html\n"
		fi

		;;
	*)
		pmsg $P_ERROR "unknown action\n"
		exit 3
		;;
esac
