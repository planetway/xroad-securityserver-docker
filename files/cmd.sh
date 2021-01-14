#!/bin/bash

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

log "running supervisord"
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
