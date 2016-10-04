#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
VERBOSE=1

die() {
  echo "Failed to install Yum Notifier" 1>&2
  echo "Error: $*" 1>&2
  exit 1
}

srcdir="$DIR/src"

install_opts=( --owner=root --group=root )
[ "$VERBOSE" ] && install_opts+=( --verbose )

install "${install_opts[@]}" --mode=0755 \
  "$srcdir/yum-notifier.sh" "$SRC_DIR/yum-notifier-cron.sh" /usr/local/sbin
[ $? -ne 0 ] && die "Failed to install sbin files"

install "${install_opts[@]}" --mode=0600 --backup \
  "$srcdir/yum-notifier.conf" /etc
[ $? -ne 0 ] && die "Failed to install etc files"

install "${install_opts[@]}" --mode=0755 -T \
  "$srcdir/cronjob.daily.sh" /etc/cron.daily/yum-notifier
[ $? -ne 0 ] && die "Failed to install daily cron file"

install "${install_opts[@]}" --mode=0755 -T \
  "$srcdir/cronjob.weekly.sh" /etc/cron.weekly/yum-notifier
[ $? -ne 0 ] && die "Failed to install weekly cron file"

echo "Yum Notifier successfully installed."
exit 0
