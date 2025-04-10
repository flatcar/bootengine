#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

install() {
    # Simply pull in all the shadow db files so things like systemd-tmpfiles
    # will always be able to find users referenced by the baselayout files.
    inst_simple /usr/share/baselayout/passwd  /etc/passwd
    inst_simple /usr/share/baselayout/shadow  /etc/shadow
    inst_simple /usr/share/baselayout/group   /etc/group
    inst_simple /usr/share/baselayout/gshadow /etc/gshadow
}
