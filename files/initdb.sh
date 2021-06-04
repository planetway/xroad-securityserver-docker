#!/bin/bash

# This script initlizes X-Road related databases
# https://github.com/nordic-institute/X-Road/blob/6.24.1/doc/Manuals/ug-ss_x-road_6_security_server_user_guide.md#20-migrating-to-remote-database-host

set -e

# static variables
script_path="$( cd "$(dirname "$0")" ; pwd -P )"

# include libaries
libraries="helper_libs.sh"
for l in $libraries; do
  # shellcheck source=./files/libs/helper_libs.sh
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
