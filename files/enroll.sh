#!/bin/bash

# verbose logging
[[ $PX_TRACE_ENROLL ]] && set -x

# static variables
script_path="$( cd "$(dirname "$0")" || exit ; pwd -P )"
work_path=/etc/xroad/signer
autologin_file=/etc/xroad/autologin
ca_enrollment_endpoint=https://enroll.test.conneqt.net
# default values for demo purpose, can be overwritten with container environment variable
PX_MEMBER_CODE=${PX_MEMBER_CODE:-0170121212121}
PX_MEMBER_CLASS=${PX_MEMBER_CLASS:-COM}
PX_MEMBER_ENROLLMENT_PASSWORD=${PX_MEMBER_ENROLLMENT_PASSWORD:-66705b9ce583ffb9c7092844198f20706ee4d644b8a29413ee169feefe36221942801a6ee66d8630f46f7243bbd9c04020391b56d081cc0fd9ad5e5b5d03708}

# include libaries
libraries="helper_libs.sh xroad_libs.sh"
for l in $libraries; do
  # shellcheck source=./files/libs/helper_libs.sh
  # shellcheck source=./files/libs/xroad_libs.sh
  . "$script_path/libs/$l"
    test $? -ne 0 &&\
      echo "failed loading $l from '$l'" &&\
      exit 1
done

# set work path
cd $work_path || exit

# start required processes
start_xroad_process xroad-confclient configuration-client.jar 5675
start_xroad_process xroad-signer signer.jar 5558
start_xroad_process xroad-proxy-ui-api proxy-ui-api.jar 4000

# create api key to setup security server over https
create_api_key "$PX_ADMINUI_USER" "$PX_ADMINUI_PASSWORD"

# initialize and log in to token
initialize_security_server

add_timestamping_service

token_login

# generate keys and csrs
generate_key_and_csr auth
generate_key_and_csr sign

# request certificates from CA
request_certificate auth "$ca_enrollment_endpoint" "$PX_MEMBER_ENROLLMENT_PASSWORD"
request_certificate sign "$ca_enrollment_endpoint" "$PX_MEMBER_ENROLLMENT_PASSWORD"

# imports sign certificate
import_certificate sign
# imports auth certificate, activates and registers it
import_certificate auth

# Destroy api key, done seting up the security server
destroy_api_key "$PX_ADMINUI_USER" "$PX_ADMINUI_PASSWORD"

# stop processes
stop_xroad_process xroad-signer signer.jar
stop_xroad_process xroad-confclient configuration-client.jar
stop_xroad_process xroad-proxy-ui-api proxy-ui-api.jar
