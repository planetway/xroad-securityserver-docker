# execution IAM role executes ECS related actions like pushing to Cloudwatch logs
resource "aws_iam_role" "execution" {
  name = "${var.name_prefix}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# IAM roles for tasks can be used by containers in the task
resource "aws_iam_role" "task" {
  name = "${var.name_prefix}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy" "ecs-execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// TODO make this more specific
data "aws_iam_policy" "efs-client-readwrite" {
  arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"
}

// from https://aws.amazon.com/blogs/containers/new-using-amazon-ecs-exec-access-your-containers-fargate-ec2/
data "aws_iam_policy_document" "ecs-exec" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "logs:DescribeLogGroups"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.this.account_id}:log-group:${aws_cloudwatch_log_group.ecs-exec.name}:*"
    ]
  }
  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      aws_kms_key.ecs-exec.arn
    ]
  }
}

resource "aws_iam_policy" "ecs-exec" {
  name   = "ecs-exec"
  path   = "/"
  policy = data.aws_iam_policy_document.ecs-exec.json
}

resource "aws_iam_role_policy_attachment" "ss-execution-ecs" {
  role       = aws_iam_role.execution.name
  policy_arn = data.aws_iam_policy.ecs-execution.arn
}

resource "aws_iam_role_policy_attachment" "ss-task-efs" {
  role       = aws_iam_role.task.name
  policy_arn = data.aws_iam_policy.efs-client-readwrite.arn
}

resource "aws_iam_role_policy_attachment" "ss-task-exec" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.ecs-exec.arn
}
