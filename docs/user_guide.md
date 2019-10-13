---
permalink: /fast-vm/user_guide.html
title: fast-vm User Guide
layout: post
date: 2019-10-13 12:09:00+0900
categories: [ fast-vm ]
---
* TOC
{:toc}

---

- This is User Guide for `fast-vm` version 1.6.
- Did you find a mistake/inaccuracy/missing information and you think you
know how to fix it or expand it? Then [edit this page on Github](https://github.com/OndrejHome/fast-vm/edit/master/docs/user_guide.txt) and once reviewed by author it will appear here.
- Found a mistake but don't know how to fix it or you would like to request some part to be documented in this guide? Please get in touch with [the Author](https://www.famera.cz/blog/about.html).
- While `fast-vm` allows most of operations to be run as normal user this guide uses the `#` symbol to indicate commands that can be run and doesn't necessarily require super user. This is for convenience when making copy&amp;paste of commands to terminal which leads to command being copied and not executed as `#` comments it out.

## 1. What is `fast-vm`? {#what_is_fast-vm}
`fast-vm` is a script that provides command-line interface to create virtual machines (VMs) in libvirt based on imported disks in LVM and XML templates.

### 1.1. System requirements for running `fast-vm` {#system_requirements}
`fast-vm` needs several things for proper operation, the minimum is:

- running and functional libvirt daemon (pulled in as dependency from `fast-vm` RPM packages)
- user with access to libvirt (root or normal user with unrestricted read-write access to libvirt)
- some templates to start with (you can also create your own, check the section [Creating custom images](#creating_custom_images))
- LVM tools with thinpool capabilities (most of todays distributions has this)
- some space on LVM for `fast-vm` data (you can create also LVM on top of loopback device if you are out of space, check ADVANCED USAGE part)

### 1.2. How `fast-vm` works {#how_fast-vm_works}
Once configured, `fast-vm` stores the templates of VM disk drives (**"images"**) in LVM thinpool LV for space efficiency. Templates for VMs (**"libvirt XML"**) are just libvirt XMLs with few macros from `fast-vm` (full listing in man page).

When `fast-vm` is requested to create a VM, it will:

1. create new writable LVM snapshot of disk drive
2. define libvirt VM for it (taking the libvirt XML, replacing macros and defining the VM using `virsh define`)
3. make a static DHCP reservation for libvirt network on which VM will be. (so you can have predictable IPv4 address of the VM)
4. (optionally) after VM was defined in libvirt and all other tasks were done it can run so called 'hack file' that customize the image of VM further (one of use cases is to run guestfish tools to alter needed files on VM disk drive to achieve additional level of customization)

When `fast-vm` is requested to delete a VM, it will:

1. stop the VM forcefully if it is running
2. remove static DHCP reservation from libvirt and send dhcp_release request when `dnsmasq-tools` are present.
3. remove the writable snaphot of machine
4. (optionally) before undefining the VM from libvirt the so called 'delete hack file' can be run to do cleanup which can be a counter part to 'hack file' from VM creation time
5. undefine the VM from libvirt

### 1.3. What is `fast-vm server`? {#what_is_fast-vm_server}
From version 1.0, `fast-vm` provides feature that helps to identify which user on system created the VM. This allows for basic prevention of accidental removal of VMs by other users and enables the use in multi-user environment.
`fast-vm server` in this document refers to any machine running `fast-vm` accessible by normal users that are in group allowed to use `fast-vm`. While the `fast-vm` can be used by individual it is often also used to provide access to multiple user so they can collaborativelly access the VMs.

**SECURITY NOTE:** Typical installation of `fast-vm` suggest giving users full read/write access to libvirt daemon and several commands using 'sudo'. Check the chapter [Security information](#security_information) of this document to see why the `fast-vm` needs such access and feel free to further restrict actions you find appropriate.

### 1.4. Use cases for `fast-vm` {#fast-vm_use_cases}
Suitable use cases:

- "scratch machines" - machines that you use for few things and then you throw them away
- automated deployment testing - as the `fast-vm` is easy to script and can wait until machine is up and running SSH this makes it great to use it for testing scripts for automation (ansible, puppet, etc.)
- playing with clusters or system requiring many similar machines - the way `fast-vm` operates allows to provision quickly a lot of machines that are both independent and yet quite similar
- ...

Not very suitable use cases:
- secure systems - `fast-vm` is trying to allow many users to access shared pool of images and VMs - this is going against preventing any users from access drives of other machines. By design it might not be easy or possible to guarantee the usage of `fast-vm` in environment where users must be strictly separated.

### 1.5. Concepts: Images, VM_number and VMs {#concepts_images_vm_numbers_and_vms}
Fast-vm is trying to simplify work with pre-prepared virtual machines and therefore most of the time you will already use machine that has some system installed on it. What system will be pre-installed on VM is determined by **Image** from which the VM was created. Images are usually named the way that it is easy to guess what system they contain (for example image name 'r73' will most probably contain RHEL 7.3 system).

To identify the VMs, `fast-vm` uses **VM_number** as the name of your virtual machine. Number from range 20 to 220 (currently). So you don't need to remember how have you named your VM you just need to remember the VM_number which is used with all VM operations to identify your VM.

Note: You can add notes/descriptions to VMs if you desire to have something like name (check `fast-vm edit_note` command).

## 2. Where to download and how to install `fast-vm` {#installation_updates_unistallation}
Currently there are several methods for installation that are described below. If you are interested into making package for your distribution check out with [the Author](https://www.famera.cz/blog/about.html).

Useful links for `fast-vm` project:

- Source codes cat be found at [GitHub](https://github.com/OndrejHome/fast-vm)
- RPM packages are in [GitHub Release](https://github.com/OndrejHome/fast-vm/releases)
- Bugs/RFEs can be reported at [GitHub issues](https://github.com/OndrejHome/fast-vm/issues)

### 2.1. Installation from package (RPM, DEB) {#installation_from_package}
This type of installation is supported on latest releases of CentOS/RHEL/Fedora and Debian. Below are examples on how to install the current release on these distribution.

From `fast-vm` version 1.5 the CentOS/RHEL/Fedora also provides RPM package `fast-vm-minimal` with less dependencies. From that time by default the `fast-vm` package will pull in also the dependencies needed for some VM images and other useful packages to simplify the installation.

**Fedora 29**
~~~
# curl -o /etc/yum.repos.d/fast-vm.repo https://copr.fedorainfracloud.org/coprs/ondrejhome/fast-vm/repo/fedora-29/ondrejhome-fast-vm-fedora-29.repo
# dnf install fast-vm
~~~

**Fedora 30**
~~~
# curl -o /etc/yum.repos.d/fast-vm.repo https://copr.fedorainfracloud.org/coprs/ondrejhome/fast-vm/repo/fedora-30/ondrejhome-fast-vm-fedora-30.repo
# dnf install fast-vm
~~~

**CentOS 7.7**
~~~
# curl -o /etc/yum.repos.d/fast-vm.repo https://copr.fedorainfracloud.org/coprs/ondrejhome/fast-vm/repo/epel-7/ondrejhome-fast-vm-epel-7.repo
# yum install fast-vm
~~~

**CentOS 8.0**
~~~
# curl -o /etc/yum.repos.d/fast-vm.repo https://copr.fedorainfracloud.org/coprs/ondrejhome/fast-vm/repo/epel-8/ondrejhome-fast-vm-epel-8.repo
# dnf install fast-vm
~~~

**RHEL 7.7**

On RHEL system some of dependencies are present only in `rhel-7-server-optional-rpms` repository that needs to be activated before `fast-vm` installation.
~~~
# subscription-manager repos --enable=rhel-7-server-optional-rpms
# curl -o /etc/yum.repos.d/fast-vm.repo https://copr.fedorainfracloud.org/coprs/ondrejhome/fast-vm/repo/epel-7/ondrejhome-fast-vm-epel-7.repo
# yum install fast-vm
~~~

**RHEL 8.0**
~~~
# curl -o /etc/yum.repos.d/fast-vm.repo https://copr.fedorainfracloud.org/coprs/ondrejhome/fast-vm/repo/epel-8/ondrejhome-fast-vm-epel-8.repo
# dnf install fast-vm
~~~

**Debian 9.11/10.1**

If you plan using publically available images from Author then also `libguestfs-tools` package is required for correct application of creation scripts and their proper functionality.
~~~
# apt-get install gdebi-core
# wget https://github.com/OndrejHome/fast-vm/releases/download/1.6/fast-vm_1.6_all-debian10.deb
# gdebi fast-vm_1.6_all-debian10.deb
# apt-get install libguestfs-tools zstd
~~~

### 2.2. Manual installation from source code {#installation_manual}
On system that doesn't use RPM you can install `fast-vm` using traditional Makefile that is available in the Git repository. To install use command below.
~~~
# make install
~~~

### 2.3. Updating `fast-vm` {#updates}
Always check the notes in [GitHub Release](https://github.com/OndrejHome/fast-vm/releases) before updating to see if there were any changes requiring additional steps after update.

When using repository in Fedora/CentOS/RHEL just use the update command as show below.

~~~
# dnf update fast-vm
# yum update fast-vm
~~~

There is currently no update support for fast-vm on Debian systems.

### 2.4. Uninstalling `fast-vm` {#uninstall}
If you don't like `fast-vm` please consider leaving me a feedback on what you don't like or what could get improved so you can use it.

If you have installed `fast-vm` from RPM then just uninstall the package.

~~~
# dnf remove fast-vm fast-vm-minimal
# yum remove fast-vm fast-vm-minimal
# apt-get remove fast-vm
~~~

If you have used manual installation there is currently no automated way of unistalling but in general it is enough to check the `Makefile`and remove all files it creates in system. Additionally you can remove the directories `/etc/fast-vm/`, `$HOME/.fast-vm/`. Since version 1.4 the notes for fast-vm are not stored anymore in separate files and they are part of the description of VM in libvirt.

### 2.5. Configuring `fast-vm` {#configuring_fast-vm}
After initial installation or update of `fast-vm` it is highly recommended to run command below to perform configuration with validation.
~~~
# configure-fast-vm
~~~
**Important:** `configure-fast-vm` must be run as `root` user.

Script will create and validate configuration file `/etc/fast-vm.conf`. Further it will allow during initial configuration the creation of storage for `fast-vm` and libvirt network that will provide networking to VMs.

#### 2.5.1. `configure-fast-vm` walkthrough with examples {#configure-fast-vm-example}

a) Start configuration script.
~~~
[root@mypc ~]# configure-fast-vm
[inf] ==>> fast-vm configuration script
You can run this script repeatedly and interrupt it with ctrl+c.
Script will always recheck all configuration options. fast-vm system configuration will be saved in /etc/fast-vm.conf.
~~~

b) Enter on which VG the fast-vm will have thinpool LV as storage.
~~~
[?] VG for LVM thin pool
 fast-vm is using LVM thin LV to store VM images and data.
 On which existing VG should be this thin LV?
[]: f30
~~~

c) Provide name of thinpool LV. If thinpool LV doesn't exist script will create for you later.
~~~
[?] LVM thin pool name
 Name the thin LV on which data would be stored.
 NOTE: This can be both 'name of existing thinpool LV' or 'name for a new one'.
 If LV with this name doesn't exists, it will get created by this setup.
[fastvm-pool]:
~~~

d) (only when thinpool LV doesn't exit) Enter size for thinpool LV that will be created.
~~~
[?] LVM thin pool size
 You can use units understood by LVM like M,G,T.
 NOTE: This applies only when thin LV doesn't exists yet.
[50G]: 20G
~~~

e) Enter prefix that will be used for VMs created in libvirt.
~~~
[?] VM name prefix in libvirt
 Prefix is used in VM names and VM drive names.
[fastvm-]:
~~~

f) Enter system group name that will be allowed to use fast-vm. Only one group is allowed.
~~~
[?] Users that want to use fast-vm must be members of following group.
 WARNING: if this group is different from 'libivrt' you would have to adjust libvirt configuration.
 Please check the fast-vm.conf(5) if setting this to something else than 'libvirt'.
[libvirt]:
~~~

g) Enter name of libvirt network that will be used by fast-vm. If network doesn't exist the configurator will create it later.
~~~
[?] Libvirt network (bridge) name
 This configuration will create a libvirt
 network with this name providing NAT for VMs.
[fastvm-nat]:
~~~

h) Choose the subnet number that will be used by fast-vm to allocate IP addresses.
~~~
[?] Libvirt subnet number (192.168.XX.0/24)
[22]: 23
~~~

i) Decide if fast-vm should prevent delete of machines created by other users.
~~~
[?] Only 'root' and 'owner' of VM should be able to delete VM through fast-vm?
 "yes" - only 'root' and 'owner' can delete VM
 "no" - anyone allowed to use fast-vm can delete VM (default in versions =< 0.9)
[no]:
~~~

j) (only if thinpool LV didn't existed) Configurator will ask if you wanna create the thinpool LV.
~~~
[wrn] LV 'f30/fastvm-pool' not found
Following commands would be executed to create thin pool:
  lvcreate -n fastvm-pool -L 20G f30
  lvconvert --type thin-pool f30/fastvm-pool
[?] Create now? (y/n) y
[inf] Creating ...
  Logical volume "fastvm-pool" created.
  WARNING: Converting logical volume f30/fastvm-pool to thin pool's data volume with metadata wiping.
  THIS WILL DESTROY CONTENT OF LOGICAL VOLUME (filesystem etc.)
Do you really want to convert f30/fastvm-pool? [y/n]: y
  Converted f30/fastvm-pool to thin pool.
[ok] LVM thinpool successfuly created
~~~

k) (only if libvirt network didn't existed) Configurator will ask if to create libvirt network for fast-vm.
~~~
[?] Network fastvm-nat is not defined in libvirt, define now? (y/n) y
[inf] Creating ...
Network fastvm-nat defined from /tmp/tmp.MBoYPmWE2g.xml

Network fastvm-nat marked as autostarted

Network fastvm-nat started

[inf] fast-vm libvirt network created and autostarted
~~~

l) End of configuration
~~~
[ok] fast-vm configured
~~~

