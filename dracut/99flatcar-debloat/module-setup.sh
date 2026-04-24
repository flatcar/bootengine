config() {
    # gcrypt: Only needed for systemd-journal's FSS feature.
    # lz4: Flatcar has never needed this for the journal or coredumps.
    omit_dlopen_features+=" libsystemd-shared-*.so:gcrypt,lz4 "
}

# shellcheck disable=SC2064
trap "$(shopt -p extglob)" RETURN
shopt -q -s extglob

install() {
    # shellcheck disable=SC2064
    trap "$(shopt -p extglob)" RETURN
    shopt -q -s extglob

    # Remove the NSS modules we don't need.
    rm "${initdir}"/usr/lib*/libnss_!(dns|files|myhostname|resolve|systemd).so*

    # We maybe should include this, but more work is needed for compliance.
    rm "${initdir}"/usr/lib*/ossl-modules/fips.so

    # drop it when updating to dracut 110
    inst_libdir_file "libaudit.so*"
    inst_libdir_file "libpam.so*"
    inst_libdir_file "libseccomp.so*"
}
