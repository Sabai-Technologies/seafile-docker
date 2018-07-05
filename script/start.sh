#!/bin/bash

source /usr/local/bin/common.sh

SERVER_DIR="$SEAFILE_ROOT_DIR"/$(ls -1 "$SEAFILE_ROOT_DIR" | grep -E "seafile-server-[0-9.-]+")
EXPOSED_DIRS="conf ccnet logs seafile-data seahub-data"
EXPOSED_ROOT_DIR=${EXPOSED_ROOT_DIR:-"/seafile"}
REVERSE_PROXY_MODE=$(echo "$REVERSE_PROXY_MODE" |  tr '[:upper:]' '[:lower:]')
SERVER_ADDRESS=${SERVER_ADDRESS:-"127.0.0.1"}

setup_seafile() {
    log_info "Configuring seafile server"
    check_require "SEAFILE_ADMIN" $SEAFILE_ADMIN
    check_require "SEAFILE_ADMIN_PASSWORD" $SEAFILE_ADMIN_PASSWORD

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
        -c "${CCNET_DB:-"ccnet-db"}" \
        -s "${SEAFILE_DB:-"seafile-db"}" \
        -b "${SEAHUB_DB:-"seahub-db"}"

    log_info "Seafile server is successfully configured"
    setup_seahub
    setup_exposed_directories
    link_exposed_directories
    move_media_directory
}

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

config_ldap() {
    if [ -n "${LDAP_URL}" ]; then
        log_info "Configuring LDAP"
        check_require "LDAP_BASE" $LDAP_BASE
        check_require "LDAP_LOGIN_ATTR" $LDAP_LOGIN_ATTR
        crudini --set $EXPOSED_ROOT_DIR/conf/ccnet.conf LDAP HOST ${LDAP_URL}
        crudini --set $EXPOSED_ROOT_DIR/conf/ccnet.conf LDAP BASE ${LDAP_BASE}
        crudini --set $EXPOSED_ROOT_DIR/conf/ccnet.conf LDAP LOGIN_ATTR ${LDAP_LOGIN_ATTR}
        if [ -n "${LDAP_USER_DN}" ]; then
            crudini --set $EXPOSED_ROOT_DIR/conf/ccnet.conf LDAP USER_DN ${LDAP_USER_DN}
        else
            crudini --del $EXPOSED_ROOT_DIR/conf/ccnet.conf LDAP USER_DN
        fi
        if [ -n "${LDAP_PASSWORD}" ]; then
            crudini --set $EXPOSED_ROOT_DIR/conf/ccnet.conf LDAP PASSWORD ${LDAP_PASSWORD}
        else
            crudini --del $EXPOSED_ROOT_DIR/conf/ccnet.conf LDAP PASSWORD
        fi
        log_info "LDAP configured"
    else
        log_info "LDAP not configured"
        crudini --del $EXPOSED_ROOT_DIR/conf/ccnet.conf LDAP
    fi
}

config_reverse_proxy() {
    if [[ "$REVERSE_PROXY_MODE" =~ ^https?$ ]]; then
        log_info "Configuring reverse proxy"
		SERVICE_URL="$REVERSE_PROXY_MODE://$SERVER_ADDRESS"
		SEAFHTTP_URL=${SERVICE_URL//[\/]/\\/}"\/seafhttp"
        FILE_SERVER_IP=127.0.0.1
        crudini --set $EXPOSED_ROOT_DIR/conf/ccnet.conf General SERVICE_URL "$SERVICE_URL"
		sed -i \
			-e "/^\(FILE_SERVER_ROOT = \).*/{s//\1'$SEAFHTTP_URL'/;:a;n;:ba;q}" \
		    -e "\$aFILE_SERVER_ROOT = '$SEAFHTTP_URL'" \
            $EXPOSED_ROOT_DIR/conf/seahub_settings.py

        if [[ "$REVERSE_PROXY_MODE" == 'http' ]]; then
            FILE_SERVER_IP=0.0.0.0
        fi
        crudini --set $EXPOSED_ROOT_DIR/conf/seafile.conf fileserver host $FILE_SERVER_IP
    else
        log_info "Removing reverse proxy configuration"
        crudini --set $EXPOSED_ROOT_DIR/conf/ccnet.conf General SERVICE_URL "http://$SERVER_ADDRESS:8000"
        crudini --del $EXPOSED_ROOT_DIR/conf/seafile.conf fileserver host
		sed -i '/^FILE_SERVER_ROOT/d' "$EXPOSED_ROOT_DIR/conf/seahub_settings.py"
    fi
}

wait_for_db() {
    log_info "Trying to connect to the DB server"
    DOCKERIZE_TIMEOUT=${DOCKERIZE_TIMEOUT:-"60s"}
    dockerize -timeout ${DOCKERIZE_TIMEOUT} -wait tcp://${MYSQL_SERVER}:${MYSQL_PORT:-3306}
    if [[ $? -ne 0 ]]; then
        log_error "Cannot connect to the DB server"
        exit 1
    fi
    log_info "Successfully connected to the DB server"
}

validate_params() {
    log_info "Checking required params"

    if ! [[ -z "$REVERSE_PROXY_MODE" || "$REVERSE_PROXY_MODE" =~ ^https?$ ]]; then
        log_error "REVERSE_PROXY_MODE parameter must be empty or equals to 'HTTP' or 'HTTPS'"
        exit 1
    fi
    check_require "MYSQL_SERVER" $MYSQL_SERVER
    check_require "MYSQL_ROOT_PASSWORD" $MYSQL_ROOT_PASSWORD
    check_require "MYSQL_USER" $MYSQL_USER
    check_require "MYSQL_USER_PASSWORD" $MYSQL_USER_PASSWORD
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
    done
}

link_exposed_directories() {
    for EXPOSED_DIR in $EXPOSED_DIRS
    do
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

restore_install() {
    log_info "Restoring previous install"
    link_exposed_directories
    ln -sf "$SERVER_DIR" "$LATEST_SERVER_DIR"
    ln -sf "$EXPOSED_ROOT_DIR/seahub/media" "$LATEST_SERVER_DIR/seahub/media"
}

check_require() {
    if [[ -z ${2//[[:blank:]]/} ]]; then
        log_error "$1 is required"
        exit 1
    fi
}

wait_for_db

if [[ ! -e $LATEST_SERVER_DIR ]]; then
    validate_params
    if is_new_install; then
        setup_seafile
    else
        restore_install
    fi
fi

config_ldap
config_reverse_proxy

log_info "All is Done"
log_info "Starting Seafile ..."
seafile start
seahub start

tail -f ${SEAFILE_ROOT_DIR}/logs/seafile.log
