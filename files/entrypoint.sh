#!/bin/bash

# Exit shell on failure
set -e

# static variables
script_path="$( cd "$(dirname "$0")" ; pwd -P )"

# include libaries
libraries="helper_libs.sh"
for l in $libraries; do
  . "$script_path/libs/$l"
    test $? -ne 0 &&\
      echo "failed loading $l from '$l'" &&\
      exit 1
done

log "Creating /var/lib/xroad/backup"
# BACKUP AND RESTORE screen expects this directory to exist
mkdir -p /var/lib/xroad/backup

# Slave node procedures
if [ "$PX_NODE_TYPE" = "secondary" ]; then
    log "Detected node type is secondary"
    log "Disabling messagelog records archiving, unnecessary processes"
    # Do not insert secondary.ini to local.ini if content is already there
    if ! grep -q -F -x -f /files/secondary.ini /etc/xroad/conf.d/local.ini; then
      cat files/secondary.ini >> /etc/xroad/conf.d/local.ini
    fi
    cp files/supervisor-secondary.conf /etc/supervisor/conf.d/xroad.conf
    cp files/node-secondary.ini /etc/xroad/conf.d/node.ini
else
    cp files/supervisor.conf /etc/supervisor/conf.d/xroad.conf
fi

if [ "$PX_INSTANCE" = "JP" ]; then
    cp /files/configuration_anchor_$PX_INSTANCE.xml /etc/xroad/configuration-anchor.xml
else
    cp /files/configuration_anchor_JP-TEST.xml /etc/xroad/configuration-anchor.xml
fi

# Create new internal certificates
if [ ! -f /etc/xroad/ssl/internal.key ]; then
    log "Generating new internal.[crt|key|p12] files"
    /usr/share/xroad/scripts/generate_certificate.sh -n internal -f -S -p
fi

# Create new certificates for proxy-ui-api, from xroad-proxy-ui-api-setup.sh
if [[ ! -r /etc/xroad/ssl/proxy-ui-api.crt || ! -r /etc/xroad/ssl/proxy-ui-api.key  || ! -r /etc/xroad/ssl/proxy-ui-api.p12 ]]
then
    log "Generating new proxy-ui-api.[crt|key|p12] files"
    rm -f /etc/xroad/ssl/proxy-ui-api.crt /etc/xroad/ssl/proxy-ui-api.key /etc/xroad/ssl/proxy-ui-api.p12

    HOST=$(hostname -f)
    LIST=
    for i in $(ip addr | grep 'scope global' | tr '/' ' ' | awk '{print $2}')
    do
        LIST+="IP:$i,";
    done
    ALT="${LIST}DNS:$(hostname),DNS:$HOSTNAME"

    /usr/share/xroad/scripts/generate_certificate.sh  -n proxy-ui-api -s "/CN=$HOST" -a "$ALT" -p 2> /tmp/cert.err || log "generate_certificate failed, see /tmp/cert.err!"
fi

# Create admin ui user
if [[ -n "${PX_ADMINUI_USER}" && -n "${PX_ADMINUI_PASSWORD}" || -e /run/secrets/adminui-user && -e /run/secrets/adminui-password ]]; then
    if [[ -e /run/secrets/adminui-user && -e /run/secrets/adminui-password ]]; then
        declare PX_ADMINUI_USER=$(cat /run/secrets/adminui-user)
        declare PX_ADMINUI_PASSWORD=$(cat /run/secrets/adminui-password)
    fi
    if useradd "$PX_ADMINUI_USER" -s /usr/sbin/nologin; then
        echo "$PX_ADMINUI_USER:$PX_ADMINUI_PASSWORD" | chpasswd
        declare -a groups=("xroad-security-officer" "xroad-registration-officer" "xroad-service-administrator" "xroad-system-administrator" "xroad-securityserver-observer")
        for i in "${groups[@]}"
        do
            usermod -aG "$i" "${PX_ADMINUI_USER}"
        done
        log "Created Admin UI user "${PX_ADMINUI_USER}""
    else
        log "Admin UI user already exists."
    fi
fi

if [ -n "$PX_TOKEN_PIN" ]; then
    log "PX_TOKEN_PIN variable set, writing to /etc/xroad/autologin"
    echo "$PX_TOKEN_PIN" > /etc/xroad/autologin
    unset PX_TOKEN_PIN
fi

envsubst < /files/db.properties.template    > /etc/xroad/db.properties
envsubst < /files/xroad.properties.template > /etc/xroad.properties
envsubst < /files/local.conf.template       > /etc/xroad/services/local.conf

# Any env variable with the prefix "PX_CONF_" will be written into local.conf, without the prefix.
# eg. "PX_CONF_PROXY_PARAMS=..." env variable will be written into local.conf as:
# PROXY_PARAMS="..."
perl /files/local.conf.pl >> /etc/xroad/services/local.conf

# Any env variable with the prefix "PX_INI_" will be written into local.ini, without the prefix.
# eg. "PX_INI_MESSAGELOG_A=128" env variable will be written into local.ini as:
# [message-log]
# a="128"
perl /files/local.ini.pl >> /etc/xroad/conf.d/local.ini

if [ "$PX_ENROLL" = true ]; then
  # Run enrollment script
  su xroad -c "/files/enroll.sh"
fi

# run the CMD
exec "$@"
