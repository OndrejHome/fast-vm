#!/bin/bash

echo "### 0 ###"
echo -n "VM name prefix [fastvm-]: "
read vm_prefix

if [ -z "$vm_prefix" ]; then
	vm_prefix="fastvm-"
	echo "[info] using default VM name prefix - $vm_prefix"
fi

## changing configuration file
echo "adding values to configuration file ~/.fast-vm/config"
if [ ! -d "$HOME/.fast-vm" ]; then 
	mkdir "$HOME/.fast-vm"
fi
echo "# general_setup $(date)" >> $HOME/.fast-vm/config
echo "VM_PREFIX=$vm_prefix" >> $HOME/.fast-vm/config
