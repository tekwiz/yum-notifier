#!/bin/bash

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
