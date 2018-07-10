#!/bin/bash

source /usr/local/bin/common.sh

setup_seafile(){
    log_info "Configuring seafile server with Sqlite"
    "$SERVER_DIR"/setup-seafile.sh auto \
                                -n "${SERVER_NAME:-"seafile"}" \
                                -i "${SERVER_ADDRESS}" \
                                -p 8082
    mkdir -p "$EXPOSED_ROOT_DIR/sqlite"
    mv "$SEAFILE_ROOT_DIR/seahub.db" "$EXPOSED_ROOT_DIR/sqlite/seahub.db"
    ln -sf "$EXPOSED_ROOT_DIR/sqlite/seahub.db" "$SEAFILE_ROOT_DIR/seahub.db"
    log_info "Successfully configured Seafile server with Sqlite"
}

restore_specific_install() {
    if [[ -f "$EXPOSED_ROOT_DIR/sqlite/seahub.db" ]]; then
        ln -sf "$EXPOSED_ROOT_DIR/sqlite/seahub.db" "$SEAFILE_ROOT_DIR/seahub.db"
    else
        log_error "seahub.db is missing"
        exit 1
    fi
}