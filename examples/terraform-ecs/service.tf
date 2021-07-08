locals {
  revision_primary = max(aws_ecs_task_definition.primary.revision, data.aws_ecs_task_definition.primary.revision)
  revision_secondary = max(aws_ecs_task_definition.secondary.revision, data.aws_ecs_task_definition.secondary.revision)
}

resource "aws_ecs_service" "primary" {
  name             = "${var.name_prefix}-primary"
  cluster          = aws_ecs_cluster.this.id
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.primary.family}:${local.revision_primary}"

  desired_count = 1
  # lifecycle {
  #   ignore_changes = [desired_count]
  # }

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.internal_4000.arn
    container_name   = "ss"
    container_port   = 4000
  }

  network_configuration {
    subnets = data.aws_subnet_ids.private.ids
    security_groups = [ module.internal_sg.security_group_id ]
  }

  enable_execute_command = var.enable_execute_command
}

resource "aws_ecs_service" "secondary" {
  name             = "${var.name_prefix}-secondary"
  cluster          = aws_ecs_cluster.this.id
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.secondary.family}:${local.revision_secondary}"

  desired_count = 1
  # lifecycle {
  #   ignore_changes = [desired_count]
  # }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.external_5500.arn
    container_name   = "ss"
    container_port   = 5500
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.external_5577.arn
    container_name   = "ss"
    container_port   = 5577
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.internal_80.arn
    container_name   = "ss"
    container_port   = 80
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.internal_443.arn
    container_name   = "ss"
    container_port   = 443
  }

  network_configuration {
    subnets = data.aws_subnet_ids.private.ids
    security_groups = [ module.internal_sg.security_group_id ]
  }

  enable_execute_command = true
}

data "aws_ecs_task_definition" "primary" {
  task_definition = aws_ecs_task_definition.primary.family
}

data "aws_ecs_task_definition" "secondary" {
  task_definition = aws_ecs_task_definition.secondary.family
}

resource "aws_ecs_task_definition" "primary" {
  family = "${var.name_prefix}-primary"

  container_definitions = data.template_file.container_definition_primary.rendered

  task_role_arn = aws_iam_role.task.arn
  execution_role_arn = aws_iam_role.execution.arn

  network_mode = "awsvpc"
  requires_compatibilities = [ "FARGATE" ]
  cpu = "2048"
  memory = "4096"

  volume {
    name = "signer"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.this.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2998
      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.signer.id
      }
    }
  }
  volume {
    name = "xroad"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.this.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999
      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.xroad.id
      }
    }
  }
}

resource "aws_ecs_task_definition" "secondary" {
  family = "${var.name_prefix}-secondary"

  container_definitions = data.template_file.container_definition_secondary.rendered

  task_role_arn = aws_iam_role.task.arn
  execution_role_arn = aws_iam_role.execution.arn
  
  network_mode = "awsvpc"
  requires_compatibilities = [ "FARGATE" ]
  cpu = "2048"
  memory = "4096"

  volume {
    name = "signer"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.this.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2998
      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.signer.id
      }
    }
  }
  volume {
    name = "xroad"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.this.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999
      authorization_config {
        iam = "ENABLED"
        access_point_id = aws_efs_access_point.xroad.id
      }
    }
  }
}

data "template_file" "container_definition_primary" {
  template = file("./templates/container-definition.json")

  vars = {
    docker_image = "conneqt/xroad-securityserver:6.26.0-1"
    signer_readonly = false
    xroad_readonly = false
    postgres_host = module.db.db_instance_address
    postgres_user = module.db.db_instance_username
    postgres_pass = module.db.db_instance_password
    awslogs_group = aws_cloudwatch_log_group.ss-primary.name
    awslogs_region = var.region
    awslogs_stream_prefix = "${var.name_prefix}-primary"
    public_endpoint = aws_lb.external.dns_name
    node_type = "primary"
  }
}

data "template_file" "container_definition_secondary" {
  template = file("./templates/container-definition.json")

  vars = {
    docker_image = "conneqt/xroad-securityserver:6.26.0-1"
    signer_readonly = true
    xroad_readonly = true
    postgres_host = module.db.db_instance_address
    postgres_user = module.db.db_instance_username
    postgres_pass = module.db.db_instance_password
    awslogs_group = aws_cloudwatch_log_group.ss-secondary.name
    awslogs_region = var.region
    awslogs_stream_prefix = "${var.name_prefix}-secondary"
    public_endpoint = aws_lb.external.dns_name
    node_type = "secondary"
  }
}
