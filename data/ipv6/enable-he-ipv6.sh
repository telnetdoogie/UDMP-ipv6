#Remote endpoint used for your tunnel, HE calls this "Server IPv4 Address:" on tunnelbroker.net under Tunnel Details.
REMOTE_ENDPOINT={your ipv4 HE endpoint}

#Local IPV6 for tunnel, HE calls this "Client IPv6 Address:" on tunnelbroker.net under Tunnel Details
LOCAL_IPV6={your HE ipv6 address}

get_local_endpoint() {
  /sbin/ip route get "$REMOTE_ENDPOINT" 2>/dev/null | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'
}

#Retry getting local endpoint, if one is not yet ready
i=0
LOCAL_ENDPOINT=$(get_local_endpoint)
while [ "x$LOCAL_ENDPOINT" = "x" -a $i -lt 10 ]; do
  logger -t enable-he-ipv6 -p INFO "No route yet (try $i)"
  sleep 1
  i=$((i+1))
  LOCAL_ENDPOINT=$(get_local_endpoint)
done
if [ "x$LOCAL_ENDPOINT" = "x" ]; then
  logger -s -t enable-he-ipv6 -p INFO "No route to $REMOTE_ENDPOINT found, exiting"
  exit 1
else
  logger -t enable-he-ipv6 -p INFO "Found route to $REMOTE_ENDPOINT after $i tries: $LOCAL_ENDPOINT"
fi  

/sbin/ip tunnel add he-ipv6 mode sit remote $REMOTE_ENDPOINT local $LOCAL_ENDPOINT ttl 255
/sbin/ip link set he-ipv6 up

/sbin/ip addr add $LOCAL_IPV6 dev he-ipv6
/sbin/ip route add ::/0 dev he-ipv6

logger -t enable-he-ipv6 -p INFO HE-IPV6 enabled
