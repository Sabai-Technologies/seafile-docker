#!/bin/bash

. /usr/local/bin/env.sh

EXPOSED_DIRS="ccnet conf logs seafile-data seahub-data"
EXPOSED_ROOT_DIR=${EXPOSED_ROOT_DIR:-"/seafile"}

setup_seafile(){
	echo "Setting up seafile server ..."
	check_require "MYSQL_SERVER" $MYSQL_SERVER
	check_require "MYSQL_ROOT_PASSWORD" $MYSQL_ROOT_PASSWORD
	check_require "MYSQL_USER" $MYSQL_USER
	check_require "MYSQL_USER_PASSWORD" $MYSQL_USER_PASSWORD
	check_require "SEAFILE_ADMIN" $SEAFILE_ADMIN
	check_require "SEAFILE_ADMIN_PASSWORD" $SEAFILE_ADMIN_PASSWORD

	"$SERVER_DIR"/setup-seafile-mysql.sh auto \
	    -n "${SERVER_NAME:-"seafile"}" \
	    -i "127.0.0.1" \
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
	    -b "${SEAHUB_DB:-"seahub-db"}" \

	echo "Setting up seahub ..."
  setup_seahub

  echo "Create exposed directory ..."
  setup_exposed_directories
}

setup_seahub(){
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
}

wait_for_db() {
	DOCKERIZE_TIMEOUT=${DOCKERIZE_TIMEOUT:-"60s"}
	dockerize -timeout ${DOCKERIZE_TIMEOUT} -wait tcp://${MYSQL_SERVER}:${MYSQL_PORT:-3306}
	if [[ $? -ne 0 ]]; then
		echo "Cannot connect to the DB server"
		exit 1
	fi
}

setup_exposed_directories() {
	for EXPOSED_DIR in $EXPOSED_DIRS
	do
		if [[ -e $SEAFILE_ROOT_DIR/$EXPOSED_DIR ]]; then
			if [[ ! -L  $SEAFILE_ROOT_DIR/$EXPOSED_DIR ]]; then
				mv "$SEAFILE_ROOT_DIR/$EXPOSED_DIR" "$EXPOSED_ROOT_DIR"
				ln -sf "$EXPOSED_ROOT_DIR/$EXPOSED_DIR" "$SEAFILE_ROOT_DIR/$EXPOSED_DIR"
			fi
		else
			mkdir "$EXPOSED_ROOT_DIR/$EXPOSED_DIR"
			ln -sf "$EXPOSED_ROOT_DIR/$EXPOSED_DIR" "$SEAFILE_ROOT_DIR/$EXPOSED_DIR"
		fi
	done
}

control_seafile() {
	"$SERVER_DIR"/seafile.sh "$@"
}

control_seahub() {
	"$SERVER_DIR"/seahub.sh "$@"
}

check_require() {
	if [[ -z ${2//[[:blank:]]/} ]]; then
		echo "$1 is require"
		exit 1
	fi
}


echo "Waiting for the DB server is up ..."
wait_for_db
echo "DB server OK"

echo "Installing Seafile ..."
if [[ ! -e $LATEST_SERVER_DIR ]]; then
	echo "Installing Seafile ..."
	setup_seafile
	echo "Installation done"
fi

exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
