#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

depends() {
    echo systemd
}

install() {
    dracut_install tr
    inst_simple "$moddir/usr-generator" \
        "$systemdutildir/system-generators/usr-generator"
    inst_simple "$moddir/remount-sysroot.service" \
        "$systemdutildir/system/remount-sysroot.service"

    # Overwrite systemd-fsck-usr.service because it wants After=local-fs-pre.target
    # which prevents (the systemd-generated) sysusr-usr.mount from starting before Ignition
    # but we need it because we want to start Ignition from /sysusr/usr/ already.
   cat > "$initdir/etc/systemd/system/systemd-fsck-usr.service" <<EOF
# Set up by 10usr-generator/module-setup.sh
[Unit]
DefaultDependencies=no
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=true
EOF

}
