locals {
  db_name = "${var.name_prefix}db"
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  name = local.db_name
  identifier = local.db_name

  engine = "postgres"
  engine_version = "12.6"
  port = "5432"

  # DB option group
  major_engine_version = "12.6"

  # DB parameter group
  family = "postgres12"
  
  instance_class = "db.t3.micro"
  allocated_storage = "20"
  storage_encrypted = "false"
  multi_az = "true"

  username = "root"
  password = "${random_id.db_password.hex}"

  # TODO be more specific
  vpc_security_group_ids = [
    module.internal_sg.security_group_id
  ]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = "30"

  # DB subnet group
  subnet_ids = data.aws_subnet_ids.db.ids

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "${local.db_name}-${random_id.db_snapshot_name.hex}"

  deletion_protection = var.termination_protection

  publicly_accessible = "false"

  apply_immediately = "true"

  parameters = [
    {
      name = "max_connections"
      value = "100"
    }
  ]
}

# create unique id for database snapshot
resource "random_id" "db_snapshot_name" {
  byte_length = 8
}

resource "random_id" "db_password" {
  byte_length = 20
}

output "db_address" {
  value = "${module.db.db_instance_address}"
}

output "db_username" {
  value = "${module.db.db_instance_username}"
  sensitive = true
}

output "db_password" {
  value = "${module.db.db_instance_password}"
  sensitive = true
}
