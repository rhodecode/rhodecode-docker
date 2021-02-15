#!/usr/bin/env bash
set -Eeo pipefail


BOOTSTRAP_FILE=.bootstrapped

# Avoid destroying bootstrapping by simple start/stop
if [[ ! -e /.$BOOTSTRAP_FILE ]]; then
  echo "ENTRYPOINT: Starting $RC_APP_TYPE bootstrap"

  touch $MOD_DAV_SVN_CONF_FILE
  touch /$BOOTSTRAP_FILE
fi

exec "$@"