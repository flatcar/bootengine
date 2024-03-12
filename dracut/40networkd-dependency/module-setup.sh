#!/bin/bash

depends() {
    echo systemd
}

install() {
    inst_simple "$moddir/networkd-dependency-generator" \
        "$systemdutildir/system-generators/networkd-dependency-generator"
}
