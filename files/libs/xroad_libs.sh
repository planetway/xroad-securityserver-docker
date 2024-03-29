#!/usr/bin/env bash
# xroad libs
#
# meant to be source loaded
# e.g.
#   . ./xroad_libs.sh

Q_CERTS_FOLDER=/etc/xroad/signer

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
    log "Error, API key request failed, exiting"
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

function request_api () {
  local verb=$1
  local path=$2
  local body=$3

  local api_key=${created_api_key[1]}
  local curl_args=('-H' 'Content-Type: application/json' '-H' "Authorization: X-Road-ApiKey token=$api_key")
  api_response=$(curl -s -k -i -X $verb --data "$body" "${curl_args[@]}" "https://localhost:4000/api/v1$path")
  api_response_status_code=$(echo -e "${api_response}"|head -n 1|cut -d$' ' -f2)
  api_response_body=$(echo -e "${api_response}"|tail -n 1)
}

function initialize_security_server_post() {
  local software_token_pin=$(cat $autologin_file)
  local tpl='{
  "owner_member_class": "%s",
  "owner_member_code": "%s",
  "security_server_code": "%s",
  "software_token_pin": "%s",
  "ignore_warnings": true
}'
  local data
  printf -v data "$tpl" "$PX_MEMBER_CLASS" "$PX_MEMBER_CODE" "$PX_SS_CODE" "$software_token_pin"
  # creates entries in serverconf db, initializes software token and does token login
  request_api POST /initialization "$data"
}

function initialize_security_server_try() {
  request_api GET "/initialization/status"
  if [ $api_response_status_code = 200 ]; then
    # this is used in the caller function
    software_token_init_status=$(echo $api_response_body | jq -r '.software_token_init_status')
    if [[ $software_token_init_status = "NOT_INITIALIZED" ]]; then
      initialize_security_server_post
      if [ $api_response_status_code = 201 ]; then
        log "Software token created"
      else
        log "Error, could not initialize software token. $api_response_body"
        exit 1
      fi
    elif [ $software_token_init_status = INITIALIZED ]; then
      local is_server_code_initialized=$(echo $api_response_body | jq -r '.is_server_code_initialized')
      local is_server_owner_initialized=$(echo $api_response_body | jq -r '.is_server_owner_initialized')
      if [[ $is_server_code_initialized = "false" ]] || [[ $is_server_owner_initialized = "false" ]]; then
        # when the response body of GET /initialization/status says (is_server_code_initialized:false or is_server_owner_initialized:false) AND software_token_init_status:INITIALIZED,
        # and still we try to POST /initialize, SS returns:
        # {"status":400,"error":{"code":"invalid_init_params","metadata":["pin_code_exists"]}}
        # also in this situation when we try to initialize through the UI, it shows
        # "Invalid initialisation parameters pin_code_exists" and we cannot recover.
        log "Error, the softtoken is already initialized, but the database is not. Please 1) backup the /etc/xroad/signer directory if needed, 2) clear the files in /etc/xroad/signer directory, and try again."
        exit 1
      fi
      log "Software token initialized"
    else
      # Before "X-Road Proxy Admin REST API" logs "Signer is available", API can respond with software_token_init_status: UNKNOWN.
      log "Unexpected software_token_init_status: $software_token_init_status"
    fi
  else
    log "Error, could not get initialization status. $api_response_body"
    exit 1
  fi
}

function initialize_security_server() {
  local n=0
  # can wait max 5 x 15 seconds
  local max_retries=5
  local sleep_interval=15
  software_token_init_status=""

  until [ $n -ge $max_retries ]; do
    initialize_security_server_try
    if [ $software_token_init_status != UNKNOWN ]; then
      # success
      break
    fi
    log "Retrying initialize after $sleep_interval seconds"
    n=$((n+1))
    sleep $sleep_interval
  done

  if [ $n -eq $max_retries ]; then
    log "Retry max exceeded"
    exit 1
  fi
}

function add_timestamping_service() {
  tpl='{
  "name": "%s",
  "url": "%s"
}'
  printf -v data "$tpl" "$PX_TSA_NAME" "$PX_TSA_URL"
  request_api POST "/system/timestamping-services" "$data"
  if [[ $api_response_status_code -eq 201 ]]; then
      log "Added timestamping service ${PX_TSA_NAME}"
  elif [[ $api_response_status_code -eq 409 ]]; then
      log "Timestamping service already exists"
  else
      log "Error, could not add timestamping service. $api_response_body"
      exit 1
  fi
}

function token_login() {
  local software_token_pin=$(cat $autologin_file)
  request_api PUT "/tokens/0/login" "{\"password\": \"$software_token_pin\"}"
}

