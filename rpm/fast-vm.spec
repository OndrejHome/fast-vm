Name:		fast-vm
Version:	1.5
Release:	1%{?dist}
Summary:	Script for defining VMs from images provided in thin LVM pool - with extra dependencies

License:	GPLv3+
URL:		https://github.com/OndrejHome/%{name}/
Source0:	https://github.com/OndrejHome/%{name}/archive/%{version}.tar.gz

BuildArch:	noarch
BuildRequires:	coreutils
BuildRequires:	bash-completion
BuildRequires:	make
Requires:	%{name}-minimal
Recommends:	bash-completion
Recommends:	curl
Recommends:	dnsmasq-utils
Recommends:	gzip
Recommends:	pv
Recommends:	xz
Recommends:	libguestfs-tools-c

%description
%{name} provides command-line interface to create virtual machines (VMs) in
libvirt, based on imported disks in LVM and XML templates.

Templates of VM disk drives are stored in LVM thinpool LV for space efficiency.
Templates for VMs are just libvirt XMLs with few macros from %{name}. When
creating a VM, %{name} will create new writable LVM snapshot of disk drive,
define libvirt VM for it and make a static DHCP reservation for libvirt network
on which VM will be. Optionally %{name} allows to do some customization of disk
drive of new machine before starting VM using the 'hack files'.

For package with minimal dependencies check '%{name}-minimal'.

%package minimal
Summary:        Script for defining VMs from images provided in thin LVM pool

Requires:	coreutils
Requires:	gawk
Requires:	libvirt-client
Requires:	libvirt-daemon
Requires:	libxml2
Requires:	lvm2
Requires:	ncurses
Requires:	openssh-clients
Requires:	sed
Requires:	sudo
Requires:	util-linux
Requires:	qemu-kvm
Requires:	libvirt-daemon-driver-storage
Requires:	libvirt-daemon-driver-lxc
Requires:	libvirt-daemon-driver-qemu
Conflicts:	%{name} < 1.5

%description minimal
%{name} provides command-line interface to create virtual machines (VMs) in
libvirt, based on imported disks in LVM and XML templates.

Templates of VM disk drives are stored in LVM thinpool LV for space efficiency.
Templates for VMs are just libvirt XMLs with few macros from %{name}. When
creating a VM, %{name} will create new writable LVM snapshot of disk drive,
define libvirt VM for it and make a static DHCP reservation for libvirt network
on which VM will be. Optionally %{name} allows to do some customization of disk
drive of new machine before starting VM using the 'hack files'.

%prep
%autosetup -n %{name}-%{version}

%install
%make_install

%files
%{nil}

%files minimal
%doc README.md
%license LICENSE
%{_bindir}/%{name}
%{_bindir}/%{name}-net-cleanup
%{_sbindir}/configure-%{name}
%{_libexecdir}/%{name}-helper.sh
%{_datadir}/%{name}/
%{_datadir}/bash-completion/completions
%{_mandir}/man5/%{name}.conf*
%{_mandir}/man8/%{name}*
%{_mandir}/man8/configure-%{name}*
%config(noreplace) %{_sysconfdir}/sudoers.d/%{name}-sudoers

%changelog
* Thu Jul 19 2018 Ondrej Famera <ofamera@redhat.com> 1.5-1
- recursive scp command
- scp with multiple files (@itsbill)
- improved reliability of new metadata storage
- various documentation fixes
- splitted fast-vm into 2 RPM packages for CentOS/RHEL/Fedora

* Tue May 08 2018 Ondrej Famera <ofamera@redhat.com> 1.4-1
- added 'scp' and 'keydist' actions (itsbill)
- move VM metadata into libvirt VMs (deprecated FASTVM_NOTES_DIR)
- fix output from 'fast-vm list' when using non-English locale
- various small fixes in code and documentation (tedwon,nrwahl12)
- removed the use of 'sg'
- IMPORTANT: run 'configure-fast-vm' as 'root' to convert VM metadata

* Sun Dec 24 2017 Ondrej Famera <ofamera@redhat.com> 1.3.1-1
- fix 'sg' handling on systems with sssd

* Sun Nov 19 2017 Ondrej Famera <ofamera@redhat.com> 1.3-1
- operations over multiple VMs
- output change - relevant parts are prefixed with VM number
- activity tracking - time since last action on VM
- video documentation of fast-vm installation, configuration, basic usage
- various fixes and small improvements in code

* Mon Jun 05 2017 Ondrej Famera <ofamera@redhat.com> 1.2.1-1
- fix the size detection for VMs on some systems

* Sun Jun 04 2017 Ondrej Famera <ofamera@redhat.com> 1.2-1
- allow custom sizes of images allow image resizing
- show disk sizes in listings of VMs and images
- allow use of external networks not managed by fast-vm
- improve configure-fast-vm scripts to assist more
- various fixes

* Mon Feb 13 2017 Ondrej Famera <ofamera@redhat.com> 1.1-1
- image profiles support
- delete hack files added
- multi-nic VM removal fix
- store VM notes also in libvirt XML definition for external applications

* Sun Nov 13 2016 Ondrej Famera <ofamera@redhat.com> 1.0-1
- added support for handling machines with UEFI firmware
- improve error messages and documentation
- fix locking and make it dependent on image block device
  (= no need for lock files and shared read lock for images)

* Sun Oct 09 2016 Ondrej Famera <ofamera@redhat.com> 0.9.5-1
- ability to have VM notes (also indicates the owners of VM)
- fix issue with DHCP lease when last VM was deleted
- relaxed the locking of images and VMs in multiuser environments

* Sat Jul 16 2016 Ondrej Famera <ofamera@redhat.com> 0.9-1
- version suitable for use in multiuser environment
- system-wide storage of XML and hack files
- logging via syslog
- configurable group for fast-vm users (previously fixed to 'libvirt' group)

* Tue May 31 2016 Ondrej Famera <ofamera@redhat.com> 0.8-1
- a lot of sanity checks introduced - for example image name restricted to contain only some characters
- import "empty" image and add "export_image" subcommand
- remove the XML definition and hacks file after removing image file

* Wed May 18 2016 Ondrej Famera <ofamera@redhat.com> 0.7.1-1
- fix incorrect check logic for ssh/console commands
- fix wrong awk requirement in RPM

* Wed May 18 2016 Ondrej Famera <ofamera@redhat.com> 0.7-1
- transition from /bin/bash to /bin/sh
- move listing of the VMs from bash completion to fast-vm script
- add list_images function

* Thu May 05 2016 Ondrej Famera <ofamera@redhat.com> 0.6.1-1
- fix the missing double dash in VG names for bash completion script
- change permisions for some of the installed files

* Sun May 01 2016 Ondrej Famera <ofamera@redhat.com> 0.6-4
- support for http(s) links for XML definitions and hack files
- colourful output
- 'stop' action added

* Fri Apr 08 2016 Ondrej Famera <ofamera@redhat.com> 0.5-1
- Initial release
