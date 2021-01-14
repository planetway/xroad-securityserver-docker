#!/bin/bash

# static variables
script_path="$( cd "$(dirname "$0")" ; pwd -P )"
work_path=/etc/xroad/signer
autologin_file=/etc/xroad/autologin
enrollment_status_file=/etc/xroad/signer/enrollment.status
ca_enrollment_endpoint=https://enroll.test.planetcross.net
# default values for demo purpose, can be overwritten with container environment variable
PX_MEMBER_CODE=${PX_MEMBER_CODE:-0170121212121}
PX_MEMBER_CLASS=${PX_MEMBER_CLASS:-COM}
PX_MEMBER_ENROLLMENT_PASSWORD=${PX_MEMBER_ENROLLMENT_PASSWORD:-66705b9ce583ffb9c7092844198f20706ee4d644b8a29413ee169feefe36221942801a6ee66d8630f46f7243bbd9c04020391b56d081cc0fd9ad5e5b5d03708}

# include libaries
libraries="helper_libs.sh xroad_libs.sh"
for l in $libraries; do
  . "$script_path/libs/$l"
    test $? -ne 0 &&\
      echo "failed loading $l from '$l'" &&\
      exit 1
done

# check enrollment status file
if [ -f $enrollment_status_file ]; then
  log "security server already enrolled"
  exit 0
fi

# check for autologin file
if [ -s $autologin_file ]; then
  software_token_pin=$(cat $autologin_file)
else
  log "autologin file not found (PX_TOKEN_PIN not set?) or is empty, exiting"
  exit 1
fi

# check for mandatory variables
if [ -z $PX_INSTANCE ] || [ -z $PX_MEMBER_CLASS ] || [ -z $PX_MEMBER_CODE ]; then
  log "variables PX_INSTANCE, PX_MEMBER_CLASS or PX_MEMBER_CODE is unset, exiting"
  exit 1
fi

# set work path
cd $work_path

# start required processes
start_xroad_process xroad-confclient configuration-client.jar 5675
start_xroad_process xroad-signer signer.jar 5558

# initialize and log in to token
initialize_software_token $software_token_pin
log_in_to_software_token $software_token_pin

# generate keys
generate_key auth-${PX_MEMBER_CODE}
generate_key sign-${PX_MEMBER_CODE}

# generate certificate signing requests
generate_csr auth-${PX_MEMBER_CODE}
generate_csr sign-${PX_MEMBER_CODE}

# request certificates from CA
request_certificate auth-${PX_MEMBER_CODE} $ca_enrollment_endpoint auth-${PX_MEMBER_CODE} $PX_MEMBER_ENROLLMENT_PASSWORD
request_certificate sign-${PX_MEMBER_CODE} $ca_enrollment_endpoint sign-${PX_MEMBER_CODE} $PX_MEMBER_ENROLLMENT_PASSWORD

# import certificates
import_auth_certificate auth-${PX_MEMBER_CODE}
import_sign_certificate sign-${PX_MEMBER_CODE}

# create enrollment status file
## we expect a successfull enrollment without further checks because because shell has `-e` option set in entrypoint.sh
log "enrollment successfull, creating status file"
touch $enrollment_status_file

# stop processes
stop_xroad_process xroad-signer signer.jar
stop_xroad_process xroad-confclient configuration-client.jar
