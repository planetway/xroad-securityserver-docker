resource "aws_iam_user" "ci" {
  name = "ci"
  path = "/system/"
}

resource "aws_iam_access_key" "ci" {
  user = aws_iam_user.ci.name
}

output "ci_aws_access_key_id" {
  description = "aws_access_key_id for the ci user"
  value = aws_iam_access_key.ci.id
}

output "ci_aws_secret_access_key" {
  description = "aws_secret_access_key for the ci user"
  value = aws_iam_access_key.ci.secret
  sensitive = true
}

resource "aws_iam_policy" "ecs" {
  name = "ecs-deploy"
  description = "policy for CI user"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "ecs:Describe*",
                "ecs:Update*",
                "ecs:Register*"
            ],
            "Resource": "*"
        }
    ]
} 

EOF
}

resource "aws_iam_user_policy_attachment" "ci_ecs" {
  user       = aws_iam_user.ci.name
  policy_arn = aws_iam_policy.ecs.arn
}
