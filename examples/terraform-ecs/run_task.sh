#!/bin/bash

set -euxo pipefail

# private subnet
subnet=subnet-016c8ca0ef1bdcffe
# allow internal security group
sg=sg-0e7c736e3dc3300ce
version=21
aws ecs run-task --cluster ss-ecs \
    --enable-execute-command \
    --launch-type FARGATE \
    --count 1 \
    --task-definition "ss-primary:${version}" \
    --network-configuration "{\"awsvpcConfiguration\":{\"subnets\":[\"${subnet}\"],\"securityGroups\":[\"${sg}\"],\"assignPublicIp\":\"DISABLED\"}}" \
    --overrides '{"containerOverrides":[{"name":"ss","command":["sleep","3600"],"environment":[{"name":"PX_ENROLL","value":"false"}]}]}'
