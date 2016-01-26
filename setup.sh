#!/bin/bash

echo "##==>> fast-vm setup script"
echo "copying fast-vm into /usr/local/sbin/fast-vm"
cp fast-vm /usr/local/sbin
echo "## running configuration scripts for initial setup"

. setup-general.sh
. setup-thin-lvm.sh
. setup-libvirt-net.sh
