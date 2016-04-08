%global _enable_debug_package 0
%global debug_package %{nil}
%global __os_install_post /usr/lib/rpm/brp-compress %{nil}
Name:	fast-vm	
Version:	0.5
Release:	1%{?dist}
Summary:	script for defining VMs from images provided in thin LVM pool

License:	GPLv3
URL:		https://github.com/OndrejHome/%{name}/
Source0:	https://github.com/OndrejHome/%{name}/archive/%{version}.tar.gz

BuildArch: 	noarch
BuildRequires:	coreutils
Requires:	lvm2,sudo,pv,curl,bash,bash-completion,dnsmasq-utils,libguestfs-tools-c,libvirt,qemu-kvm

%description
%{name} is taking care of:
- defining the VMs from provided XML in libvirt
- creating thin LV thin snaphost as storage devices for VMs
- making static IP DHCP reservation in libvirt network definition for MAC address of VM

%prep
%autosetup -n %{name}-%{version}

%build

%install
%make_install

%files
%doc README
%license LICENSE
%{_bindir}/*
%{_sbindir}/*
%{_libexecdir}/*
%{_datadir}/%{name}/*
%{_datadir}/bash-completion/completions/%{name}
%{_sysconfdir}/sudoers.d/*
%{_mandir}/*

%changelog