#### 2.5.2. (optional) Configure LVM filters {#configure_lvm_filters}
Optional but recommended is to filter out detection of LVM on the VG that holds the thinpool LV for fast-vm. For example if you use VG `f30` then following entries can be add into LVM `filter =`.

~~~
"r|/dev/f30/.*|"
"r|/dev/mapper/f30-.*|"
~~~

Example of incorporating the above filter into `/etc/lvm/lvm.conf`.
~~~
...
devices {
   ...
   filter = [ "r|/dev/f30/.*|", "r|/dev/mapper/f30-.*|", "a|.*|" ]
   ...
}
...
~~~
NOTE: Final filter configuration depends heavilly on your environment/system.

### 2.6. UEFI boot support with OVMF {#ovmf_uefi_support}
To use libvirt with UEFI boot a special firmware is required. fast-vm` doesn't require any special configuration for UEFI boot except of having needed firmware and image that was pre-installed with UEFI support. More on how to install UEFI firmware into libvirt check [Fedora: Using UEFI with QEMU](https://fedoraproject.org/wiki/Using_UEFI_with_QEMU) article.

To use images provided by the Author with UEFI on Fedora following steps needs to be taken.

1a. (Fedora 24+) Install package `edk2-ovmf` containing firmware files.
~~~
# dnf install edk2-ovmf
~~~

1b. (CentOS/RHEL 7) Download the `edk2.git-ovmf-x64-xxxxx.noarch.rpm` from [OVMF generated RPMs](https://www.kraxel.org/repos/jenkins/edk2/) and install it manualy using `yum`.

1c. (RHEL 8) While RHEL8 has package `edk2-ovmf` containing firmware files. This package at the moment provide only secure-boot version of firmware requiring different VM machine type (q35). To support images before q35 machines download the `edk2.git-ovmf-x64-xxxxx.noarch.rpm` from [OVMF generated RPMs](https://www.kraxel.org/repos/jenkins/edk2/) and install it manualy using `yum`. Check [GitHub Issue 48](https://github.com/OndrejHome/fast-vm/issues/48) for more details.

1d. (Debian) Install package `ovmf` containing firmware files.
~~~
# apt-get install ovmf
~~~

2\. Ensure that `/etc/libvirt/qemu.conf` contains following variable with value below. On Fedora 30, CentOS 7.6 this is already present in default comment and does not need changing.
~~~
nvram = [
   "/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd"
      ]
~~~

3a. (Fedora 30) Ensure that variable from previous steps is pointing to correct firmware files. With default installation on Fedora no additional commands are needed.
~~~
# ls -l /usr/share/OVMF/OVMF_{CODE,VARS}.fd
lrwxrwxrwx. 1 root root /usr/share/OVMF/OVMF_CODE.fd -> ../edk2/ovmf/OVMF_CODE.fd
lrwxrwxrwx. 1 root root /usr/share/OVMF/OVMF_VARS.fd -> ../edk2/ovmf/OVMF_VARS.fd
~~~

3b. (CentOS/RHEL 7) Ensure that variable from previous steps is pointing to correct firmware files. When using package from [OVMF generated RPMs](https://www.kraxel.org/repos/jenkins/edk2/). the following additional commands are needed.
~~~
# mkdir /usr/share/OVMF  # as this directory is usually not present on system
# ln -s /usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd /usr/share/OVMF/OVMF_CODE.fd
# ln -s /usr/share/edk2.git/ovmf-x64/OVMF_VARS-pure-efi.fd /usr/share/OVMF/OVMF_VARS.fd
~~~

3c. (RHEL 8) Adjust links in `/usr/share/OVMF/` with commands below. Note that steps will need to be repeated when the `edk2-ovmf` package is updated or reinstalled.
~~~
# rm /usr/share/OVMF/OVMF_VARS.fd
# ln -s /usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd /usr/share/OVMF/OVMF_CODE.fd
# ln -s /usr/share/edk2.git/ovmf-x64/OVMF_VARS-pure-efi.fd /usr/share/OVMF/OVMF_VARS.fd
# ls -l /usr/share/OVMF/OVMF_{CODE,VARS}.fd
lrwxrwxrwx. 1 root root /usr/share/OVMF/OVMF_CODE.fd -> /usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd
lrwxrwxrwx. 1 root root /usr/share/OVMF/OVMF_VARS.fd -> /usr/share/edk2.git/ovmf-x64/OVMF_VARS-pure-efi.fd
~~~

3d. (Debian) Ensure that variable from previous steps is pointing to correct firmware files. With default installation on Debian no additional commands are needed.
~~~
# ls -l /usr/share/OVMF/
-rw-r--r-- 1 root root 1966080 Mar 18 21:12 OVMF_CODE.fd
-rw-r--r-- 1 root root  131072 Mar 18 21:12 OVMF_VARS.fd
~~~

## 3. Basic operations in `fast-vm` {#basic_operations}

### 3.1. Accessing the VMs {#accessing_vm}
There are 3 ways discussed in this guide on how to access your VM created by `fast-vm`. In most cases you will need to know password of some user on VM to which you are connecting. To find which user and password to used with such VMs check with provider of **Image**. Author of `fast-vm` uses most commonly user 'root' with password 'testtest' in images that he provides, however it doesn't apply to all systems so check carefully with provider of Image to know how to access the VMs. This guide will assume the use of account 'root' with password 'testtest' as account information for VMs.

#### 3.1.1. Accessing VMs using SSH or other remote connection protocols running on VM {#accessing_vm_using_ssh_or_remote_connection}
Each VM will be assigned IP address by DHCP from local subnet that ends with VM_number. For example if your VM_number is `42` and the subnet used by `fast-vm` is `192.168.11.0/24`, then your VM will be assigned address `192.168.11.42` by DHCP. To figure out which address is assigned to your VM you can also use command below to print the IP of your VM.
~~~
# fast-vm info <VM_number>
~~~
If you would like to login using SSH as root to your VM you can use shortcut command below.
~~~
# fast-vm ssh <VM_number> 
~~~
This command provides following advantages over normal SSH connection:

- Waits for SSH on your VM to become available and probe for availability every second. Once SSH is ready then connect (this is equivalent of trying `ssh root@>your_machine_ip<` manually until you succeed).
- Ignore any SSH keys stored in 'known_hosts' file - especially useful if you re-use same VM_number and you don't want to be bothered with updating 'known_hosts' file.`fast-vm` bypasses saving of the SSH key into 'known_hosts' file.

#### 3.1.2. Accessing VMs using serial console {#accesing_vm_using_serial_console}
Most of images provided by Author for `fast-vm` are pre-configured to provide serial console access. This allows you to connect via virtual serial port to text console of your VM. This is useful when VM network is not working and provides you also with access to GRUB boot menu. Compared with graphical console access discussed in next section you have ability to copy and paste text easily from serial console.

To access serial console of machine use command below
~~~
# fast-vm console <VM_number>
~~~
To get out of serial console of machine use escape sequence `ctrl + ]`('ctrl' key and 'right squared bracket' key)

#### 3.1.3. Accessing VMs using graphical console (Spice/VNC) {#accessing_vm_using_graphical_console}
Depending on Image this access might not be configured (for example headless systems with serial console only provided by Author). There is no dedicated command to launch connection to VM using graphical console.

The simplest way on how to get access to graphical console even when the `fast-vm server` is the remote system is to use GUI `virt-manager` which has integrated access to graphical console.

### 3.2. Creating VMs {#creating_vm}
To create VM you need to know 2 things:
<ul>
<li>name of image or profile you want to use</li>
<li>know one VM_number on `fast-vm server` that is not in use</li>
</ul>

To list available images and profiles you can use commands below
~~~
# fast-vm list_images
# fast-vm list_profiles
~~~
To list VM_numbers that are already in use you can use the command below
~~~
# fast-vm list
~~~
Once you have needed information the creation of VM is done using command below
~~~
# fast-vm create <image_name or profile_name> <VM_number>
~~~
**TIP:** To make things easier the `fast-vm` provides bash command completion for both image/profile names and list of free VM_numbers. (just use TAB key to show possible options). Bash completion will also show 'only the free VM_numbers' when creating VM.

### 3.3. Starting and stopping VMs {#starting_vm}
Once VM exists you can start it using command below.
~~~
# fast-vm start <VM_number>
~~~
To forcefully stop VM you can use command below.
~~~
# fast-vm stop <VM_number>
~~~
To gracefully stop your VM you can add word 'graceful' to the end of stop command like below. This will send ACPI shutdown signal to VM instead of forcefully killing it. If OS can recognize this ACPI singal it will initiate appropriate action (usually grafeul shutdown of system).
~~~
# fast-vm stop <VM_number> graceful
~~~

### 3.4. Deleting VMs {#deleting_vm}
If you don't need the VM any more then you can delete it using command below.
~~~
# fast-vm delete <VM_number>
~~~
**WARNING:** You will NOT be prompted to confirm the VM deletion. VM can be deleted anytime - regardless if it is running or not.

By default `fast-vm` will prevent you from deleting VMs that created byt another users (does not apply to situation when running as root). For more information check the option FASTVM_OWNER_ONLY_DELETE in man page.

### 3.5. Listing VMs on `fast-vm server` {#listing_vms}
To list the VMs on `fast-vm server` created by you and other users use command below.
~~~
# fast-vm list
~~~
This command will show list or VMs ordered by VM_number along with **Image name** from which the VMs were created, current VM **status** (running/stopped), **Profile name** using which was VM created if any,**Size** of VM primary disk and spaced used by it on LVM storage, last time that there was **Activity** with this VM using the `fast-vm` commands and VM **Notes** containing the name of owner who created the VM and any additional notes for given VM.

Example `fast-vm list` output
~~~
VM# Image name      Status       Profile_name    Size( %used )  Activity  Notes
 21 centos-7.6      shut off     ---               6g( 24.78%)    3d ago  ondrej: CentOS 7.6 minimal
 22 centos-7.6      shut off     centos-g-7.6      6g( 27.22%)   12d ago  ondrej: CentOS 7.6 with graphical console
 23 fedora30        running      ---               6g( 18.63%)    0d ago  root: some other running machine with Fedora 30
~~~

### 3.6. Creating and editing VM notes {#editing_vm_notes}
Sometimes VM_numbers might not be enough to contain enough information to identify the VM therefore you can assign your VM a note using command below
~~~
# fast-vm edit_note <VM_number> "your_note_as_single_parameter"
~~~
This note will be shown in listing of VMs and also it will be included in the libvirt 'visible name' so some clients such as 'virt-manager' can show it to help you to identify your VM.

### 3.7. Importing images into `fast-vm` {#importing_images}
The main thing in `fast-vm` are **Images** which provides the templates upon which we create new VMs. It is possible to create you own Image or you can import some premade ones. Below is link for some images pre-made by Author.

[Public `fast-vm` images created by the Author](https://www.famera.cz/blog/fast-vm/about.html)

To import simple image into `fast-vm` you can use command below.
~~~
# fast-vm import_image <Image_name> <path_or_URL_to_Image_file> <path_or_URL_to_libvirt_XML>
~~~
Images can be optionally imported with additional 2 parameter specifying the scripts that should be run when the VM is created and deleted. (Images provided by Author uses only  scripts during VM creation to provide access to serial console and some minimal customization such as hostname and networking setup)

Example of importing image of CentOS 7.6 with script used during VM creation from Authors site.
~~~
# fast-vm import_image centos-7.6 http://ftp.linux.cz/pub/linux/people/ondrej_famera/fastvm-images/generated/6g__centos-7.6.img.xz https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/centos/xml/centos-6.3-current.xml https://raw.githubusercontent.com/OndrejHome/fast-vm-public-images/master/centos/hacks/6g_centos-7-hacks.sh
~~~

### 3.8. Importing and using Profiles {#importing_and_using_profiles}
**Profiles** in `fast-vm` are used to provide templates with same Image file as existing Images but with different set of libvirt XML, creation/deletion scripts. This is useful when you have for example several HW configurations for same system that you would like to use so you don't have to import the same Image twice (meaning taking up disk space twice).

To import a profile you can use command below.
~~~
# fast-vm import_profile <ProfileName> <ImageName> <PathToLibvirtXML> <PathToHacksFile> <PathToDeleteHackFile>
~~~
Last two parameters are optional the same way as when importing the Image.

### 3.9. Resizing the disks of VMs and Images (from `fast-vm-1.2`) {#resizing_disks_of_vms_and_images}
In case you want to change the size of disks in either Image or existing VM you can use one of the following commands to do so:

Resizing the disk of `fast-vm` VM to new value
~~~
# fast-vm resize <VM_number> <New_disk_size_in_GB>
~~~
Resizing the disk of `fast-vm` imported Image.
~~~
# fast-vm resize_image <Image_name> <New_Image_disk_size_in_GB>
~~~

**WARNING:** `fast-vm` will resize the disk regardless of the position of data on it which means that you can loose data if they are not within new disk size.

If the Image disk size is changed the VMs newly created from it will have this new size. Old VMs will be unaffected by the Image disk size change.

## 4. Advanced operations {#advanced_operation}
This part of guide covers some advanced use cases for `fast-vm`. Note that this is not exhaustive list of all possibilities and in general as long as you don't change the naming of VMs you can editing anything that libvirt allows to customize your VMs.

### 4.1. Using virt-manager to manage and access `fast-vm` VMs {#using_virt-manager}
GUI application 'virt-manager' can be used to connect to `fast-vm server`,access VMs and edit them. Further `virt-manager` allows you to access serial and graphical console of VMs, create custom networks, change VM hardware and much more.

When `fast-vm server` is the same as machine from which you want to connect there is no special configuration needed in most of cases. If you cannot see the VMs created by `fast-vm` then check if you are connecting to local libvirt URI `qemu:///system`.

