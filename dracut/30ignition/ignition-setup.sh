#!/bin/bash
# Set up /usr/lib/ignition, copying contents from /oem.

set -e

case "$1" in
normal)
    src=/mnt/oem
    mkdir -p "${src}"
    mount /dev/disk/by-label/OEM "${src}"
    # retry-umount may not be necessary, but be cautious
    trap 'retry-umount "${src}"' EXIT
    ;;
pxe)
    # OEM directory in the initramfs itself.
    # Despite having the OEM partition being moved to
    # /oem in general, we keep checking /usr/share/oem in initrds to avoid
    # breaking compatibility.
    src=/usr/share/oem
    ;;
*)
    echo "Usage: $0 {normal|pxe}" >&2
    exit 1
esac

dst=/usr/lib/ignition
mkdir -p "${dst}/base.d"

if [[ -e "${src}/base/base.ign" ]]; then
        cp "${src}/base/base.ign" "${dst}/base.d/"
fi
if [[ -e "${src}/config.ign" ]]; then
    cp "${src}/config.ign" "${dst}/user.ign"
fi
