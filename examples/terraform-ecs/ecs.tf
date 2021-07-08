locals {
  cluster_name = "${var.name_prefix}-ecs"
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  configuration {
    execute_command_configuration {
      # TODO
      # kms_key_id = aws_kms_key.ecs-exec.arn
      logging    = "OVERRIDE"

      log_configuration {
        # TODO
        # cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs-exec.name
      }
    }
  }

  capacity_providers = [ "FARGATE" ]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

module "ec2-profile" {
  source = "terraform-aws-modules/ecs/aws//modules/ecs-instance-profile"
  name   = "ecs-instance-profile"
}

data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh")

  vars = {
    cluster_name = local.cluster_name
  }
}
