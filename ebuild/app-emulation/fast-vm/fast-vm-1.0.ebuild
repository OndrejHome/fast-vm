# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit linux-info

DESCRIPTION="Script for defining VMs from images provided in thin LVM pool"
HOMEPAGE="https://www.famera.cz/blog/fast-vm/about.html"
SRC_URI="https://github.com/OndrejHome/fast-vm/archive/1.0.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+hack-file-dependencies +curl +bash-completion"

# built time dependencies
DEPEND=""
# runtime dependencies
RDEPEND="
	app-emulation/libvirt[virt-networks]
	net-dns/dnsmasq[dhcp-tools,script]
	sys-apps/gawk
	sys-apps/coreutils
	app-admin/sudo
	dev-libs/libxml2
	sys-fs/lvm2[thin]
	curl? ( net-misc/curl )
	hack-file-dependencies? ( 
		app-emulation/libguestfs 
		app-emulation/libguestfs-appliance
		app-emulation/libvirt[virt-networks,qemu]
		)
	bash-completion? ( app-shells/bash-completion )
"

src_compile() {
	return
}

pkg_setup() {
	# check if some basic kernel modules not checked elsewhere are needed
	CONFIG_CHECK="
		~DM_SNAPSHOT
		~DM_THIN_PROVISIONING"
	if [[ -n ${CONFIG_CHECK} ]]; then
                linux-info_pkg_setup
        fi
}
