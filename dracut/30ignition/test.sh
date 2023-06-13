for i in clevis-encrypt-tpm2 clevis-luks-bind clevis-luks-common-functions clevis-luks-unlock  pwmake tpm2_create clevis-decrypt-tpm2 tpm2_createprimary tpm2_flushcontext tpm2_load tpm2_unseal tpm2_pcrread tpm2_pcrlist clevis-luks-common-functions clevis-decrypt clevis-luks-list luksmeta clevis jose; do printf "#!/bin/sh\nLD_LIBRARY_PATH=/sysusr/usr/lib64 exec /sysusr/usr/bin/"$i" "$@"\n" > "$i"-wrapper; done

printf   "#!/bin/sh\nLD_LIBRARY_PATH=/sysusr/usr/lib64 exec /sysusr/usr/local/libexec/clevis-luks-askpass "$@"\n"   > clevis-luks-askpass-wrapper  
printf   "#!/bin/sh\nLD_LIBRARY_PATH=/sysusr/usr/lib64 exec /sysusr/usr/lib/systemd-reply-password "$@"\n"   > clevis-reply-password-wrapper