When `fast-vm server` is remote machine then ensure you have a SSH access to user on that machine that can use `fast-vm`. Once you have this one then you can create connection to this server in `virt-manager` following way.

1. From top menu select `File -> Add Connection ...`
2. In window that opens use following values:
  - **Hypervisor:** `QEMU/KVM`
  - check the checkbox **Connect to remote host**
  - **Method:** `SSH`
  - **Username:** `<your SSH user for remote server>`
  - **Hostname:** `< password for this SSH user>`
  - (optionaly) check the checkbox **Autoconnect**
3. Click on **Connect** button
4. Access VMs same way as with normal `virt-manager`

**WARNING:** By default access via 'virt-manager' is unrestricted and you may use nearly any feature of libvirt provided on `fast-vm server`. This is provided for flexibility but doing intentionally bad changes can impact the whole `fast-vm server` so think before making any changes.

Other features and limitations using `virt-manager`

- `virt-manager` doesn't provide ability to create VMs same way as `fast-vm` does.
- VM names are shown in format `<VM_number> <VM note containing VM owner>`
- When upgrading from older version of fast-vm some VMs might not have populated the names correctly which can be fixed by assigning them notes from `fast-vm`
- VM visible names are not propagated to `fast-vm server` and are always overwritten by `fast-vm edit_note` command.
- From version 1.4 `fast-vm` stores metadata in the **description** field provided by libvirt in the VM. If this data are inconsistent the `fast-vm` will replace them and make VM owner to be 'root'.

