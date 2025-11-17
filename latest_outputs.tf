# IAM role for Queue Lambda
resource "aws_iam_role" "queue_lambda_role" {
  name = "${local.stack_name}-Queue-Lambda-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# Policies for Queue Lambda
resource "aws_iam_role_policy" "queue_lambda_logs" {
  name = "logs"
  role = aws_iam_role.queue_lambda_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "queue_lambda_s3" {
  name = "s3"
  role = aws_iam_role.queue_lambda_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::${local.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "queue_lambda_iam" {
  name = "iam"
  role = aws_iam_role.queue_lambda_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = aws_iam_role.ec2_instance_role.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "queue_lambda_ec2_tags" {
  name = "ec2-tags"
  role = aws_iam_role.queue_lambda_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "queue_lambda_ec2" {
  name = "ec2"
  role = aws_iam_role.queue_lambda_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:Describe*",
          "ec2:TerminateInstances",
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "queue_lambda_ses" {
  name = "ses"
  role = aws_iam_role.queue_lambda_role.id

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

resource "aws_iam_role_policy" "queue_lambda_sns" {
  name = "sns"
  role = aws_iam_role.queue_lambda_role.id

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

resource "aws_iam_role_policy" "queue_lambda_dynamodb" {
  name = "dynamodb"
  role = aws_iam_role.queue_lambda_role.id

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

# Queue Lambda function
resource "aws_lambda_function" "queue_lambda" {
  filename         = data.archive_file.queue_lambda.output_path
  function_name    = "${local.stack_name}-QueueLambda"
  role            = aws_iam_role.queue_lambda_role.arn
  handler         = "handler.handler"
  source_code_hash = data.archive_file.queue_lambda.output_base64sha256
  runtime         = "nodejs18.x"
  memory_size     = 128
  timeout         = 60

  environment {
    variables = {
      REGION               = var.aws_region
      RAIL_IMAGE_AMI      = var.rail_image_ami
      RAIL_IMAGE_URI      = "${aws_ecr_repository.rail_simulation.repository_url}:latest"
      INSTANCE_PROFILE_ARN = aws_iam_instance_profile.ec2_instance_profile.arn
      AUTH_REGION         = var.aws_region
      USER_POOL_ID        = local.user_pool_id
      DYNAMODB_TABLE      = local.api_table_name
      S3_BUCKET           = aws_s3_bucket.wear_files.bucket
      S3_VTI_BUCKET       = aws_s3_bucket.vti_files.bucket
      AUTO_TERMINATE      = "1"
      STACK_NAME          = local.stack_name
      STACK_SUFFIX        = var.stack_suffix
      KEY_NAME            = var.key_name != "" ? var.key_name : "loram-dt-${lower(var.stack_suffix)}"
      PRIVATE_SUBNET      = local.private_subnet
      TOPIC_ARN           = local.topic_arn
    }
  }

  tags = local.common_tags
}

# EventBridge rule for Queue Lambda scheduling
resource "aws_cloudwatch_event_rule" "queue_lambda_schedule" {
  name                = "${local.stack_name}SimulationQueueRule"
  description         = "Trigger queue lambda every 5 minutes"
  schedule_expression = "cron(0/5 * * * ? *)"
  
  tags = local.common_tags
}

# EventBridge target for Queue Lambda
resource "aws_cloudwatch_event_target" "queue_lambda_target" {
  rule      = aws_cloudwatch_event_rule.queue_lambda_schedule.name
  target_id = "simulationQueueFnTarget"
  arn       = aws_lambda_function.queue_lambda.arn
}

# Permission for EventBridge to invoke Queue Lambda
resource "aws_lambda_permission" "queue_lambda_eventbridge_permission" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.queue_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.queue_lambda_schedule.arn
}
