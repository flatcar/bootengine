#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

depends() {
    # Flatcar: do not depend on "url-lib network"
    echo qemu systemd
}

install_ignition_unit() {
    local unit="$1"; shift
    local target="${1:-ignition-complete.target}"; shift
    local instantiated="${1:-$unit}"; shift
    inst_simple "$moddir/$unit" "$systemdsystemunitdir/$unit"
    mkdir -p "$initdir/$systemdsystemunitdir/$target.requires"
    ln_r "../$unit" "$systemdsystemunitdir/$target.requires/$instantiated"
}

install() {
    # Flatcar: add coreos-metadata, systemd-detect-virt, mountpoint, nvme
    inst_multiple \
        basename \
        lsblk

    # Not all features of the configuration may be available on all systems
    # (e.g. on embedded systems), so only add applications which are actually
    # present
    inst_multiple -o \
        groupadd \
        groupdel \
        systemd-detect-virt \
        mountpoint \
        mkfs.btrfs \
        mkfs.ext4 \
        mkfs.fat \
        mkfs.xfs \
        mkswap \
        nvme \
        sgdisk \
        partx \
        useradd \
        userdel \
        usermod \
        wipefs \
        cryptsetup

    # Flatcar: add cloud_aws_ebs_nvme_id
    inst_script "$udevdir/cloud_aws_ebs_nvme_id" \
        "/usr/lib/udev/cloud_aws_ebs_nvme_id"

    # Needed for clevis binding; note all binaries related to unlocking are
    # included by the Clevis dracut modules.
    inst_multiple -o \
        clevis-encrypt-sss \
        clevis-encrypt-tang \
        clevis-encrypt-tpm2 \
        clevis-luks-bind \
        clevis-luks-common-functions \
        clevis-luks-unlock \
        pwmake \
        tpm2_create

    # Required by s390x's z/VM installation.
    # Supporting https://github.com/coreos/ignition/pull/865
    inst_multiple -o chccwdev vmur

    # Required on system using SELinux
    inst_multiple -o setfiles

    inst_script "$moddir/ignition-kargs-helper" \
        "/usr/sbin/ignition-kargs-helper"

    # Flatcar: add ignition-setup
    inst_script "$moddir/ignition-setup.sh" \
        "/usr/sbin/ignition-setup"

    # Flatcar: add ignition-setup-pre
    inst_script "$moddir/ignition-setup-pre.sh" \
        "/usr/sbin/ignition-setup-pre"

    # Rule to allow udev to discover unformatted encrypted devices
    inst_simple "$moddir/99-xx-ignition-systemd-cryptsetup.rules" \
        "/usr/lib/udev/rules.d/99-xx-ignition-systemd-cryptsetup.rules"

    # disable dictcheck
    inst_simple "$moddir/ignition-luks.conf" \
        "/etc/security/pwquality.conf.d/ignition-luks.conf"

    # Flatcar: add retry-umount
    inst_script "$moddir/retry-umount.sh" \
        "/usr/sbin/retry-umount"

    inst_simple "$moddir/ignition-generator" \
        "$systemdutildir/system-generators/ignition-generator"

    for x in "complete" "subsequent" "diskful" "diskful-subsequent"; do
        inst_simple "$moddir/ignition-$x.target" \
            "$systemdsystemunitdir/ignition-$x.target"
    done

    # Flatcar: add ignition-quench.service, sysroot-boot.service,
    # flatcar-digitalocean-network.service, flatcar-static-network.service,
    # flatcar-metadata-hostname.service, flatcar-openstack-hostname.service
    inst_simple "$moddir/ignition-quench.service" \
        "$systemdsystemunitdir/ignition-quench.service"
    inst_simple "$moddir/sysroot-boot.service" \
        "$systemdsystemunitdir/sysroot-boot.service"
    inst_simple "$moddir/flatcar-digitalocean-network.service" \
        "$systemdsystemunitdir/flatcar-digitalocean-network.service"
    inst_simple "$moddir/flatcar-static-network.service" \
        "$systemdsystemunitdir/flatcar-static-network.service"
    inst_simple "$moddir/flatcar-metadata-hostname.service" \
        "$systemdsystemunitdir/flatcar-metadata-hostname.service"
    inst_simple "$moddir/flatcar-openstack-hostname.service" \
        "$systemdsystemunitdir/flatcar-openstack-hostname.service"

    install_ignition_unit ignition-fetch.service
    install_ignition_unit ignition-fetch-offline.service
    install_ignition_unit ignition-kargs.service
    install_ignition_unit ignition-disks.service
    install_ignition_unit ignition-mount.service
    install_ignition_unit ignition-files.service

    # units only started when we have a boot disk
    # path generated by systemd-escape --path /dev/disk/by-label/root
    install_ignition_unit ignition-remount-sysroot.service ignition-diskful.target

    # needed for openstack config drive support
    # Flatcar: add 66-azure-storage.rules and 90-cloud-storage.rules
    inst_rules 60-cdrom_id.rules 66-azure-storage.rules 90-cloud-storage.rules

    # Flatcar: add symlinks for dependencies of Ignition, coreos-metadata (afterburn), and 
    # Clevis. This saves space in the initramfs image by replacing files with symlinks to
    # the previously mounted /sysusr/.
    for executable in \
        /usr/bin/clevis-decrypt-sss \
        /usr/bin/clevis-decrypt-tang \
        /usr/bin/clevis-decrypt-tpm2 \
        /usr/bin/clevis-decrypt \
        /usr/bin/clevis-encrypt-sss \
        /usr/bin/clevis-encrypt-tang \
        /usr/bin/clevis-encrypt-tpm2 \
        /usr/bin/clevis-luks-bind \
        /usr/bin/clevis-luks-common-functions \
        /usr/bin/clevis-luks-list \
        /usr/bin/clevis-luks-unlock \
        /usr/bin/clevis \
        /usr/bin/coreos-metadata \
        /usr/bin/curl \
        /usr/bin/ignition \
        /usr/bin/jose \
        /usr/bin/luksmeta \
        /usr/bin/mktemp \
        /usr/bin/pwmake \
        /usr/bin/sort \
        /usr/bin/tail \
        /usr/bin/tpm2_createprimary \
        /usr/bin/tpm2_create \
        /usr/bin/tpm2_flushcontext \
        /usr/bin/tpm2_load \
        /usr/bin/tpm2_pcrlist \
        /usr/bin/tpm2_pcrread \
        /usr/bin/tpm2_unseal \
        /usr/lib/systemd-reply-password \
        /usr/local/libexec/clevis-luks-askpass \
        /usr/libexec/clevis-luks-generic-unlocker \
        /usr/sbin/setfiles \
    ; do
        directory="$(dirname "$executable")"
        filename="$(basename "$executable")"

        wrapper_name="${filename}-wrapper"
        cat <<EOF > /tmp/${filename}-wrapper
#!/bin/sh

LD_LIBRARY_PATH=/sysusr/usr/lib64 exec "/sysusr${executable}" "\$@"
EOF
        chmod +x /tmp/${filename}-wrapper

        inst_script "/tmp/${filename}-wrapper" \
            "/usr/bin/$filename"
            
        rm /tmp/${filename}-wrapper
    done

}

# See: https://github.com/coreos/ignition/commit/d304850c3d3696822bc05e0833ee4b27df9d7a38
installkernel() {
     # required by hyperv platform to read kvp from the kernel
     instmods -c hv_utils
}
