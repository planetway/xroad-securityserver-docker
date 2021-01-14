#!/bin/bash

# This script checks if X-Road related databases have been initialized.
# https://github.com/nordic-institute/X-Road/blob/6.23.0/doc/Manuals/ug-ss_x-road_6_security_server_user_guide.md#19-migrating-to-remote-database-host

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

# Start database checks
check_postgres

log "Checking if all 3 databases exist"

serverconf_user=${PX_SERVERCONF_USER:-serverconf}
database_count=$(PGPASSWORD=$PX_SERVERCONF_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $serverconf_user -d postgres -t -A -c "SELECT count(datname) FROM pg_database WHERE datname IN ('messagelog', 'op-monitor', 'serverconf');")
if [ $database_count -ne 3 ]; then
  log "Some databases missing, found $database_count databases, exiting"
  exit
else
  log "Found $database_count databases, continuing"
fi

log "Checking for tsp table and relevant records"
set +e
tsp_count=$(PGPASSWORD=$PX_SERVERCONF_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $serverconf_user -d serverconf -t -A -c "SELECT count(id) FROM serverconf.tsp;" 2> /dev/null)

if [[ $? -ne 0 ]]; then
  log "tsp table check failed, table probably missing"
  exit 0
else
  if [[ $tsp_count -eq 0 ]]; then
    log "Records in tsp table missing"
    exit
  fi
fi

log "Database checks passed"
set -e