### 4.2. Using `virsh` to access and manage `fast-vm` VMs {#using_virsh}
To use `virsh` with fast-vm you would have to specify a special connection string to let know it where the `fast-vm server` is.

For local `fast-vm server` you can use the command below
~~~
# virsh --connect qemu:///system <virsh_command>
~~~
For remote `fast-vm server` you can use the command below
~~~
# virsh --connect qemu+ssh://user@remote_system/system <virsh_command>
~~~
Same limitation as for `virt-manager` applies here.

### 4.3. Creating custom Images for `fast-vm` {#creating_custom_images}
`fast-vm` is made the way that it provides support for creating your own Images for use and sharing with others and aims at making this one of its main features. Before `fast-vm-1.2` it was possible to create only Images with disk size of 10GB. From `fast-vm-1.2` you are able to specify custom size of Image in GB and to resize any existing Image.

The process of creating custom Image can be summarized into following steps which are described more in detail in man page (`man fast-vm`) section 'CREATING CUSTOM IMAGES'.

1. Creating libvirt XML for future VMs
2. Importing empty image and giving it name to start with.
3. Creating base VM that can be used for accessing directly the empty Image.
4. Export of Image into archive for sharing.
5. (optional) Creation of scripts that are run on VM creation/deletion.

## 5. Detailed `fast-vm` architecture {#architecture}
Below you will find some more technical aspects of fast-vm that are aimed at providing information for those who would like to interact with `fast-vm` on low level or tighten up its security aspects. Author believes that for example access to libvirt could be configured using rules from policykit and would gladly accept any contribution in this area if someone is interested.

