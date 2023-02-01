#!/bin/bash

cp /data/cronjobs/* /etc/cron.d/
/etc/init.d/cron restart

exit 0
