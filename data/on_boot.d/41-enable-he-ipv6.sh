#!/bin/sh
DELAY=60

#delay start, since networking is still not started yet
echo "Adding he-ipv6 tunnel in $DELAY seconds..." | /usr/bin/logger
sleep $DELAY && /data/ipv6/enable-he-ipv6.sh &