### 5.1. Security information {#security_information}
`fast-vm` is using following commands from virsh (libvirt):

- list - listing the VMs under `fast-vm` control
- destroy - forcefully shutdown VMs
- shutdown - gracefully shutdown VMs
- start - start VMs
- console - provide access to serial console of VMs
- define, dumpxml - define new VMs and get their basic data
- net-update - create static DHCP leases for VMs\
- desc - update VM notes in libvirt definition
- undefine - delete VMs
- net-info, net-define, net-autostart, net-start, net-dumpxml - used by `configure-fast-vm` script for initial configuration, not needed during normal operations

Further following actions requires giving user the root priviliges using sudo. All of these privileges are checked within scripts to match the configuration so the access is limited to `fast-vm` things only.

- lvcreate - creation of LVs for Images and VM disks
- lvremove - removal of LVs for Images and VM disk
- chgrp - allow access to LVs created by `fast-vm` to group of users so they can modify it without root privileges
- dhcp_release - sending DHCP release packet to libvirt so the static DHCP lease can be cleared once the VM is undefined
- lvs - get information about disk sizes and utilization
- lvresize - resize of LVs for Images and VM disks

## 6. fast-vm-server documentation {#fast-vm-server_documentation}
This part of documentation describes best practices on how to use `fast-vm` in mutli user environment and how to deploy `fast-vm` in automated and scalable way.

