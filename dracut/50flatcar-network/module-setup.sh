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

    inst_multiple \
        "$systemdnetwork"/{20-calico-tunl0,50-veth,98-{gce-coreos-virtio,gce-virtio,virtio}}.link \
        "$systemdnetwork"/yy-{azure-sriov{,-coreos},pxe}.network \
        "$systemdnetwork"/zz-default.network

    # Don't keep the configuration, otherwise the IP address is not released.
    # This can cause problems when a different DHCP client configuration is set
    # on first boot. The DHCP server would not recognize the rootfs system and
    # would therefore keep two addresses allocated.
    sed -i -r 's:^(KeepConfiguration)=.*:\1=no:' \
        "$initdir/$systemdnetwork"/{yy-pxe,zz-default}.network

    inst_simple "$moddir/network-cleanup.service" \
        "$systemdsystemunitdir/network-cleanup.service"

    inst_simple "$moddir/parse-ip-for-networkd.service" \
        "$systemdsystemunitdir/parse-ip-for-networkd.service"

    inst_simple "$moddir/afterburn-network-kargs.service" \
        "$systemdsystemunitdir/afterburn-network-kargs.service"

    inst_simple "$moddir/10-nodeps.conf" \
        "$systemdsystemunitdir/systemd-resolved.service.d/10-nodeps.conf"

    inst_simple "$moddir/yy-digitalocean.network" \
        "$systemdnetwork/yy-digitalocean.network"

    inst_simple "$moddir/yy-digitalocean-coreos.network" \
        "$systemdnetwork/yy-digitalocean-coreos.network"

    inst_simple "$moddir/yy-netroot.network" \
        "$systemdnetwork/yy-netroot.network"

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
