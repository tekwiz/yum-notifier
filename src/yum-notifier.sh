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

# Location: /usr/local/sbin/yum-notifier.sh
# Permissions: root:root, 0755

PROGNAME=` basename $0 `
CONF_FILE=/etc/yum-notifier.conf

usage () {
  cat <<EOF
Usage: $PROGNAME [-vh] <security-or-full>
description
  security-or-full      "security" or "full"
Options:
  -E,--no-email         Do not send email
  -v,--verbose          Run in verbose mode
  -h,--help             Show this help
EOF
}

_ansicolor_fmtdigit() {
  case $1 in
    reset ) echo -n "0" ;;
    bold ) echo -n "1" ;;
    dim ) echo -n "2" ;;
    underline ) echo -n "4" ;;
    blink ) echo -n "5" ;;
    * ) echo "Invalid format: $1" 1>&2 ; exit 1 ;;
  esac
}

_ansicolor_colordigit() {
  case $1 in
    black ) echo -n "0" ;;
    red ) echo -n "1" ;;
    green ) echo -n "2" ;;
    yellow ) echo -n "3" ;;
    blue ) echo -n "4" ;;
    purple|magenta ) echo -n "5" ;;
    cyan ) echo -n "6" ;;
    gray ) echo -n "7" ;;
    default ) echo -n "9" ;;
    * ) echo "Invalid color: $1" 1>&2 ; exit 1 ;;
  esac
}

# shellcheck disable=SC2059
_ansicolor() {
  if [[ "$*" == "reset" ]]; then
    printf "\e[0m"
  elif [[ "$1" == "reset" ]]; then
    printf "\e[2$(_ansicolor_fmtdigit $2)m"
  else
    c="\e["
    while [[ $# -gt 0 ]] ; do
      case $1 in
        reset )
          c="${c}2$(_ansicolor_fmtdigit $2);"
          shift
          ;;
        bold|dim|underline|blink ) c="$c$(_ansicolor_fmtdigit $1);" ;;
        bkg* ) c="${c}4$(_ansicolor_colordigit ${1#bkg});" ;;
        * ) c="${c}3$(_ansicolor_colordigit $1);" ;;
      esac
      shift
    done
    printf "${c%;}m"
  fi
}

# shellcheck disable=SC2059
_reset() {
  _ansicolor reset
  ( [ $# -gt 0 ] && printf "$@" ) || printf ""
}

VERBOSE=
# shellcheck disable=SC2059
debug() {
  [[ $VERBOSE ]] && ( printf "$@" ; _reset "\n" )
}

VERBOSE=
# shellcheck disable=SC2059
info() {
  printf "$@" ; _reset "\n"
}

# shellcheck disable=SC2059
warn() {
  ( _ansicolor red ; printf "$@" ; _reset "\n" ) 1>&2
}

# shellcheck disable=SC2059
die() {
  ( _ansicolor bold red ; printf "Error: " ; printf "$@" ; _reset "\n" ) 1>&2
  exit 1
}

instance_has_aws_creds() {
  local SECURITY_CREDENTIALS_URL=instance-data/latest/meta-data/iam/security-credentials/
  [ "$( curl -f $SECURITY_CREDENTIALS_URL 2>/dev/null )" ] && return 0
  return 1
}

env_has_aws_creds() {
  [ "$AWS_ACCESS_KEY_ID" ] && [ "$AWS_SECRET_ACCESS_KEY" ] && return 0
  return 1
}

load_and_validate_conf_file() {
  [ -z "$CONF_FILE" ] && die "CONF_FILE not set"
  [ ! -r "$CONF_FILE" ] && die "CONF_FILE (%s) does not exist or is not readable" "$CONF_FILE"
  # shellcheck source=yum-notifier.conf
  source "$CONF_FILE"
  [ $? -ne 0 ] && conf_file_err "Failed to load CONF_FILE (%s)" "$CONF_FILE"

  if [[ $SEND_EMAIL ]]; then
    failure=
    [ -z "$FROM_EMAIL" ] && ( failure=1 && warn "FROM_EMAIL not defined" )
    [ -z "$NOTIFY_EMAIL" ] && ( failure=1 && warn "NOTIFY_EMAIL not defined" )

    local has_credentials=
    instance_has_aws_creds && has_credentials=1
    env_has_aws_creds && has_credentials=1
    [ -z $has_credentials ] && ( failure=1 && warn "AWS credentials not defined" )

    [ $failure ] && die "One or more failures loading %s" "$CONF_FILE"
  fi
}

[ $# -eq 0 ] && usage && exit

SEND_EMAIL=1
INCLUDE_SUMMARY=
UPDATES=
updateinfo_types=( )
FROM_EMAIL=
NOTIFY_EMAIL=
SNS_TOPIC=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
SUPPRESS_NOTICES=( )

while [[ $# -gt 0 ]] ; do
  case "$1" in
    -E|--no-email ) SEND_EMAIL= && shift ;;
    -v|--verbose ) VERBOSE=1 && shift ;;
    -h|--help ) usage && exit ;;
    -* ) warn "Invalid option: %s\n" "$1" && usage && exit 1 ;;
    * )
      if [[ -z "$UPDATES" ]]; then
        UPDATES="$1"
        if [[ "$UPDATES" = "security" ]]; then
          updateinfo_types=( security cves )
        elif [[ "$UPDATES" = "full" ]]; then
          updateinfo_types=( security cves bugzillas bugfix recommended enhancement )
        else
          warn "Invalid parameter: %s. Expected security or full\n" "$1" && usage && exit 1
        fi
      else
        warn "Invalid parameter: %s\n" "$1" && usage && exit 1
      fi
      shift
      ;;
  esac
