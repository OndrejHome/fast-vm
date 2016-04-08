Name:		fast-vm
Version:	0.5
Release:	1%{?dist}
Summary:	Script for defining VMs from images provided in thin LVM pool

License:	GPLv3+
URL:		https://github.com/OndrejHome/%{name}/
Source0:	https://github.com/OndrejHome/%{name}/archive/%{version}.tar.gz

BuildArch:	noarch
BuildRequires:	coreutils
BuildRequires:	bash-completion
Requires:	bash
Requires:	libvirt-client
Requires:	libvirt-daemon
Requires:	lvm2
Requires:	sudo
Requires:	qemu-kvm
Recommends:	bash-completion
Recommends:	curl
Recommends:	dnsmasq-utils
Recommends:	pv
Suggests:	libguestfs-tools-c

%description
%{name} is taking care of:
- defining the VMs from provided XML in libvirt
- creating thin LV thin snaphost as storage devices for VMs
- making static IP DHCP reservation in libvirt network definition for MAC address of VM

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
%{_datadir}/bash-completion/completions/%{name}
%{_sysconfdir}/sudoers.d/%{name}-sudoers
%{_mandir}/man5/%{name}.conf*
%{_mandir}/man8/%{name}*
%{_mandir}/man8/configure-%{name}*

%changelog
* Fri Apr 08 2016 Ondrej Famera <ofamera@redhat.com> 0.5-1
- Initial release
