#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

depends() {
  echo systemd
}

install() {

  inst_script "${moddir}/capture-telemetry" \
              "/sbin/capture-telemetry"

  inst_simple "$moddir/azure-telemetry.service" \
    "$systemdsystemunitdir/azure-telemetry.service"
}
