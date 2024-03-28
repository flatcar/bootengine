install() {
    inst_script "$moddir/decrypt-root" \
        "/usr/sbin/decrypt-root"

    inst_simple "$moddir/decrypt-root.service" \
        "$systemdsystemunitdir/decrypt-root.service"

    inst_simple /usr/lib64/cryptsetup/libcryptsetup-token-systemd-tpm2.so

    systemctl --root "$initdir" enable decrypt-root.service
}
