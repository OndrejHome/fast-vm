Name:		fast-vm
Version:	0.9.5
Release:	1%{?dist}
Summary:	Script for defining VMs from images provided in thin LVM pool

License:	GPLv3+
URL:		https://github.com/OndrejHome/%{name}/
Source0:	https://github.com/OndrejHome/%{name}/archive/%{version}.tar.gz

BuildArch:	noarch
BuildRequires:	coreutils
BuildRequires:	bash-completion
Requires:	coreutils
Requires:	gawk
Requires:	libvirt-client
Requires:	libvirt-daemon
Requires:	lvm2
Requires:	ncurses
Requires:	openssh-clients
Requires:	sed
Requires:	sudo
Requires:	qemu-kvm
Requires:	libvirt-daemon-driver-storage
Requires:	libvirt-daemon-driver-lxc
Requires:	libvirt-daemon-driver-qemu

%description
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
%doc README
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
