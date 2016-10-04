#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DIR_BN=$( basename "$DIR" )

rm -vf "$DIR/yum-notifier.tar.gz"
tar -C "$DIR/.." -czvf "$DIR/yum-notifier.tar.gz" \
  "$DIR_BN/src" "$DIR_BN/install.sh" "$DIR_BN/README.md"
