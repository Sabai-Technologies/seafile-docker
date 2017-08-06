#!/bin/bash

. /usr/local/bin/seafile_env.sh

EXPOSED_DIRS="conf ccnet logs seafile-data seahub-data"
EXPOSED_ROOT_DIR=${EXPOSED_ROOT_DIR:-"/seafile"}

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

setup_seafile(){
	log_info "Configuring seafile server"
	check_require "SEAFILE_ADMIN" $SEAFILE_ADMIN
	check_require "SEAFILE_ADMIN_PASSWORD" $SEAFILE_ADMIN_PASSWORD

	"$SERVER_DIR"/setup-seafile-mysql.sh auto \
	    -n "${SERVER_NAME:-"seafile"}" \
	    -i "${SERVER_ADDRESS:-"127.0.0.1"}" \
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
	fastcgi_conf
}

setup_seahub(){
	log_info "Configuring seahub server"
	# From https://github.com/haiwen/seafile-server-installer-cn/blob/master/seafile-server-ubuntu-14-04-amd64-http
	sed -i 's/= ask_admin_email()/= '"\"${SEAFILE_ADMIN}\""'/' ${SERVER_DIR}/check_init_admin.py
	sed -i 's/= ask_admin_password()/= '"\"${SEAFILE_ADMIN_PASSWORD}\""'/' ${SERVER_DIR}/check_init_admin.py

	# Start and stop Seafile to generate the admin user.
	control_seafile "start"
	control_seahub "start"
 	sleep 2
 	control_seahub "stop"
	sleep 1
	control_seafile "stop"
	log_info "Seahub server is successfully configured"
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

check_required_params() {
	log_info "Checking required params"
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

move_media_directory() {
    log_info "Moving seahub/media directory in root exposed directory"
    mkdir "$EXPOSED_ROOT_DIR/seahub"
    mv "$LATEST_SERVER_DIR/seahub/media" "$EXPOSED_ROOT_DIR/seahub/"
    CUR_DIR=$(pwd)
    cd "$EXPOSED_ROOT_DIR/seahub/media"
    ln -sf ../../seahub-data/avatars .
    cd $CUR_DIR
    ln -sf "$EXPOSED_ROOT_DIR/seahub/media" "$LATEST_SERVER_DIR/seahub/media"
}

fastcgi_conf() {
    log_info "Updating configuration for FASTCGI mode"
    if [[ $FASTCGI = [Tt]rue ]];then
        echo "FILE_SERVER_ROOT = 'http://$SERVER_ADDRESS/seafhttp'" >> $EXPOSED_ROOT_DIR/conf/seahub_settings.py
    fi
}

is_new_install(){
	DIR_COUNTER=0
	MISSING_DIR=""
	for EXPOSED_DIR in $EXPOSED_DIRS
	do
		if [[ -d "$EXPOSED_ROOT_DIR/$EXPOSED_DIR" ]]; then
			DIR_COUNTER=$((DIR_COUNTER+1))
		else
			MISSING_DIR="$MISSING_DIR $EXPOSED_DIR"
		fi
	done
	if [[ $DIR_COUNTER -gt 0 && $DIR_COUNTER -lt $(wc -w <<< "$EXPOSED_DIRS") ]]; then
		log_error "Inconsistent state. Following directories are missing to restore previous install: $MISSING_DIR"
        exit 1
	fi
	return $DIR_COUNTER
}

restore_install(){
	log_info "Restoring previous install"
	link_exposed_directories
	ln -sf "$SERVER_DIR" "$LATEST_SERVER_DIR"
    ln -sf "$EXPOSED_ROOT_DIR/seahub/media" "$LATEST_SERVER_DIR/seahub/media"

    if [[ $FASTCGI = [Tt]rue ]];then
        if ! grep -qE '^FILE_SERVER_ROOT' "$EXPOSED_ROOT_DIR/conf/seahub_settings.py";then
            fastcgi_conf
        fi
    else
        sed -i '/^FILE_SERVER_ROOT/ d' "$EXPOSED_ROOT_DIR/conf/seahub_settings.py"
    fi
}

control_seafile() {
	"$SERVER_DIR"/seafile.sh "$@"
}

control_seahub() {
	"$SERVER_DIR"/seahub.sh "$@"
}

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

if [[ ! -e $LATEST_SERVER_DIR ]]; then
	wait_for_db
	check_required_params
	if is_new_install; then
		setup_seafile
	else
	    restore_install
	fi
	log_info "All is Done"
	log_info "Starting Seafile ..."
fi

exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
