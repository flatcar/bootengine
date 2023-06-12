#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

depends() {
    echo fs-lib
}

install() {
    dracut_install grep ldconfig mountpoint systemd-tmpfiles flatcar-tmpfiles realpath

    inst_script "${moddir}/initrd-setup-root" \
	        "/sbin/initrd-setup-root"
    inst_script "${moddir}/initrd-setup-root-after-ignition" \
                "/sbin/initrd-setup-root-after-ignition"

    inst_simple "${moddir}/initrd-setup-root.service" \
        "${systemdsystemunitdir}/initrd-setup-root.service"

    inst_simple "${moddir}/initrd-setup-root-after-ignition.service" \
        "${systemdsystemunitdir}/initrd-setup-root-after-ignition.service"
    inst_script "$moddir/gpg-agent-wrapper" \
        "/usr/bin/gpg-agent"
}
