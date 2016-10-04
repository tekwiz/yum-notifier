#!/bin/bash
# Location: /etc/cron.daily/yum-notifier
# Permissions: root:root, 0755

exec /usr/local/sbin/yum-notifier-cron.sh security
