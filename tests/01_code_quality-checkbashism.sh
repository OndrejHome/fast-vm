#!/bin/bash
echo "##### checkbashism #####"
for i in fast-vm fast-vm-helper.sh fast-vm-image configure-fast-vm fast-vm-net-cleanup; do echo "## ==== $i"; checkbashisms $i; done
