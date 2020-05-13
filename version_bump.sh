#!/bin/bash
## this script adjusts version in relevant files for fast-vm release
date_deb=$(date "+%a, %d %b %Y %T %z")
date_rpm=$(date "+%a %b %d %Y")
author_name="Ondrej Famera"
author_email="ondrej-xa2iel8u@famera.cz"
version="$1"
## ======================================== ##

# adjust version number
sed -i "s/== fast-vm version.* ==/== fast-vm version ${version} <${author_email}> ==/" fast-vm
sed -i "s/== fast-vm-image version.* ==/== fast-vm-image version ${version} <${author_email}> ==/" fast-vm-image

# adjust man page versions
sed -i "s/ FAST-VM\(.\+\) [0-9.]\+ (/ FAST-VM\1 ${version} (/" man/*

# add changelog entry
debian_changelog=$(cat <<EOF
fast-vm ($version) unstable; urgency=medium

  * version bump to $version

 -- ${author_name} <${author_email}>  ${date_deb}

$(cat debian/changelog)
EOF
)
echo "$debian_changelog" > debian/changelog

# add changelog entry and adjust version
sed -i "/%changelog/a\* ${date_rpm} ${author_name} <${author_email}> ${version}-1\n- version bump to ${version}\n" rpm/fast-vm-*.spec
sed -i "s/^\(Version:\s\+\)[0-9.]\+/\1${version}/" rpm/fast-vm-*.spec

# generate ebuild
cp ebuild/app-emulation/fast-vm/fast-vm-next.ebuild ebuild/app-emulation/fast-vm/fast-vm-${version}.ebuild
