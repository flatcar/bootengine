#!/bin/bash

# This module extends dracut's systemd-networkd module to include additional
# networking configuration for Ignition.

# called by dracut
depends() {
    echo net-lib systemd-networkd systemd-resolved
}

# called by dracut
install() {
    inst_multiple \
        "$systemdnetwork"/98-{gce-coreos-virtio,gce-virtio,virtio}.link \
        "$systemdnetwork"/yy-{azure-sriov{,-coreos},pxe}.network \
        "$systemdnetwork"/zz-default.network

    # Don't keep the configuration, otherwise the IP address is not released.
    # This can cause problems when a different DHCP client configuration is set
    # on first boot. The DHCP server would not recognize the rootfs system and
    # would therefore keep two addresses allocated.
    sed -i -r 's:^(KeepConfiguration)=.*:\1=no:' \
        "$initdir/$systemdnetwork"/{yy-pxe,zz-default}.network

    inst_simple "$moddir/yy-digitalocean.network" \
        "$systemdnetwork/yy-digitalocean.network"

    inst_simple "$moddir/yy-digitalocean-coreos.network" \
        "$systemdnetwork/yy-digitalocean-coreos.network"

    inst_simple "$moddir/yy-netroot.network" \
        "$systemdnetwork/yy-netroot.network"

    inst_simple "$moddir/network-cleanup.service" \
        "$systemdsystemunitdir/network-cleanup.service"

    inst_simple "$moddir/afterburn-network-kargs.service" \
        "$systemdsystemunitdir/afterburn-network-kargs.service"

    # Feed afterburn-injected kargs (in Dracut's cmdline.d) to
    # systemd-network-generator, which only reads /proc/cmdline.
    inst_simple "$moddir/systemd-network-generator-afterburn.conf" \
        "$systemdsystemunitdir/systemd-network-generator.service.d/10-afterburn.conf"

    # The systemd-networkd and systemd-resolved Dracut modules enable their
    # services by default, but we only want them when pulled in on demand.
    systemctl --root "$initdir" disable systemd-networkd.{service,socket} systemd-resolved.service

    # Disabling systemd-networkd also disables its generator because the former
    # lists the latter in its [Install] Also=, so explicitly re-enable it.
    systemctl --root "$initdir" enable systemd-network-generator.service

    systemctl --root "$initdir" enable network-cleanup.service
}
