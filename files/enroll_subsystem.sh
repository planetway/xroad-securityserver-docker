#!/bin/bash

# positional arguments
PX_MEMBER_CODE=$1
PX_MEMBER_ENROLLMENT_PASSWORD=$2

# static variables
script_path="$( cd "$(dirname "$0")" ; pwd -P )"
work_path=/etc/xroad/signer
ca_enrollment_endpoint=https://enroll.test.planetcross.net

# include libaries
libraries="helper_libs.sh xroad_libs.sh"
for l in $libraries; do
  . "$script_path/libs/$l"
    test $? -ne 0 &&\
      echo "failed loading $l from '$l'" &&\
      exit 1
done

# check for mandatory variables
if [ -z $PX_INSTANCE ] || [ -z $PX_MEMBER_CLASS ] || [ -z $PX_MEMBER_CODE ]; then
  log "variables PX_INSTANCE, PX_MEMBER_CLASS or PX_MEMBER_CODE is unset, exiting"
  exit 1
fi

# set work path
cd $work_path

# generate keys
generate_key sign-${PX_MEMBER_CODE}

# generate certificate signing requests
generate_csr sign-${PX_MEMBER_CODE}

# request certificates from CA
request_certificate sign-${PX_MEMBER_CODE} $ca_enrollment_endpoint sign-${PX_MEMBER_CODE} $PX_MEMBER_ENROLLMENT_PASSWORD

# import certificates
import_sign_certificate sign-${PX_MEMBER_CODE}
