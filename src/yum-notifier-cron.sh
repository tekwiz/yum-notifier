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

# Location: /usr/local/sbin/yum-notifier-cron.sh
# Permissions: root:root, 0755

PROGNAME=` basename $0 `

usage () {
  cat <<EOF
Usage: $PROGNAME <security-or-full>
YUM notifier cron script
  security-or-full      "security" or "full"
EOF
}

NOTIFIER_TYPE="$1"
if [[ "$NOTIFIER_TYPE" != "security" ]] && [[ "$NOTIFIER_TYPE" != "full" ]]; then
  "Invalid parameter: %s. Expected security or full\n" "$NOTIFIER_TYPE" && usage && exit 1
fi

notifier_results=$( /usr/local/sbin/yum-notifier.sh $NOTIFIER_TYPE 2>&1 )
EXITVALUE=$?

/usr/bin/logger -t yum-notifier "$notifier_results"

if [[ $EXITVALUE -ne 0 ]]; then
  /usr/bin/logger -p user.error -t yum-notifier "exited with status $EXITVALUE"
fi

exit 0
