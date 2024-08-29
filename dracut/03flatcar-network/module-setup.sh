#!/bin/bash

# This module extends dracut's systemd-networkd module to include additional
# networking configuration for Ignition.

# called by dracut
depends() {
    echo net-lib systemd-networkd
}

# called by dracut
install() {
    inst_multiple -o \
        $systemdutildir/systemd-resolved \
        $systemdsystemunitdir/systemd-resolved.service \
        /etc/systemd/resolved.conf

    inst_simple "$moddir/network-cleanup.service" \
        "$systemdsystemunitdir/network-cleanup.service"

    inst_simple "$moddir/parse-ip-for-networkd.service" \
        "$systemdsystemunitdir/parse-ip-for-networkd.service"

    inst_simple "$moddir/afterburn-network-kargs.service" \
        "$systemdsystemunitdir/afterburn-network-kargs.service"

    inst_simple "$moddir/10-nodeps.conf" \
        "$systemdsystemunitdir/systemd-resolved.service.d/10-nodeps.conf"

    inst_simple "$moddir/yy-azure-sriov.network" \
        "$systemdutildir/network/yy-azure-sriov.network"

    inst_simple "$moddir/yy-digitalocean.network" \
        "$systemdutildir/network/yy-digitalocean.network"

    inst_simple "$moddir/yy-netroot.network" \
        "$systemdutildir/network/yy-netroot.network"

    inst_simple "$moddir/yy-pxe.network" \
        "$systemdutildir/network/yy-pxe.network"

    inst_simple "$moddir/zz-default.network" \
        "$systemdutildir/network/zz-default.network"

    # add a hook to generate networkd configuration from ip= arguments
    inst_hook cmdline 99 "$moddir/parse-ip-for-networkd.sh"

    # user/group required for systemd-resolved
    getent passwd systemd-resolve >> "$initdir/etc/passwd"
    getent group systemd-resolve >> "$initdir/etc/group"

    # point /etc/resolv.conf @ systemd-resolved's resolv.conf
    ln -s ../run/systemd/resolve/resolv.conf "$initdir/etc/resolv.conf"

    # the systemd-networkd dracut module enables networkd by default, but
    # we only want it when pulled in
    systemctl --root "$initdir" disable systemd-networkd.service
    systemctl --root "$initdir" disable systemd-networkd.socket

    systemctl --root "$initdir" enable network-cleanup.service
    systemctl --root "$initdir" enable parse-ip-for-networkd.service
    systemctl --root "$initdir" enable afterburn-network-kargs.service
}
