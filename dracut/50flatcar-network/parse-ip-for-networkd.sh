#!/bin/bash
#
# This script was mostly stolen from 40network/parse-ip-opts.sh.  Its
# actions are adapted to write .network files to /etc/systemd/network
# in the initramfs instead of using separate DHCP commands, etc.  Note
# the bashisms. It used to be run as a dracut hook, relying on afterburn to
# process kargs for the dracut cmdline target. Now that we start afterburn
# from /sysusr instead of ramdisk root, we need to mount /sysusr first. Mounting
# happens later than the dracut hook we used. Thus we added a systemd unit for
# this script. The unit runs shortly before systemd-networkd.
# However, since the "netroot" variable is set up by another dracut
# hook, this script here will still get executed once as dracut hook
# to save the "netroot" variable to an env file and exit.
# Could the script instead be a hook at a later stage? There doesn't
# seem to be a suitable later stage and also then the env could be
# different. As long as we want to rely on dracut-lib/net-lib for
# parsing the env var topic is not easily avoided.
#

if [ "${APPLY-}" != "1" ]; then
  # First run, called as dracut hook
  {
  # While the script only makes use of the env vars "NEEDBOOTDEV" and "netroot"
  # we actually don't really know what env vars dracut-lib.sh and net-lib.sh
  # will depend on in future versions and therefore, we try to preserve the
  # environment as is.
  for VARNAME in $(compgen -v); do
    # Prevent leaking HEREEOF into VAL ($_ is the argument of the prev. command, and in this loop contains HEREOF)
    [ "${VARNAME}" = "_" ] && continue
    # Skip unnecessary variables
    [[ "${VARNAME}" = "BASH"* ]] && continue
    # Skip errors from read-only variables
    (unset "${VARNAME}" 2> /dev/null) || continue
    VAL="${!VARNAME}"
    echo "${VARNAME}=\$(cat <<'HEREEOF'
${VAL}
HEREEOF
)"
  done
  } > /saved-parse-ip.env
  return;
else
  # Second run, expected to be called as systemd unit
  # Make it a hard error if we forgot to exclude some problematic variables and thus the sourcing terminates without setting all variables
  . /saved-parse-ip.env || { echo "Error: failed sourcing all variables"; exit 1 ; }
fi

# The getarg uses getcmdline which assembles the cmdline on-the-fly
# from /proc/cmdline and the drop-in files under /etc/cmdline.d/
# where afterburn could have written the kargs values
command -v getarg >/dev/null          || . /lib/dracut-lib.sh
command -v ip_to_var >/dev/null       || . /lib/net-lib.sh

if [ -n "$netroot" ] && [ -z "$(getarg ip=)" ] && [ -z "$(getarg BOOTIF=)" ]; then
    # No ip= argument(s) for netroot provided, defaulting to DHCP
    exit 0
fi

function mask2cidr() {
    local -i bits=0
    for octet in ${1//./ }; do
        for i in {0..8}; do
            [ "$octet" -eq $(( 256 - (1 << i) )) ] && bits+=$((8-i)) && break
        done
        [ $i -eq 8 -a "$octet" -ne 0 ] && warn "Bad netmask $mask" && return
        [ $i -gt 0 ] && break
    done
    echo $bits
}

# Check ip= lines
# XXX Would be nice if we could errorcheck ip addresses here as well
for p in $(getargs ip=); do
    ip_to_var $p
    # From here on the variables "ip", "mask" etc are set up (or are cleared)
    # from 'unset ip srv gw mask hostname dev autoconf macaddr mtu dns1 dns2' in ip_to_var
    # ("cidr" is defined below)

    # Empty autoconf defaults to 'dhcp'
    if [ -z "$autoconf" ] ; then
        warn "Empty autoconf values default to dhcp"
        autoconf="dhcp"
    fi

    # Convert the netmask to CIDR notation
    if [[ "x$mask" =~ ^x[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        cidr=$(mask2cidr "$mask")
    elif [ -n "$mask" -a "x${mask//[0-9]/}" = 'x' ]; then
        # The mask is already a prefix length (uint), so validate it
        [[ "x$ip" == x*:*:* && "$mask" -le 128 || "$mask" -le 32 ]] && cidr=$mask
    fi

    # Error checking for autoconf in combination with other values
    for autoopt in $(str_replace "$autoconf" "," " "); do
        case $autoopt in
            error) die "Error parsing option 'ip=$p'";;
            auto6|ibft|bootp|rarp|both) die "Sorry, ip=$autoopt is currenty unsupported";;
            none|off)
                [ -z "$ip" ] && \
                    die "For argument 'ip=$p'\nValue '$autoopt' without static configuration does not make sense"
                [ -z "$mask" ] && \
                    die "Sorry, automatic calculation of netmask is not yet supported"
                [ -z "$cidr" ] && \
                    die "For argument 'ip=$p'\nSorry, failed to convert netmask '$mask' to CIDR"
                ;;
            dhcp|dhcp6|on|any) \
                [ -n "$NEEDBOOTDEV" ] && [ -z "$dev" ] && \
                    die "Sorry, 'ip=$p' does not make sense for multiple interface configurations"
                [ -n "$ip" ] && \
                    die "For argument 'ip=$p'\nSorry, setting client-ip does not make sense for '$autoopt'"
                ;;
            *) die "For argument 'ip=$p'\nSorry, unknown value '$autoopt'";;
        esac
    done

    # Enough validation, write the network file
    # Count down so that early ip= arguments are overridden by later ones
    _net_file=/etc/systemd/network/10-dracut-cmdline-$(( 99 - _net_count++ )).network
    mkdir -p /etc/systemd/network
    echo '[Match]' > $_net_file
    _dev=${dev:-"*"}; echo "Name=$_dev" >> $_net_file
    echo '[Link]' >> $_net_file
    [ -n "$macaddr" ] && echo "MACAddress=$macaddr" >> $_net_file
    [ -n "$mtu" ] && echo "MTUBytes=$mtu" >> $_net_file
    echo '[Network]' >> $_net_file
    [ "x$autoconf" = xoff -o "x$autoconf" = xnone ] &&
        echo DHCP=no >> $_net_file || echo -e "DHCP=yes\nIPv6AcceptRA=true" >> $_net_file
    [ -n "$gw" ] && echo "Gateway=$gw" >> $_net_file
    [ -n "$dns1" ] && echo "DNS=$dns1" >> $_net_file
    [ -n "$dns2" ] && echo "DNS=$dns2" >> $_net_file
    echo '[Address]' >> $_net_file
    [ -n "$ip" ] && echo "Address=$ip/${cidr:-24}" >> $_net_file
    [ -n "$srv" ] && echo "Peer=$srv" >> $_net_file
    echo '[DHCP]' >> $_net_file
    [ -n "$hostname" ] && echo "Hostname=$hostname" >> $_net_file
done
# Have a clear exit code instead of propagating the one from [ -n "$hostname" ]
exit 0
