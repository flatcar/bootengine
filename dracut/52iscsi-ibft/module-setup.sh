#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# Keep the iSCSI root disk of a machine that boots from the iBFT (Oracle Cloud bare
# metal). minimal-init logged in to the iSCSI target and wrote
# /etc/cmdline.d/90-ibft.conf, which makes dracut's iscsi module take the session
# over; the units of this module only run when that file exists.

depends() {
    echo iscsi systemd-networkd
}

install() {
    inst_multiple ip sed

    inst_script "$moddir/ibft-network" \
        "/usr/bin/ibft-network"
    inst_script "$moddir/ibft-root-setup" \
        "/usr/bin/ibft-root-setup"

    inst_simple "$moddir/ibft-network.service" \
        "$systemdsystemunitdir/ibft-network.service"
    inst_simple "$moddir/ibft-root-setup.service" \
        "$systemdsystemunitdir/ibft-root-setup.service"

    systemctl --root "$initdir" enable ibft-network.service ibft-root-setup.service
}
