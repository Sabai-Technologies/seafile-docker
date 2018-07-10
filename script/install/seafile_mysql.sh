#!/bin/bash

source /usr/local/bin/common.sh

wait_for_mysql() {
    log_info "Trying to connect to the DB server"
    DOCKERIZE_TIMEOUT=${DOCKERIZE_TIMEOUT:-"60s"}
    dockerize -timeout ${DOCKERIZE_TIMEOUT} -wait tcp://${MYSQL_SERVER}:${MYSQL_PORT:-3306}
    if [[ $? -ne 0 ]]; then
        log_error "Cannot connect to the DB server"
        exit 1
    fi
    log_info "Successfully connected to the DB server"
}

setup_seafile() {
    check_require "MYSQL_SERVER" $MYSQL_SERVER
    check_require "MYSQL_ROOT_PASSWORD" $MYSQL_ROOT_PASSWORD
    check_require "MYSQL_USER" $MYSQL_USER
    check_require "MYSQL_USER_PASSWORD" $MYSQL_USER_PASSWORD

    wait_for_mysql

    log_info "Configuring seafile server with MySQL"
    "$SERVER_DIR"/setup-seafile-mysql.sh auto \
                                     -n "${SERVER_NAME:-"seafile"}" \
                                     -i "${SERVER_ADDRESS}" \
                                     -p 8082 \
                                     -e 0 \
                                     -o "${MYSQL_SERVER}" \
                                     -t "${MYSQL_PORT:-3306}" \
                                     -r "${MYSQL_ROOT_PASSWORD}" \
                                     -u "${MYSQL_USER}" \
                                     -w "${MYSQL_USER_PASSWORD}" \
                                     -q "%" \
                                     -c "${MYSQL_CCNET_DB:-"ccnet-db"}" \
                                     -s "${MYSQL_SEAFILE_DB:-"seafile-db"}" \
                                     -b "${MYSQL_SEAHUB_DB:-"seahub-db"}"

    log_info "Successfully configured Seafile server with MySQL"
}

restore_specific_install() {
    wait_for_mysql
}