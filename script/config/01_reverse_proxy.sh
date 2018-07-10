#!/bin/bash

source /usr/local/bin/common.sh

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
    log_info "Reverse proxy is not configured"
    crudini --set $EXPOSED_ROOT_DIR/conf/ccnet.conf General SERVICE_URL "http://$SERVER_ADDRESS:8000"
    crudini --del $EXPOSED_ROOT_DIR/conf/seafile.conf fileserver host
    sed -i '/^FILE_SERVER_ROOT/d' "$EXPOSED_ROOT_DIR/conf/seahub_settings.py"
fi