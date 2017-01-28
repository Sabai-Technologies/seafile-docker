#!/bin/bash

. /usr/local/bin/seafile_env.sh

stop(){
  echo "Stopping Seafile"
  $LATEST_SERVER_DIR/seafile.sh stop
  pkill -f '/tmp/seafile.up'
  sleep 2
  exit 0
}

trap stop EXIT

echo "Starting seafile server ..."
$LATEST_SERVER_DIR/seafile.sh start
touch /tmp/seafile.up
echo "... done"

tail -f  /tmp/seafile.up
