#!/bin/bash

# Copyright 2016 MaxMedia <https://www.maxmedia.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
  "$srcdir/yum-notifier.sh" "$srcdir/yum-notifier-cron.sh" /usr/local/sbin
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
