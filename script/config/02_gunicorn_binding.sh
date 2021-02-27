#!/bin/bash

source /usr/local/bin/common.sh
log_info "Configuring Gurnicorn binding"
sed -i 's/127.0.0.1/0.0.0.0/g' "$EXPOSED_ROOT_DIR/conf/gunicorn.conf.py"
