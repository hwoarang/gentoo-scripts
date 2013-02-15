#!/bin/bash
# Simple Kernel update script for Gentoo Linux
# Markos Chandras <hwoarang@gentoo.org>
# See LICENSE file in the repository for copyright

set -e

# get config file
pushd /usr/src/linux > /dev/null 2>&1
[[ ! -e .config ]] && zcat /proc/config.gz > .config

$(mount|grep -q /boot) || mount /boot

make -j$(getconf _NPROCESSORS_CONF) && make modules_install && make install

module-rebuild -X rebuild
# Fix grub.conf
kernel=$(readlink /usr/src/linux | sed -e "s:linux-::" -e "s:-gentoo::")
[[ -z ${kernel} ]] && \
	{ echo "Failed to find kernel version"; exit 1; }

sed -i -e \
	"/vmlinuz/s:vmlinuz-.*-gentoo:vmlinuz-${kernel}-gentoo:" \
	/boot/grub/grub.conf || { echo "Failed to fix grub"; exit 1; }

#remove old kernel bits
old_kernel=$(uname -r | cut -d '-' -f 1)

if [[ "${kernel}" != "${old_kernel}" ]]; then
	[[ -z ${old_kernel} ]] && \
		{ echo "Failed to find old kernel version"; exit 1; }

	rm -r /boot/*${old_kernel}* || { echo "Failed to remove boot files"; exit 1; }	
	rm -r /lib/modules/${old_kernel}* || { echo "Failed to remove modules"; exit 1; }
fi

umount /boot
popd > /dev/null 2>&1

# Remove old packages
emerge -P gentoo-sources

exit 0
