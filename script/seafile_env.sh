#!/usr/bin/env bash
export SERVER_DIR_BASENAME="seafile-server"
export LATEST_SERVER_DIR=${SEAFILE_ROOT_DIR}/${SERVER_DIR_BASENAME}-latest
export SERVER_DIR="$SEAFILE_ROOT_DIR"/$(ls -1 "$SEAFILE_ROOT_DIR" | grep -E "$SERVER_DIR_BASENAME-[0-9.-]+")
