IP6TABLES_PATH="/usr/sbin"
if test -f "/sbin/iptables-save"; then
        IP6TABLES_PATH="/sbin"
fi

# export ip6tables, remove eth8 entries, replace eth9 entries with he-ipv6
if $IP6TABLES_PATH/ip6tables-save | grep -Fq "eth9" ; then
    echo "Updating ip6tables to replace eth9 with he-ipv6..."
    $IP6TABLES_PATH/ip6tables-save | sed '/eth8/d' | sed 's/eth9/he-ipv6/g' | $IP6TABLES_PATH/ip6tables-restore
fi
