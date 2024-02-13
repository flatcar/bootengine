#!/bin/bash

# called by dracut
depends() {
    echo systemd-networkd
}

# called by dracut
install() {
    inst_simple "$moddir/systemd-tmpfiles-setup-dev-early.service" \
        "$systemdsystemunitdir/systemd-tmpfiles-setup-dev-early.service"
}
