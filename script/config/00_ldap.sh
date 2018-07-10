#!/bin/bash

source /usr/local/bin/common.sh

if [[ -n ${LDAP_URL//[[:blank:]]/} ]]; then
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