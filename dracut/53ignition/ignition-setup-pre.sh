#!/bin/bash
# This is split out of the generator to not write to /run/ from it

set -e

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
