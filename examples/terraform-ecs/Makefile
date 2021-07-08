plan:
	terraform plan -out=/tmp/terraform.plan -var profile=$(AWS_PROFILE) -var region=$(AWS_REGION) -var myip=`curl -s ifconfig.co` -var termination_protection=false -var enable_execute_command=true -var public_zone_name=$(PUBLIC_ZONE_NAME) -var private_zone_name=$(PRIVATE_ZONE_NAME)

apply:
	terraform apply /tmp/terraform.plan

init:
	terraform init

clean:
	terraform destroy -var profile=$(AWS_PROFILE) -var region=$(AWS_REGION) -var myip=`curl -s ifconfig.co` -var termination_protection=false -var enable_execute_command=true -var public_zone_name=$(PUBLIC_ZONE_NAME) -var private_zone_name=$(PRIVATE_ZONE_NAME)

ssh-primary:
	./ssh.sh ss-primary

run-primary:
	./run-task.sh
