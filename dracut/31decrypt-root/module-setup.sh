install() {
    inst_script "$moddir/decrypt-root" \
        "/usr/sbin/decrypt-root"

    inst_simple "$moddir/decrypt-root.service" \
        "$systemdsystemunitdir/decrypt-root.service"
    
    systemctl --root "$initdir" enable decrypt-root.service
}
