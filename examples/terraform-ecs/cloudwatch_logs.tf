resource "aws_cloudwatch_log_group" "ss-primary" {
  name = "/ecs/${var.name_prefix}-primary"
  retention_in_days = 14
  # TODO
  # kms_key_id = ...
}

resource "aws_cloudwatch_log_group" "ss-secondary" {
  name = "/ecs/${var.name_prefix}-secondary"
  retention_in_days = 14
  # TODO
  # kms_key_id = ...
}

resource "aws_cloudwatch_log_group" "ecs-exec" {
  name = "/ecs/exec"
  retention_in_days = 14
  # TODO
  # kms_key_id = aws_kms_key.ecs-exec.arn
}
