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
    # Workaround, "chmod" is not available
    cp -a /bin/cat /bin/is-live-image
    printf '#!/bin/sh\nexit 1\n' > /bin/is-live-image
    ;;
pxe)
    # OEM directory in the initramfs itself
    src=/oem
    # Workaround, "chmod" is not available
    cp -a /bin/cat /bin/is-live-image
    printf '#!/bin/sh\nexit 0\n' > /bin/is-live-image
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

cmdline=( $(</proc/cmdline) )
cmdline_arg() {
    local name="$1" value="$2"
    for arg in "${cmdline[@]}"; do
        if [[ "${arg%%=*}" == "${name}" ]]; then
            value="${arg#*=}"
        fi
    done
    echo "${value}"
}

oem_id=metal
if [[ $(systemd-detect-virt || true) =~ ^(kvm|qemu)$ ]]; then
    oem_id=qemu
fi

oem_cmdline="$(cmdline_arg flatcar.oem.id ${oem_id})"
if [[ "${oem_id}" = "${oem_cmdline}" ]]; then
    oem_cmdline="$(cmdline_arg coreos.oem.id ${oem_id})"
fi

# Ignition changed the platform name to "aws"
if [ "${oem_cmdline}" = "ec2" ]; then
  oem_cmdline="aws"
fi

# Ignition changed the platform name to "gcp"
if [ "${oem_cmdline}" = "gce" ]; then
  oem_cmdline="gcp"
fi

# To maintain compatibility with eventual legacy 'flatcar.oem.id=pxe'
if [ "${oem_cmdline}" = "pxe" ]; then
  oem_cmdline="metal"
fi

{ echo "OEM_ID=${oem_cmdline}" ; echo "PLATFORM_ID=${oem_cmdline}" ; } > /run/ignition.env
