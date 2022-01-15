## fast-vm on fast-vm test environment setup
This environemnt is used for testing fast-vm functionality on various platforms.

Recommended minimal testing specs:
- 2 vCPU
- 3GB RAM (more than 1GB is needed to test running of images)
- extra 11GB disk (`sdb`) - for fast-vm thinpool

NOTE: Following are specifics to my test environment that you may need to adjust/change:
- `README.md` - VG name on hypervisor is `vg_raid5`
- `README.md` - VM numbers are from range 61-79
- `01_setup_fast-vm.yaml` - `192.168.5.31` is local repository server for RHEL repositories
- `ansible_hosts` - `192.168.2.0/24` is subnet with fast-vm VMs on hypervisor
- gentoo VMs are not (yet) part of the setup

### 1. Preparing fast-vm host
- create special profiles with recommended specs
~~~
fast-vm-image import_profile fvm-alma-8.5 alma-8.5 alma-8.3-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/alma/hacks/6g_alma-8-hacks.sh
fast-vm-image import_profile fvm-centos-7.9 centos-7.9 centos-6.3-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/centos/hacks/6g_centos-7-hacks.sh
fast-vm-image import_profile fvm-centos-8.5 centos-8.5 centos-6.3-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/centos/hacks/6g_centos-8-hacks.sh
fast-vm-image import_profile fvm-debian-10.11 debian-10.11 debian-9-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/debian/hacks/debian-10.sh
fast-vm-image import_profile fvm-debian-11.2 debian-11.2 debian-9-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/debian/hacks/debian-11.sh
fast-vm-image import_profile fvm-fedora34 fedora34 fedora-28-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/fedora/hacks/6g_fedora-34-hacks.sh
fast-vm-image import_profile fvm-fedora35 fedora35 fedora-28-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/fedora/hacks/6g_fedora-35-hacks.sh
#fast-vm-image import_profile fvm-gentoo-s gentoo210905s gentoo.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/gentoo/hacks/gentoo-hacks-systemd.sh
#fast-vm-image import_profile fvm-gentoo-o gentoo210905o gentoo.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/gentoo/hacks/gentoo-hacks-openrc-ens.sh
fast-vm-image import_profile fvm-u1804.4 u1804.4 ubuntu-lts-1804-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/ubuntu/hacks/ubuntu-1804-hacks.sh
fast-vm-image import_profile fvm-u2004.0 u2004.0 ubuntu-lts-1804-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/ubuntu/hacks/ubuntu-2004-hacks.sh
fast-vm-image import_profile fvm-rhel-7.9 rhel-7.9 rhel-6.3-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/rhel/hacks/6g_rhel-7-hacks.sh
fast-vm-image import_profile fvm-rhel-8.5 rhel-8.5 rhel-6.3-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/rhel/hacks/6g_rhel-8-hacks.sh
~~~
- create VMs based on profiles
~~~
fast-vm create fvm-alma-8.5 61
fast-vm create fvm-centos-7.9 62
fast-vm create fvm-centos-8.5 63
fast-vm create fvm-debian-10.11 64
fast-vm create fvm-debian-11.2 65
fast-vm create fvm-fedora34 66
fast-vm create fvm-fedora35 67
#fast-vm create fvm-gentoo-s 68
#fast-vm create fvm-gentoo-o 69
fast-vm create fvm-u1804.4 70
fast-vm create fvm-u2004.0 71
fast-vm create fvm-rhel-7.9 72
fast-vm create fvm-rhel-8.5 73
~~~
- create sparse disks for VMs to be used for thinpool
~~~
for i in {61..73}; do lvcreate -n data$i -V 11G --thinpool vg_raid5/fastvm_raid5_pool; done
~~~
- attach disks
~~~
virsh attach-disk fastvm-alma-8.5-61 /dev/vg_raid5/data61 sdb --config --targetbus scsi
virsh attach-disk fastvm-centos-7.9-62 /dev/vg_raid5/data62 sdb --config --targetbus scsi
virsh attach-disk fastvm-centos-8.5-63 /dev/vg_raid5/data63 sdb --config --targetbus scsi
virsh attach-disk fastvm-debian-10.11-64 /dev/vg_raid5/data64 sdb --config --targetbus scsi
virsh attach-disk fastvm-debian-11.2-65 /dev/vg_raid5/data65 sdb --config --targetbus scsi
virsh attach-disk fastvm-fedora34-66 /dev/vg_raid5/data66 sdb --config --targetbus scsi
virsh attach-disk fastvm-fedora35-67 /dev/vg_raid5/data67 sdb --config --targetbus scsi
#virsh attach-disk fastvm-gentoo210905s-68 /dev/vg_raid5/data68 sdb --config --targetbus scsi
#virsh attach-disk fastvm-gentoo210905o-69 /dev/vg_raid5/data69 sdb --config --targetbus scsi
virsh attach-disk fastvm-u1804.4-70 /dev/vg_raid5/data70 sdb --config --targetbus scsi
virsh attach-disk fastvm-u2004.0-71 /dev/vg_raid5/data71 sdb --config --targetbus scsi
virsh attach-disk fastvm-rhel-7.9-72 /dev/vg_raid5/data72 sdb --config --targetbus scsi
virsh attach-disk fastvm-rhel-8.5-73 /dev/vg_raid5/data73 sdb --config --targetbus scsi
~~~

### 2. Running basic fast-vm deploy with `ondrejhome.fast-vm-server` ansible role
- download `ondrejhome.fast-vm-server` role form ansible galaxy (version `15.0.0` or newer)
~~~
# ansible-galaxy install -p roles ondrejhome.fast-vm-server
Starting galaxy role install process
- downloading role 'fast-vm-server', owned by ondrejhome
- downloading role from https://github.com/OndrejHome/ansible.fast-vm-server/archive/15.0.0.tar.gz
- extracting ondrejhome.fast-vm-server to .../roles/ondrejhome.fast-vm-server
- ondrejhome.fast-vm-server (15.0.0) was installed successfully
~~~
- start all VMs and distribute the SSH key for access
~~~
# fast-vm start '61 62 63 64 65 66 67 70 71 72 73'
# fast-vm keydist '61 62 63 64 65 66 67 70 71 72 73'
~~~
- deploy basic fast-vm on all VMs
~~~
# ansible-playbook -i ansible_hosts 01_setup_fast-vm.yaml
~~~

### 3. Runnig tests
At this moment any functional tests can be run to verify that fast-vm functions properly.

### 9. Cleanup
- thinpool disks wiping from hypervisor
~~~
for i in {61..73}; do blkdiscard -f /dev/vg_raid5/data$i; done
~~~
- delete all VMs
~~~
# fast-vm delete '61 62 63 64 65 66 67 70 71 72 73'
~~~
