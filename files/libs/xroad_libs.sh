#!/usr/bin/env bash
# xroad libs
#
# meant to be source loaded
# e.g.
#   . ./xroad_libs.sh

#
# functions

function create_api_key () {
  local user=$1
  local password=$2

  created_api_key=($(curl -s -k -X POST -u $user:$password \
    --data \
    '["XROAD_SECURITY_OFFICER",
    "XROAD_REGISTRATION_OFFICER",
    "XROAD_SERVICE_ADMINISTRATOR",
    "XROAD_SYSTEM_ADMINISTRATOR",
    "XROAD_SECURITYSERVER_OBSERVER"]' \
    --header "Content-Type: application/json" \
    "https://localhost:4000/api/v1/api-keys" | jq -r -c '.id,.key'))

  if [[ -z $created_api_key ]] ; then
    log "Warning, API key request failed, exiting"
    exit 1
  else
    log "API key request successful"
  fi
}

function destroy_api_key () {
  local user=$1
  local password=$2
  local api_key_id=${created_api_key[0]}

  log "Destroying API key ${api_key}"

  curl -s -k -X DELETE -u ${user}:${password} \
    "https://localhost:4000/api/v1/api-keys/${api_key_id}"
}

function generate_csr () {
  local type=$1
  local id=$(readlink $type|cut -d . -f "1")

  # create csr if symlink to csr doesn't exist, set key type from $type first character
  if [ ! -f ${id}.csr ]; then
    log "generating certificate signing request for $type"
    signer_console generate-cert-request ${id} \"$PX_INSTANCE $PX_MEMBER_CLASS $PX_MEMBER_CODE\" "${type:0:1}" "C=${PX_INSTANCE},O=${PX_MEMBER_CLASS},CN=${PX_MEMBER_CODE}" pem > /dev/null
  else
    log "certificate signing request for $type exists"
  fi
}

function generate_key () {
  local type=$1

  # create key if symlink to container doesn't exist
  if [ ! -L ${type} ]; then
    log "creating $type key"
    signer_console generate-key 0 \"${type} key\" > /tmp/generate-key.log
    # retrieve the keyId logged in stdout
    id=$(cat /tmp/generate-key.log | grep "keyLabel" | jq -r .message | jq -r .data.keyId)
    ln -s ${id}.p12 ${type}
  else
    log "$type key exists"
  fi
}

function import_auth_certificate () {
  local id=$(readlink $1|cut -d . -f "1")

  # import certificate if not already imported
  if [ ! "$(signer_console list-certs | grep -A 1 ${id}|grep saved)" ]; then
    log "importing auth certificate as saved state"
    signer_console import-certificate-saved ${id}.crt \"$PX_INSTANCE $PX_MEMBER_CLASS $PX_MEMBER_CODE\" > /tmp/signer_console.log
    # signer_console exit code is always 0 :(
    if [ "$(cat /tmp/signer_console.log | grep ERROR)" ]; then
      cat /tmp/signer_console.log
      exit 1
    fi
  else
    log "auth certificate already imported"
  fi
}

function import_sign_certificate () {
  local id=$(readlink $1|cut -d . -f "1")

  # import certificate if not already imported
  if [ ! "$(signer_console list-certs | grep -A 1 ${id}|grep registered)" ]; then
    log "importing sign certificate"
    signer_console import-certificate ${id}.crt \"$PX_INSTANCE $PX_MEMBER_CLASS $PX_MEMBER_CODE\" > /tmp/signer_console.log
    # signer_console exit code is always 0 :(
    if [ "$(cat /tmp/signer_console.log | grep ERROR)" ]; then
      cat /tmp/signer_console.log
      exit 1
    fi
  else
    log "sign certificate already imported"
  fi
}

# subfunction to initialize token with expect
# short password will cause Signer.TokenPinPolicyFailure
# we're expecting {"event":"Initialize the software token",...}
function expect_initialize_software_token() {
  local pin=$1
  export -f signer_console

  expect -c "proc abort {} {
               puts Aborted
               exit 1
             }
             spawn /bin/bash -c { signer_console init-software-token };
             expect 'PIN: ';
             send \"$pin\r\";
             expect 'retype PIN: ';
             send \"$pin\r\";
             expect {
                \"token initialization failed\" abort
                \"Signer.TokenPinPolicyFailure\" abort
                \"\\\"event\\\":\\\"Initialize the software token\\\"\"
             }
             "
}

