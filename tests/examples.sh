#!/bin/bash

set -e

# verbose logging
[[ $PX_VERBOSE_TEST ]] && set -x

cd $(dirname "$0")

function log () {
  echo -e "$(date "+%Y-%m-%d %H:%M:%S") $*" >&2
}

function clean () {
  docker-compose down -v 1>/dev/null 2>&1 
}

function wait_healthy () {
  local name=$1
  local n=0
  # can wait max 10 x 30 seconds
  local max_retries=10
  local sleep_interval=30

  until [ $n -ge $max_retries ]; do
    if docker ps --filter "name=${name}" --format "{{.Names}} {{.Status}}" | grep "healthy"; then
      log "Healthy"
      break
    fi
    log "Not healthy yet, retrying after $sleep_interval seconds"
    n=$((n+1))
    sleep $sleep_interval
  done

  if [ $n -eq $max_retries ]; then
    log "Retry max exceeded"
    exit 1
  fi
}

log "Testing examples/single..."
cd ../examples/single
log "Cleaning up first"
clean
log "docker-compose up in background"
docker-compose up 1>/dev/null 2>&1 &
log "Waiting for the SS to become healthy"
wait_healthy "single_ss01_1"
log "Cleaning up"
clean
log "Successfully finished"