done

( [ -z "$UPDATES" ] || [ "${#updateinfo_types[@]}" -eq 0 ] ) && \
  die "Invalid parameters%s\n%s" "$( _reset )" "$(usage)"

load_and_validate_conf_file

if env_has_aws_creds; then
  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
fi

updateinfo_running_kernel() {
  local result
  result=$( yum -q updateinfo check-running-kernel )
  exitcode=$?
  [ $exitcode -ne 0 ] && die "yum updateinfo check-running-kernel failed. Exit status $exitcode"
  [ -z "$result" ] && return 1
  echo "$result"
}

updates_list() {
  local result
  result=$( yum -q list updates )
  exitcode=$?
  [ $exitcode -ne 0 ] && die "yum list updates failed. Exit status $exitcode"
  [ -z "$result" ] && return 1
  echo "$result"
}

updateinfo_list() {
  local data=
  local data_tmp=

  for t in "${updateinfo_types[@]}" ; do
    debug "Listing updateinfo for %s" "$t" 1>&2
    data_tmp="$( yum -q updateinfo list updates $t )"
    exitcode=$?
    [ $exitcode -ne 0 ] && echo "yum updateinfo list updates $t failed. Exit status $exitcode"
    [ "$data_tmp" ] && data="$data"$'\n'"$data_tmp"
  done

  [ -z "$data" ] && return 1

  if [[ ${#SUPPRESS_NOTICES} -gt 0 ]]; then
    sed_suppress_args=( )
    for n in "${SUPPRESS_NOTICES[@]}" ; do
      if [[ $(tr -d "[:alnum:]-\n" <<< "$n" | wc -c) -ne 0 ]]; then
        warn "Skipping invalid value in SUPPRESS_NOTICES: %s" "$n"
        continue
      fi
      debug "Supressing %s" "$n" 1>&2
      sed_suppress_args+=( -e "/^\\s*${n}\\b/ d" )
    done
    data=$( sed -r "${sed_suppress_args[@]}" <<< "$data" )
  fi

  [ -z "$data" ] && return 1
  echo "$data" \
    | sed -E \
      -e 's/^\s*(.+)\b\s+\b(\S+)\s+\b(.+)$/\3 \2 \1/' \
      -e '/^\s*$/ d' \
    | sort --unique
}

msg_text="Updates are available for $( hostname )"$'\n'"Timestamp: $( date )"

debug_email_text() {
  debug $'%sEmail text:%s\n%s\n' "$( _ansicolor bold )" "$( _reset )" "$msg_text"
}

if [[ $INCLUDE_SUMMARY ]]; then
  msg_text_tmp="$( updateinfo_summary )"
  [ $? -eq 0 ] && msg_text="$msg_text"$'\n\n'"$msg_text_tmp"
fi

msg_text_tmp="$( updateinfo_list )"
if [[ $? -eq 0 ]]; then
  msg_text="$msg_text"$'\n\n'"$msg_text_tmp"
elif [[ $UPDATES = 'security' ]]; then
  debug_email_text
  info 'No updates'
  exit 0
fi

if [[ $UPDATES = 'full' ]]; then
  msg_text_tmp="$( updates_list )"
  if [[ $? -eq 0 ]]; then
    msg_text="$msg_text"$'\n\n'"$msg_text_tmp"
  else
    debug_email_text
    info 'No updates'
    exit 0
  fi
fi

debug_email_text

if [[ $SEND_EMAIL ]]; then
  aws --region us-east-1 --output text ses send-email \
    --from "$FROM_EMAIL" \
    --to "$NOTIFY_EMAIL" \
    --subject "Security updates for $( hostname )" \
    --text "$msg_text"

  if [[ $? -eq 0 ]]; then
    info "Sent updates email to %s" "$NOTIFY_EMAIL"
  else
    warn "Failed send updates email to %s" "$NOTIFY_EMAIL"
  fi
fi

if [[ "$SNS_TOPIC" ]]; then
  msg_text_fn=$( mktemp /tmp/yum-notifier-msg.txt.XXXXXX )
  aws --region us-east-1 --output text sns publish \
    --topic-arn "$SNS_TOPIC" \
    --subject "Security updates for $( hostname )" \
    --message "file://$msg_text_fn"

  if [[ $? -eq 0 ]]; then
    info "Sent updates notification to %s" "$SNS_TOPIC"
  else
    warn "Failed send updates notification to %s" "$SNS_TOPIC"
  fi

  rm -f $msg_text_fn
fi
