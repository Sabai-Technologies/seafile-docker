#!/bin/bash

source /usr/local/bin/common.sh

SERVER_DIR="$SEAFILE_ROOT_DIR"/$(ls -1 "$SEAFILE_ROOT_DIR" | grep -E "seafile-server-[0-9.-]+")
EXPOSED_DIRS="conf ccnet logs seafile-data seahub-data"
EXPOSED_ROOT_DIR=${EXPOSED_ROOT_DIR:-"/seafile"}
REVERSE_PROXY_MODE=$(echo "$REVERSE_PROXY_MODE" |  tr '[:upper:]' '[:lower:]')
SERVER_ADDRESS=${SERVER_ADDRESS:-"127.0.0.1"}


setup_seahub() {
    log_info "Configuring seahub server"

    # From https://github.com/haiwen/seafile-server-installer-cn/blob/master/seafile-server-ubuntu-14-04-amd64-http
    sed -i 's/= ask_admin_email()/= '"\"${SEAFILE_ADMIN}\""'/' ${SERVER_DIR}/check_init_admin.py
    sed -i 's/= ask_admin_password()/= '"\"${SEAFILE_ADMIN_PASSWORD}\""'/' ${SERVER_DIR}/check_init_admin.py

    seafile start
    seahub start
    seahub stop
    seafile stop

    log_info "Seahub server is successfully configured"
}

setup_exposed_directories() {
    log_info "Creating exposed directories"
    for EXPOSED_DIR in $EXPOSED_DIRS
    do
        if [[ -d $SEAFILE_ROOT_DIR/$EXPOSED_DIR ]]; then
            mv "$SEAFILE_ROOT_DIR/$EXPOSED_DIR" "$EXPOSED_ROOT_DIR"
        else
            mkdir "$EXPOSED_ROOT_DIR/$EXPOSED_DIR"
        fi
        ln -sf "$EXPOSED_ROOT_DIR/$EXPOSED_DIR" "$SEAFILE_ROOT_DIR/$EXPOSED_DIR"
    done
}

is_new_install() {
    DIR_COUNTER=0
    MISSING_DIR=""
    for EXPOSED_DIR in $EXPOSED_DIRS
    do
        if [[ -d "$EXPOSED_ROOT_DIR/$EXPOSED_DIR" ]]; then
            DIR_COUNTER=$((DIR_COUNTER + 1))
        else
            MISSING_DIR="$MISSING_DIR $EXPOSED_DIR"
        fi
    done
    if [[ $DIR_COUNTER -gt 0 && $DIR_COUNTER -lt $(wc -w <<<"$EXPOSED_DIRS") ]]; then
        log_error "Inconsistent state. Following directories are missing to restore previous install: $MISSING_DIR"
        exit 1
    fi
    return $DIR_COUNTER
}

restore_common_install() {
    log_info "Restoring previous install"
    for EXPOSED_DIR in $EXPOSED_DIRS
    do
        ln -sf "$EXPOSED_ROOT_DIR/$EXPOSED_DIR" "$SEAFILE_ROOT_DIR/$EXPOSED_DIR"
    done
    ln -sf "$SERVER_DIR" "$LATEST_SERVER_DIR"
    ln -sf "$EXPOSED_ROOT_DIR/seahub/media" "$LATEST_SERVER_DIR/seahub/media"
}


if [[ -n ${MYSQL_SERVER//[[:blank:]]/} ]]; then
    source /usr/local/bin/install/seafile_mysql.sh
else
    source /usr/local/bin/install/seafile_sqlite.sh
fi

if [[ ! -e $LATEST_SERVER_DIR ]]; then
    if is_new_install; then
        check_require "SEAFILE_ADMIN" $SEAFILE_ADMIN
        check_require "SEAFILE_ADMIN_PASSWORD" $SEAFILE_ADMIN_PASSWORD
        setup_seafile
        setup_seahub
        setup_exposed_directories
        move_media_directory
    else
        restore_common_install
        restore_specific_install
    fi
fi

log_info "Starting additional configuration"
for conf in $(ls /usr/local/bin/config/*.sh)
do
    source "$conf"
done

log_info "All is Done"
log_info "Starting Seafile ..."
seafile start
seahub start


tail -f ${SEAFILE_ROOT_DIR}/logs/seafile.log
