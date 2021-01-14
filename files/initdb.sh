#!/bin/bash

# This script initlizes X-Road related databases
# https://github.com/nordic-institute/X-Road/blob/6.24.1/doc/Manuals/ug-ss_x-road_6_security_server_user_guide.md#20-migrating-to-remote-database-host

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

check_postgres

log "Creating roles on remote database"

# entrypoint script has already ran, so the db.properties have the credentials
db_properties=/etc/xroad/db.properties

log "Running serverconf database migrations"

/usr/share/xroad/scripts/setup_serverconf_db.sh \
    || die -1 "Setting up serverconf has failed, please check database availability and configuration in ${db_properties} file"

log "Running opmonitor database migrations"

/usr/share/xroad/scripts/setup_opmonitor_db.sh \
    || die -1 "Setting up opmonitor has failed, please check database availability and configuration in ${db_properties} file"

log "Running messagelog database migrations"

/usr/share/xroad/scripts/setup_messagelog_db.sh \
    || die -1 "Connection messagelog has failed, please check database availability and configuration in ${db_properties} file"

serverconf () {
    PGPASSWORD=$PX_SERVERCONF_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U serverconf -d serverconf -c "$1"
}

if [[ -n "${PX_INSTANCE}" && -n "${PX_MEMBER_CLASS}" && -n "${PX_MEMBER_CODE}" && -n "${PX_SS_CODE}" && "${PX_POPULATE_DATABASE}" == "true" ]]
then
    log "Populating serverconf database"

    serverconf "INSERT INTO identifier VALUES ('1', 'C', 'MEMBER', '${PX_INSTANCE}','${PX_MEMBER_CLASS}','${PX_MEMBER_CODE}') ON CONFLICT (id) DO NOTHING"
    serverconf "INSERT INTO serverconf VALUES ('1', '${PX_SS_CODE}') ON CONFLICT (id) DO NOTHING"
    serverconf "INSERT INTO client VALUES ('1', '1', '1', 'saved', 'NOSSL') ON CONFLICT (id) DO NOTHING"
    serverconf "UPDATE serverconf SET owner=1 WHERE id=1 AND 0=(SELECT COUNT(*) FROM serverconf WHERE owner=1)"
    serverconf "INSERT INTO tsp VALUES ('1', '${PX_TSA_NAME}', '${PX_TSA_URL}', '1') ON CONFLICT (id) DO NOTHING"
else
    log "Skipping populating serverconf database"
fi
