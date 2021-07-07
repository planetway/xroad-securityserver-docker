resource "aws_kms_key" "ecs-exec" {
  description             = "KMS key for ECS Exec"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "e" {
  name          = "alias/ecs-exec"
  target_key_id = aws_kms_key.ecs-exec.key_id
}