function generate_key_and_csr () {
  local type=$1
  local code=""
  if [ $type = auth ]; then
    local key_usage_type=AUTHENTICATION
  else 
    local key_usage_type=SIGNING
    local member_id=", \"member_id\": \"$PX_INSTANCE:$PX_MEMBER_CLASS:$PX_MEMBER_CODE\""
  fi

  tpl='{
	"key_label": "%s-%s",
	"csr_generate_request": {
		"key_usage_type": "%s",
		"ca_name": "%s",
		"csr_format": "PEM",
		"subject_field_values": {
			"CN": "%s",
			"SN": "%s"
		}
    %s
	}
}'
  printf -v data "$tpl" "$type" "$PX_MEMBER_CODE" "$key_usage_type" "$PX_CA_NAME" "$PX_MEMBER_CODE" "$PX_MEMBER_CODE" "$member_id"

  # assume token id: 0
  request_api POST "/tokens/0/keys-with-csrs" "$data"
  if [[ $api_response_status_code -eq 200 ]]; then
    csr_data=($(echo "$api_response_body" | jq -r -c '.key.id,.csr_id'))
    csr_path="$Q_CERTS_FOLDER/$type-$PX_MEMBER_CODE.csr"
    # download csr to $Q_CERTS_FOLDER
    $(curl -s -k -H "Authorization: X-Road-ApiKey token=${created_api_key[1]}" \
    https://localhost:4000/api/v1/keys/${csr_data[0]}/csrs/${csr_data[1]}?csr_format=PEM -o $csr_path)

    if [ -f "$csr_path" ]; then
      log "CSR created for type $key_usage_type."
    else
      log "Error, could not download csr for type $key_usage_type. csr_id: ${csr_data[1]}"
      exit 1
    fi
  elif [[ $api_response_status_code -eq 409 ]]; then
    code=($(echo "$api_response_body" | jq -r -c '.error.code'))
    if [[ $code = "action_not_possible" ]]; then
      log "$type key already exists"
    else
      log "Error, could not create csr for type $key_usage_type. $api_response_body"
      exit 1
    fi
  else
    log "Error, could not create csr for type $key_usage_type. $api_response_body"
    exit 1
  fi
}

function request_certificate () {
  local type=$1
  local ca_enrollment_endpoint=$2
  local username="$type-$PX_MEMBER_CODE"
  local password=$3
  local csr_path="$Q_CERTS_FOLDER/$type-${PX_MEMBER_CODE}.csr"
  local crt_path="$Q_CERTS_FOLDER/$type-${PX_MEMBER_CODE}.crt"

  # request certificate if it doesn't exists
  if [ ! -f $crt_path ]; then
    log "requesting $type certificate for $username"
    # curl -k allows untrusted HTTPS connection.
    # Flag must be removed before release when EJBCA endpoint is available from public internet with a trusted certificate.
    curl -s -L $ca_enrollment_endpoint \
         --form-string user=$username \
         --form-string password=$password \
         -F "pkcs10req=
         $(cat ${csr_path})
         " \
         --form-string 'resulttype=4' > ${crt_path} # resulttype 4 returns full chain
    # Validate certificate with openssl
    openssl x509 -noout -in ${crt_path} 2> /dev/null
    # Check openssl status code, exit on failure
    check $? "certificate request from certification authority failed"
  else
    log "$type certificate already requested for $username"
  fi
}

function import_certificate () {
  local type=$1
  local code=""
  local crt_path="$Q_CERTS_FOLDER/$type-${PX_MEMBER_CODE}.crt"
  log "Importing $type certificate for $PX_MEMBER_CODE"

  local api_key=${created_api_key[1]}
  local curl_args=('-H' 'Content-Type: application/octet-stream' '-H' "Authorization: X-Road-ApiKey token=$api_key")
  api_response=$(curl -s -k -i -X POST --data-binary "@$crt_path" "${curl_args[@]}" "https://localhost:4000/api/v1/token-certificates")
  api_response_status_code=$(echo -e "$api_response"|head -n 3|tail -n 1|cut -d$' ' -f2)
  api_response_body=$(echo -e "$api_response"|tail -n 1)

  if [[ $api_response_status_code -eq 201 ]]; then
    log "Uploaded $type-${PX_MEMBER_CODE}.crt"
    if [ $type = auth ]; then
      # register and activate auth cert only
      # replace \, with , using sed, to avoid jq parse failure, should be cleaned in proxy-ui-api instead
      crt_hash=$(echo $api_response_body|sed 's/\\,/,/g'|jq -r '.certificate_details.hash')
      request_api PUT "/token-certificates/$crt_hash/register" "{\"address\":\"${PX_SS_PUBLIC_ENDPOINT}\"}"
      if [ $api_response_status_code = 204 ]; then
        log "Auth certificate registered"
        request_api PUT "/token-certificates/$crt_hash/activate"
        if [ $api_response_status_code = 204 ]; then
          log "Auth certificate activated"
        else
          log "Error, could not activate certificate $type-${PX_MEMBER_CODE}.crt. $api_response_body"
          exit 1
        fi
      else
        # register can fail for example when the PX_SS_PUBLIC_ENDPOINT is in invalid format.
        log "Error, could not register certificate. hash: $crt_hash $api_response_body"
        exit 1
      fi
    fi
  elif [[ $api_response_status_code -eq 409 ]]; then
    code=($(echo "$api_response_body" | jq -r -c '.error.code'))
    if [[ $code = "certificate_already_exists" ]]; then
      log "$type certificate already exists"
    else
      log "Error, could not upload certificate $type-${PX_MEMBER_CODE}.crt. $api_response_body"
      exit 1
    fi
  else
    log "Error, could not upload certificate $type-${PX_MEMBER_CODE}.crt. $api_response_body"
    exit 1
  fi
}

function start_xroad_process () {
  local start_script=$1
  local java_archive=$2
  local port=$3

  # start process if not running
  if ! pgrep -f $java_archive > /dev/null; then
    log "starting $start_script"
    if [[ $PX_TRACE_ENROLL ]]; then
        /usr/share/xroad/bin/${start_script} &
    else
        /usr/share/xroad/bin/${start_script} > /dev/null 2>&1 &
    fi
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
