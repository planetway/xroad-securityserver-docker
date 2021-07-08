CONNEQT Security server cluster setup using Terraform
=====================================================

# Overview

This directory shows a very basic setup of a CONNEQT Security server cluster using Terraform.  
Treat this as a starting point, not the goal of a production cluster system.

# How to use

```
cp env.sh.template env.sh

# Use the AWS config and credentials under ~/.aws
# Edit env.sh

# Use the environment variables written in env.sh
. ./env.sh

# Runs terraform plan
make plan

# Run terraform apply
make apply

# Cleanup
make clean
```
