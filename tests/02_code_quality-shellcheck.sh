#!/bin/bash
echo "##### shellcheck #####"
for i in configure-fast-vm fast-vm fast-vm-helper.sh fast-vm-image fast-vm-net-cleanup; do echo -n "$i: "; shellcheck -x $i|wc -l; done
