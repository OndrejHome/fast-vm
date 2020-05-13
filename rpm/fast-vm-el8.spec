Name:		fast-vm
Version:	1.6
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
Recommends:	zstd
Recommends:	libguestfs-tools-c
Recommends:	libguestfs-devel

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
Requires:	bc
Requires:	libvirt-daemon-driver-storage
Requires:	libvirt-daemon-driver-qemu
Conflicts:	%{name} < 1.6

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
%{_bindir}/%{name}-image
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
* Wed Oct 09 2019 Ondrej Famera <ondrej-xa2iel8u@famera.cz> 1.6-1
- CentOS/RHEL 8 support
- zst compression support (if installed)
- 'compact' and 'compact_image' commands added
- various fixes and documentation improvements

* Thu Mar 21 2019 Ondrej Famera <ondrej@famera.cz> 1.5-2
- RHEL 8 Beta preview version of fast-vm

* Thu Jul 19 2018 Ondrej Famera <ofamera@redhat.com> 1.5-1
- recursive scp command
- scp with multiple files (@itsbill)
- improved reliability of new metadata storage
- various documentation fixes
- splitted fast-vm into 2 RPM packages for CentOS/RHEL/Fedora
