#Remote endpoint used for your tunnel, HE calls this "Server IPv4 Address:" on tunnelbroker.net under Tunnel Details.
REMOTE_ENDPOINT={your ipv4 HE endpoint}

#Local IPV6 for tunnel, HE calls this "Client IPv6 Address:" on tunnelbroker.net under Tunnel Details
LOCAL_IPV6={your HE ipv6 address}

LOCAL_ENDPOINT=`/sbin/ip route get $REMOTE_ENDPOINT | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'`

/sbin/ip tunnel add he-ipv6 mode sit remote $REMOTE_ENDPOINT local $LOCAL_ENDPOINT ttl 255
/sbin/ip link set he-ipv6 up

/sbin/ip addr add $LOCAL_IPV6 dev he-ipv6
/sbin/ip route add ::/0 dev he-ipv6

logger -s -t enable-he-ipv6 -p INFO HE-IPV6 enabled
