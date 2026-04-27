#!/bin/bash
# This is split out of the generator to not write to /run/ from it

set -e

read -r -a cmdline < /proc/cmdline
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

case $(systemd-detect-virt) in
    kvm|qemu) oem_id=qemu ;;
esac

oem_cmdline=$(cmdline_arg flatcar.oem.id ${oem_id})
if [[ ${oem_id} == "${oem_cmdline}" ]]; then
    oem_cmdline=$(cmdline_arg coreos.oem.id ${oem_id})
fi

case ${oem_cmdline} in
    # Ignition changed the platform name to "aws"
    ec2) oem_cmdline=aws ;;
    # Ignition changed the platform name to "gcp"
    gce) oem_cmdline=gcp ;;
    # To maintain compatibility with eventual legacy 'flatcar.oem.id=pxe'
    pxe) oem_cmdline=metal ;;
esac

cat > /run/ignition.env <<EOF
OEM_ID=${oem_cmdline}
PLATFORM_ID=${oem_cmdline}
EOF
