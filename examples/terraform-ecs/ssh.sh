#!/bin/bash

set -euxo pipefail

family=$1
if [[ -z $family ]]; then
   echo "usage: ssh.sh {family}"
   exit 1
fi

task_id=$(aws ecs list-tasks --cluster ss-ecs --family ${family} --desired-status RUNNING | jq --raw-output ".taskArns[0]")
exec aws ecs execute-command \
        --region "${AWS_REGION}" \
        --cluster ss-ecs \
        --task "${task_id}" \
        --container ss \
        --command "bash" \
        --interactive
