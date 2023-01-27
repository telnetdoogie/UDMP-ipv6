#!/bin/sh

cp /mnt/data/cronjobs/* /etc/cron.d/
/etc/init.d/crond restart

exit 0
