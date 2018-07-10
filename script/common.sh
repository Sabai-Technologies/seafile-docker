#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

SERVER_ADDRESS=${SERVER_ADDRESS:-"127.0.0.1"}

# Functions
log_info() {
    printf "$GREEN[$(date +"%F %T,%3N")] $1$NC\n"
}

log_error() {
    printf "$RED[$(date +"%F %T,%3N")] $1$NC\n"
}

check_require() {
    if [[ -z ${2//[[:blank:]]/} ]]; then
        log_error "$1 is required"
        exit 1
    fi
}

move_media_directory() {
    log_info "Moving seahub/media directory in root exposed directory"
    if [ -d "$EXPOSED_ROOT_DIR/seahub" ]; then
      rm -r  "$EXPOSED_ROOT_DIR/seahub"
    fi
    mkdir "$EXPOSED_ROOT_DIR/seahub"
    mv "$LATEST_SERVER_DIR/seahub/media" "$EXPOSED_ROOT_DIR/seahub/"
    CUR_DIR=$(pwd)
    cd "$EXPOSED_ROOT_DIR/seahub/media"
    ln -sf ../../seahub-data/avatars .
    cd $CUR_DIR
    ln -sf "$EXPOSED_ROOT_DIR/seahub/media" "$LATEST_SERVER_DIR/seahub/media"
}