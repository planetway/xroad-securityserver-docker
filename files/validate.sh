#!/bin/bash

set -e

# static variables
script_path="$( cd "$(dirname "$0")" || exit ; pwd -P )"

# include libaries
libraries="helper_libs.sh"
for l in $libraries; do
  # shellcheck source=./files/libs/helper_libs.sh
  . "$script_path/libs/$l"
    test $? -ne 0 &&\
      echo "failed loading $l from '$l'" &&\
      exit 1
done

if [[ "$PX_ENROLL" = "true" ]]; then
  if [[ "$PX_INSTANCE" != "JP-TEST" ]]; then
      log "PX_ENROLL is only available in JP-TEST environment, either set PX_ENROLL to false or try in JP-TEST environment"
      exit 1
  fi

  # check for mandatory variables
  if [ -z "$PX_TOKEN_PIN" ] || [ -z "$PX_INSTANCE" ] || [ -z "$PX_MEMBER_CLASS" ] || [ -z "$PX_MEMBER_CODE" ] || [ -z "$PX_ADMINUI_USER" ] || [ -z "$PX_ADMINUI_PASSWORD" ] || [ -z "$PX_SS_PUBLIC_ENDPOINT" ] ; then
    log "One of PX_TOKEN_PIN, PX_INSTANCE, PX_MEMBER_CLASS, PX_MEMBER_CODE, PX_ADMINUI_USER, PX_ADMINUI_PASSWORD or PX_SS_PUBLIC_ENDPOINT is unset, all of these are required to enroll"
    exit 1
  fi
fi

if [[ $PX_SS_PUBLIC_ENDPOINT == *"/"* ]]; then
  # includes /
  log "PX_SS_PUBLIC_ENDPOINT should be set to a public domain or a global IP, and should not include \"http\" or /"
  exit 1
fi
