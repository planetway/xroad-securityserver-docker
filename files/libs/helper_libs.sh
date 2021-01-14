#!/usr/bin/env bash
# helper libs
#
# meant to be source loaded
# e.g.
#   . ./helper_libs.sh

#
# functions
log() {
  pwd=$(pwd)
  echo -e "$(date "+%Y-%m-%d %H:%M:%S,%3N") $@" >&2
}

check() {
  if test $1 -ne 0
  then
    log "$2"
    exit 1
  fi
}

warn () {
    echo "$0:" "$@" >&2
}

die () {
    rc=$1
    shift
    warn "$@"
    exit $rc
}

check_postgres () {
    log "Waiting for Postgres"
    local checkdb_user=${PX_CHECKDB_USER:-$POSTGRES_USER}
    local checkdb_user=${checkdb_user:-postgres}
    local checkdb_password=${PX_CHECKDB_PASSWORD:-$POSTGRES_PASSWORD}
    until PGPASSWORD=$checkdb_password psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $checkdb_user -d postgres -c '\q' > /dev/null 2>&1; do
        >&2 log "Postgres is unavailable - waiting"
        sleep 1
    done
    >&2 log "Postgres is up"
}

# done
echo -n
