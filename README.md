---
layout: page
date:   2019-09-14 15:50:11+0900
title: FAST-VM
categories: [ fast-vm ]
---

## FAST-VM

**fast-vm** — script for defining VMs from images provided in thin LVM pool

**fast-vm** provides command-line interface to create virtual machines (VMs) in libvirt,
based on imported disks in LVM and XML templates.

### 5-minute Quick Start {#quickstart}
Check the videos below on how to:
- Install and configure fast-vm (~1 minute) - [https://asciinema.org/a/147355](https://asciinema.org/a/147355)
- Importing images and creating VMs (~1 minute) - [https://asciinema.org/a/143564](https://asciinema.org/a/143564)
- Basic operations in fast-vm (~2 minutes) - [https://asciinema.org/a/143565](https://asciinema.org/a/143565)

### DOCUMENTATION and USER GUIDE {#documentation}
user and installation guide:
  [https://www.famera.cz/blog/fast-vm/user_guide.html](https://www.famera.cz/blog/fast-vm/user_guide.html)

man pages:
- `fast-vm(8)`
- `fast-vm.conf(5)`
- `configure-fast-vm(8)`
- `fast-vm-net-cleanup(8)`
- `fast-vm-list(8)`

Other resource: [https://www.famera.cz/blog/fast-vm/index.html](https://www.famera.cz/blog/fast-vm/index.html)

### Supported/Tested OS {#supported_os}
Distribution    Installation method
- RHEL 7.7	RPM
- RHEL 8.0	RPM
- CentOS 7.7	RPM
- CentOS 8.0	RPM
- Fedora 31	RPM
- Debian 9.11	DEB
- Debian 10.1	DEB
- Gentoo	ebuild

### Requirements {#requirements}
- libvirt with qemu/kvm
- libxml2 (`xmllint`)
- LVM thin pool support
- LVM VG with reasonable amount of free space (to create LV with thin pool)
  - you can use `losetup` to create a loopback device with LVM
- preconfigured VM disk images and XML files (downloadable separately)
- `dhcp_release` for proper DHCP static leases release
- `flock` for image locking (prevent use of not fully imported images)
- (optional) `bash-completion` for bash completion to work
- (optional) `pv` to show import progress
- (optional) `curl` to pass http(s) link for image_import
- (optional) OVMF UEFI image for UEFI support in images

### How to contribute {#contribute}
check [CONTRIBUTING.md](CONTRIBUTING.md)

### License and Support {#license_support}
fast-vm is distributed under GPLv3 (or newer if it exists).
Author will try to supports only the newest release.

### Author {#author}
Ondrej Famera <ondrej-xa2iel8u@famera.cz>

### Known bugs/limitations {#known_bugs_limitations}
- initial setup requires root
- Gentoo might require user to be in group `kvm` to use guestfish from hacks files
- VM images are provided separately
  - publicly available images can be found at [https://github.com/OndrejHome/fast-vm-public-images](https://github.com/OndrejHome/fast-vm-public-images) or for directo download at [https://www.famera.cz/blog/fast-vm/image_list.html](https://www.famera.cz/blog/fast-vm/image_list.html)
- using `dhcp_release` to remove DHCP static reservation is not the cleanest
  way of doing so, but there is no other supported way of doing this through libvirt
  (TODO: make RFE/BUG into libvirt)
- sometimes the VM doesn't get designated IP address because the dnsmasq holds
  the lease for some older MAC address (dhcp_release should be fixing this but
  it's not 100% working solution) - use fast-vm-net-cleanup to fix this issue
- (from fast-vm-1.3) random failures of `virsh list` are not handled. For example if `virsh list` is called
  2 times and second time it fails, then fast-vm doesn't handle that well. Re-running command helps.
  This was observed on my testing machine, but I failed to reproduce behaviour.
  The logs shows following error around time when this happens
    `error : virHashForEach:597 : Hash operation not allowed during iteration`
- (upgrading to 'fast-vm-1.4) because of the VM metadata location change you need to run
  the `configure-fast-vm` as root after upgrade to migrate the metadata to new location

### FAQ {#faq}
**Q:** Why is it using LVM?   
**A:** Because LVM provides very reasonable management of block devices and writable snapshots
with thin provisioning.

**Q:** Why is it not using file-based disk images?   
**A:** It takes much more space.

**Q:** Why not to use file-based disk images with cow (copy-on-write) image?   
**A:** Because if you change the image, the cow images will get corrupted unless you somehow
re-export them. By using LVM this is not a concern as the LVM is keeping track of changes
and will preserve the changes stuff in snaphost so it is safe to edit base image while having
machines that are based on previous version of the base image.

**Q:** Why not to use BTRFS cow?   
**A:** BTRFS is not as widely spread as LVM and it is not clear if it would be able to provide same
functionality as LVM. There is possibility that I will look at this in the future.

**Q:** Are there any similar projects similar to fast-vm?   
**A:** Sure there are, below is a short list of some I run through or I was told about:
- Lago (python) - [https://github.com/lago-project/lago](https://github.com/lago-project/lago)
- upvm (python) - [https://github.com/ryran/upvm](https://github.com/ryran/upvm)
