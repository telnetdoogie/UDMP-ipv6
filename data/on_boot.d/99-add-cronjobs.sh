#!/bin/sh

cp /data/cronjobs/* /etc/cron.d/
/etc/init.d/crond restart

exit 0
