# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_instance_role" {
  name = "${local.stack_name}-EC2-Instance-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.stack_name} EC2 Instance Role"
  })
}

# IAM policies for EC2 role
resource "aws_iam_role_policy" "ec2_terminate_policy" {
  name = "${local.stack_name}TerminateEc2"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:TerminateInstances"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "${local.stack_name}ReadWriteS3"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.s3_bucket_name}/*",
          "arn:aws:s3:::${local.s3_bucket_name}",
          "arn:aws:s3:::${local.s3_vti_bucket_name}/*",
          "arn:aws:s3:::${local.s3_vti_bucket_name}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_global_s3_policy" {
  name = "${local.stack_name}ReadGlobalS3"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_dynamodb_policy" {
  name = "dynamodb"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:DescribeStream",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          local.api_table_arn,
          "${local.api_table_arn}/index/*",
          "${local.api_table_arn}/stream/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_ecr_policy" {
  name = "${local.stack_name}ReadECR"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ]
        Resource = aws_ecr_repository.rail_simulation.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_cloudwatch_policy" {
  name = "${local.stack_name}CloudWatchLogs"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_cognito_policy" {
  name = "${local.stack_name}CognitoUserPool"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient"
        ]
        Resource = ["arn:aws:cognito-idp:${var.aws_region}:${data.aws_caller_identity.current.account_id}:userpool/${local.user_pool_id}"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_ses_policy" {
  name = "ses"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_sns_policy" {
  name = "sns"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "SNS:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.stack_name}-EC2-Instance-Profile"
  role = aws_iam_role.ec2_instance_role.name

  tags = merge(local.common_tags, {
    Name = "${local.stack_name} EC2 Instance Profile"
  })
}