### 6.1. `fast-vm-server`: automated `fast-vm` deployment overview {#fast-vm-server_automated_fast-vm_deployment_overview}
[`fast-vm-server` ansible role](https://galaxy.ansible.com/OndrejHome/fast-vm-server/) provides a solution how to deploy `fast-vm` in automated (unattended) way and also how to deploy it on larger amount of machines. This role deals only with following things:

- `fast-vm` installation and configuration
- installation and configuration of additional features that can be used with `fast-vm` such as
  - `fence_virtd` to allow use with High-Availability clusters that needs to be able to reboot VMs for proper operation
  - installation of custom version of `qemu-kvm` and `seabios-bin` that provides support for LSI and MegaRAID SAS controllets that are not available in packages from CentOS/RHEL
  - OVMF UEFI firmware for use with UEFI fast-vm VMs

`fast-vm-server` ansible role doesn't deal with setting up user authentication to system nor for importing the `fast-vm` images into this new system. For importing images there is ongoing work to provide ansible role that will be dealing only with that.

### 6.2. `fast-vm-server` installation example {#fast-vm-server_installation_example}
All possibilities configuration options for the `fast-vm-server` role can be found in the [README](https://github.com/OndrejHome/ansible.fast-vm-server/blob/master/README.md) of the role. By default all features are enables and only minimum of configuration options needs to be changed to get from minimal system to system with functional `fast-vm`. The single options that would need to be customized on most of the systems is **fastvm_vg** VG that will contain `fast-vm` thin LV pool. Rest of options can be left in defaults or tweaked as needed.

Example playbook with default installation containing all features and 50GB thinpool LV placed on VG `my_vg` will look like below. (there must be at least 50GB of free space on `my_vg` VG or the size can be changed using option `fastvm_lv_size`)

Example of `install-fast-vm-server.yml`:

~~~
---
- hosts: servers
  remote_user: root
  roles:
    - { role: 'ondrejhome.fast-vm-server', fastvm_vg: 'my_vg' }
~~~

Example of `fast-vm-server.hosts`:
~~~
[servers]
192.168.XX.XX
~~~

To run the installation with above examples you can use command below:
~~~
# ansible-playbook -i fast-vm-server.hosts install-fast-vm-server.yml
~~~

### 6.3. Using `fast-vm` on systems with SSSD {#using-fast-vm-on-systems-with-sssd}
It is possible to use SSSD for providing centralized users and groups on systems that will run the `fast-vm`. In case that user wants to use the `fast-vm` then it must be part of group that is allowed to use `fast-vm`. In case that this cannot be changed centraly then use the `sss_override` to make a primary group of such (centrally managed) user to be a group allowed to use `fast-vm`. This can be done using the command `sss_override`. Below example shows changing primary group of user 'myuser' (assuming that group allowed to access the `fast-vm` has GID 500):

~~~
# sss_override user-add myuser -g 500
~~~

User will need to re-login and the `sssd` daemon may need to be restarted for this change to take effect.

Adding user to group in local `/etc/group` file may not work properly since `fast-vm-1.3` that uses `sg` command for some operations. This is mitigated in `fast-vm-1.3.1`.

### 6.4. Exposing `fast-vm` systems to external network via bridge {#exposing-fast-vm-systems-to-external-network-via-bridge}
In some situations it may be desirable for `fast-vm` machines to be accessible directly from same network as the hypervisor running them is reachable. This can be achieved by configuring the hypervisor OS (in this example CentOS/RHEL 7) to connect to network via software bridge to which the `fast-vm` can be also attached. Assuming that (`fast-vm`) hypervisor connects now to network via DHCP using using interface `eth0` the commands below will create the new software bridge that will contain only interface `eth0` and will use DHCP to get address. Before attempting commands below make sure that you can access machine via other means if the network configuration fails for any reason. The resulting configuration will be using `system-bridge` software bridge for obtaining IP address and will delete profile with eth0 configuration.

~~~
# nmcli con add type bridge ifname system-bridge con-name system-bridge bridge.stp no
Connection 'system-bridge' (11111111-2222-3333-4444-555555555555) successfully added.
~~~

~~~
# nmcli con add type bridge-slave ifname eth0 master system-bridge
Connection 'bridge-slave-eth0' (66666666-7777-8888-9999-000000000000) successfully added.
~~~

~~~
# nmcli con up system-bridge
Connection successfully activated (master waiting for slaves) (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/XXX)
~~~

~~~
# nmcli con del eth0
Connection 'eth0' (aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee) successfully deleted.
~~~

State of network configuration before and after applying above commands

~~~
## BEFORE
# ip a
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master system-bridge state UP group default qlen 1000
    link/ether 52:54:00:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    inet 192.168.22.xxx/24 brd 192.168.22.255 scope global noprefixroute dynamic eth0
# nmcli con show
NAME  UUID                                  TYPE      DEVICE
eth0  aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee  ethernet  eth0

## AFTER
# ip a
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master system-bridge state UP group default qlen 1000
    link/ether 52:54:00:xx:xx:xx brd ff:ff:ff:ff:ff:ff
3: system-bridge: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 52:54:00:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    inet 192.168.22.xxx/24 brd 192.168.22.255 scope global noprefixroute dynamic system-bridge
# nmcli con show
NAME                  UUID                                  TYPE      DEVICE
system-bridge         11111111-2222-3333-4444-555555555555  bridge    system-bridge
bridge-slave-eth0     66666666-7777-8888-9999-000000000000  ethernet  eth0
~~~

Once the `system-bridge` software bridge is setup and operational you can use interface in the XML definition of the fast-vm` as shown below.
~~~
<domain type='kvm'>
  ...
  <devices>
  ...
    <interface type='bridge'>
      <mac address='52:54:00:be:ef:VM_HEX_NUMBER'/>
      <source bridge='system-bridge'/>
      <model type='virtio'/>
    </interface>
  ...
  </devices>
</domain>
~~~

If you are using the XML files from [fast-vm-public-images GitHub repository](https://github.com/OndrejHome/fast-vm-public-images/) then check out [CentOS README](https://github.com/OndrejHome/fast-vm-public-images/blob/master/centos/README) and [RHEL README](https://github.com/OndrejHome/fast-vm-public-images/blob/master/rhel/README) for more information on how to used pre-made profiles with 2 network card configuration that has one of the network cards connected to `system-bridge` software bridge.
