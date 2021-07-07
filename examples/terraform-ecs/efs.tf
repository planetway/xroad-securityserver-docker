resource "aws_efs_file_system" "this" {
  # TODO
  # encrypted        = true
  # kms_key_id       = var.kms_key_id
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
}

resource "aws_efs_mount_target" "this" {
  for_each = data.aws_subnet_ids.private.ids
  file_system_id = aws_efs_file_system.this.id
  subnet_id      = each.value
  security_groups = [ module.efs_sg.security_group_id ]
}

resource "aws_efs_access_point" "signer" {
  file_system_id = aws_efs_file_system.this.id
  posix_user {
    gid = 999
    uid = 999
  }
  root_directory {
    path = "/signer"
    creation_info {
      owner_gid = 999
      owner_uid = 999
      permissions = 750
    }
  }
}

resource "aws_efs_access_point" "xroad" {
  file_system_id = aws_efs_file_system.this.id
  posix_user {
    gid = 999
    uid = 999
  }
  root_directory {
    path = "/xroad"
    creation_info {
      owner_gid = 999
      owner_uid = 999
      permissions = 750
    }
  }
}

output "efs_filesystem_id" {
  description = "EFS File system ID"
  value = aws_efs_file_system.this.id
}
