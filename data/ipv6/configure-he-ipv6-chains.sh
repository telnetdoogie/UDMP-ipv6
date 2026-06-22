#!/bin/bash

# Default ip6tables path is /usr/sbin, but on some devices (UDMP-SE) it is located in /sbin, so we will check for that and update the path if needed
IP6TABLES_PATH="/usr/sbin"
#UDMP-SE path
if test -f "/sbin/iptables-save"; then
    IP6TABLES_PATH="/sbin"
fi

# Detect active WAN interface
WAN_IFACE=$(ip route get 8.8.8.8 | awk 'NR==1{ print $5 }')

if [[ -z "${WAN_IFACE}" ]]; then
    echo "Could not determine WAN interface, exiting"
    exit 1
fi

if [[ ${WAN_IFACE} =~ \. ]]; then
    # may be a ppp0 interface
    WAN_IFACE=$(echo "${WAN_IFACE}" | grep -o '\.[^.]*$' | sed 's/\.//')
fi

# Check to see if WAN interface rules have been re-created
if ${IP6TABLES_PATH}/ip6tables-save | grep -Fqi "${WAN_IFACE}" ; then

    # if he-ipv6 entries still exist, remove them before proceeding
    if ${IP6TABLES_PATH}/ip6tables-save | grep -Fqi "he-ipv6" ; then
        echo "Removing old he-ipv6 references..."
        ${IP6TABLES_PATH}/ip6tables-save | sed '/he-ipv6/Id' | ${IP6TABLES_PATH}/ip6tables-restore
    fi

    # export ip6tables, replace WAN interface entries with he-ipv6
    echo "Updating ip6tables to replace ${WAN_IFACE} with he-ipv6..."
    ${IP6TABLES_PATH}/ip6tables-save | sed "s/${WAN_IFACE}/he-ipv6/g" | sed "s/${WAN_IFACE^^}/HE-IPV6/g" | ${IP6TABLES_PATH}/ip6tables-restore

fi