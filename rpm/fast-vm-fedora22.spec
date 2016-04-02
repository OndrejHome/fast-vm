%global _enable_debug_package 0
%global debug_package %{nil}
%global __os_install_post /usr/lib/rpm/brp-compress %{nil}
Name:	fast-vm	
Version:	0.4
Release:	22%{?dist}
Summary:	 '%{name}' is a script for defining VMs from images provided in thin LVM pool.

Group:		Unspecified
License:	GPLv3
URL:		https://github.com/OndrejHome/%{name}/
Source0:	https://github.com/OndrejHome/%{name}/archive/%{version}.tar.gz

BuildRequires:	bash
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
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}/
cp -p %{name} %{buildroot}%{_bindir}/%{name}
cp -p %{name}-net-cleanup %{buildroot}%{_bindir}/
mkdir -p %{buildroot}%{_sbindir}
cp -p configure-%{name} %{buildroot}%{_sbindir}
mkdir -p %{buildroot}%{_libexecdir}
cp -p %{name}-helper.sh %{buildroot}%{_libexecdir}
mkdir -p %{buildroot}%{_datadir}/%{name}
cp -p %{name}-network.xml %{buildroot}%{_datadir}/%{name}
cp -p config.defaults %{buildroot}%{_datadir}/%{name}/%{name}.conf.defaults
mkdir -p %{buildroot}%{_sysconfdir}/sudoers.d/
cp -p %{name}-sudoers %{buildroot}%{_sysconfdir}/sudoers.d/
mkdir -p %{buildroot}/%{_datadir}/bash-completion/completions
cp -p %{name}.bash_completion %{buildroot}/%{_datadir}/bash-completion/completions/%{name}

%files
%doc README
%license LICENSE
%{_bindir}/*
%{_sbindir}/*
%{_libexecdir}/*
%{_datadir}/%{name}/*
%{_datadir}/bash-completion/completions/%{name}
%{_sysconfdir}/sudoers.d/*

%changelog