function initialize_software_token() {
  local pin=$1
  export -f signer_console

  if [ "$(signer_console list-tokens|grep OK)" ]; then
    log "software token already initialized"
  else
    output=$(expect_initialize_software_token $pin)
    expect_exit=$?
    if [ $expect_exit -eq 0 ]; then
      log "software token initialized"
    else
      log "software token initialization failed\n$output"
      exit 1
    fi
  fi
}

function log_in_to_software_token () {
  local pin=$1
  export -f signer_console

  function expect_log_in_to_software_token() {
    expect  \
            -c "log_user 0;
                spawn /bin/bash -c { signer_console login-token 0 };
                expect -re \"PIN\";
                send \"$pin\r\";
                expect -re \"xroad\""
  }

  if [ "$(signer_console list-tokens|grep inactive)" ]; then
    expect_log_in_to_software_token $pin
  fi

  log "logged in to software token"
}

function register_authentication_certificate () {
  local api_key=${created_api_key[1]}
  local curl_args=('-H' 'accept: application/json' '-H' "Authorization: X-Road-ApiKey token=$api_key")
  local tokens=$(curl -s -k -X GET "${curl_args[@]}" "https://localhost:4000/api/v1/tokens")

  local certificate_hash=$(echo $tokens \
    | jq -r -c '.[].keys[] | select ( .usage
    | contains("AUTHENTICATION")).certificates[].certificate_details.hash')
  local certificate_status=$(echo $tokens \
    | jq -r -c '.[].keys[] | select ( .usage
    | contains("AUTHENTICATION")).certificates[].status')

  # Possible registration states are REGISTRATION_IN_PROGRESS, REGISTERED
  if [[ "${certificate_status}" == "SAVED" ]]; then
    log "Activating and registering authentication certificate"
    curl -s -k -X PUT \
      "${curl_args[@]}" \
      "https://localhost:4000/api/v1/token-certificates/${certificate_hash}/activate"
    curl -s -k -X PUT \
      "${curl_args[@]}" \
      -H 'Content-Type: application/json' \
      -d "{\"address\":\"${PX_SS_PUBLIC_ENDPOINT}\"}" \
      "https://localhost:4000/api/v1/token-certificates/${certificate_hash}/register"
  fi
}

function request_certificate () {
  local type=$1
  local ca_enrollment_endpoint=$2
  local username=$3
  local password=$4
  local id=$(readlink $type|cut -d . -f "1")

  # request certificate if it doesn't exists
  if [ ! -f ${id}.crt ]; then
    log "requesting $type certificate"
    # curl -k allows untrusted HTTPS connection.
    # Flag must be removed before release when EJBCA endpoint is available from public internet with a trusted certificate.
    curl -s -L $ca_enrollment_endpoint \
         --form-string user=$username \
         --form-string password=$password \
         -F "pkcs10req=
         $(cat ${id}.csr)
         " \
         --form-string 'resulttype=4' > ${id}.crt # resulttype 4 returns full chain
    # Validate certificate with openssl
    openssl x509 -noout -in ${id}.crt 2> /dev/null
    # Check openssl status code, exit on failure
    check $? "certificate request from certification authority failed"
  else
    log "$type certificate already requested"
  fi
}

function signer_console () {
  # we define signer_console function, because singer-console uses rlwrap.
  # rlwrap fails with "rlwrap: error: My terminal reports width=0" at docker entrypoint
  . /etc/xroad/services/signer-console.conf
  java ${SIGNER_CONSOLE_PARAMS} ${XROAD_PARAMS} -jar /usr/share/xroad/jlib/signer-console.jar "$@"
}

function start_xroad_process () {
  local start_script=$1
  local java_archive=$2
  local port=$3

  # start process if not running
  if ! pgrep -f $java_archive > /dev/null; then
    log "starting $start_script"
    /usr/share/xroad/bin/${start_script} > /dev/null 2>&1 &
  fi

  # wait for listening state of process
  until [ "$(ss -lnt|grep $port)" ]; do
    sleep 0.5
  done
  log "$1 running"
}

function stop_xroad_process () {
  local start_script=$1
  local java_archive=$2

  # stop process if running
  if pgrep -f $java_archive > /dev/null; then
    log "stopping $start_script"
    pkill -f $java_archive
  fi
}

# done
echo -n
