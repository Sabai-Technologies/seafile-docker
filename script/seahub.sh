#!/bin/bash

. /usr/local/bin/seafile_env.sh

RESULT=1

stop(){
  echo "Stopping Seahub"
  $LATEST_SERVER_DIR/seahub.sh stop
  pkill -f '/tmp/seahub.up'
  sleep 2
  exit 0
}

trap '[ $RESULT = 0 ] && stop;' EXIT

echo "Starting seahub server ..."
$LATEST_SERVER_DIR/seahub.sh start
RESULT=$?
if [[ $RESULT -eq 0 ]]; then
    touch /tmp/seahub.up
    echo "... done"
    tail -f /tmp/seahub.up
else
    echo "... error while starting Seahub"
    exit 1
fi
