# Data sources for Lambda deployment packages - automatically built from source
data "archive_file" "batch_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../batch"
  output_path = "${path.module}/lambda-packages/batch-lambda.zip"
  excludes    = ["node_modules/.cache", ".git"]
}

data "archive_file" "watcher_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../watcher"
  output_path = "${path.module}/lambda-packages/watcher-lambda.zip"
  excludes    = ["node_modules/.cache", ".git"]
}

data "archive_file" "queue_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../queue"
  output_path = "${path.module}/lambda-packages/queue-lambda.zip"
  excludes    = ["node_modules/.cache", ".git"]
}

# IAM role for Batch Lambda
resource "aws_iam_role" "batch_lambda_role" {
  name = "${local.stack_name}-Batch-Lambda-Role"

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

# Policies for Batch Lambda
resource "aws_iam_role_policy" "batch_lambda_logs" {
  name = "logs"
  role = aws_iam_role.batch_lambda_role.id

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

resource "aws_iam_role_policy" "batch_lambda_s3" {
  name = "s3"
  role = aws_iam_role.batch_lambda_role.id

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

resource "aws_iam_role_policy" "batch_lambda_sqs" {
  name = "SQS"
  role = aws_iam_role.batch_lambda_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = ["sqs:*"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "batch_lambda_dynamodb" {
  name = "dynamodb"
  role = aws_iam_role.batch_lambda_role.id

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

# Batch Lambda function
resource "aws_lambda_function" "batch_lambda" {
  filename         = data.archive_file.batch_lambda.output_path
  function_name    = "${local.stack_name}-BatchLambda"
  role            = aws_iam_role.batch_lambda_role.arn
  handler         = "batch.handler"
  source_code_hash = data.archive_file.batch_lambda.output_base64sha256
  runtime         = "nodejs18.x"
  memory_size     = 256
  timeout         = 80

  environment {
    variables = {
      REGION        = var.aws_region
      DYNAMODB_TABLE = local.api_table_name
      S3_BUCKET     = local.s3_bucket_name
    }
  }

  tags = local.common_tags
}

# Event source mapping for Batch Lambda
resource "aws_lambda_event_source_mapping" "batch_lambda_trigger" {
  event_source_arn = local.queue_arn
  function_name    = aws_lambda_function.batch_lambda.arn
}

# IAM role for Watcher Lambda
resource "aws_iam_role" "watcher_lambda_role" {
  name = "${local.stack_name}-Watcher-Lambda-Role"

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

# Policies for Watcher Lambda
resource "aws_iam_role_policy" "watcher_lambda_logs" {
  name = "logs"
  role = aws_iam_role.watcher_lambda_role.id

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

resource "aws_iam_role_policy" "watcher_lambda_s3" {
  name = "s3"
  role = aws_iam_role.watcher_lambda_role.id

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

resource "aws_iam_role_policy" "watcher_lambda_dynamodb" {
  name = "dynamodb"
  role = aws_iam_role.watcher_lambda_role.id

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

# Watcher Lambda function
resource "aws_lambda_function" "watcher_lambda" {
  filename         = data.archive_file.watcher_lambda.output_path
  function_name    = "${local.stack_name}-WatcherLambda"
  role            = aws_iam_role.watcher_lambda_role.arn
  handler         = "watcher.handler"
  source_code_hash = data.archive_file.watcher_lambda.output_base64sha256
  runtime         = "nodejs18.x"
  memory_size     = 256
  timeout         = 900

  environment {
    variables = {
      REGION        = var.aws_region
      DYNAMODB_TABLE = local.api_table_name
    }
  }

  tags = local.common_tags
}

# S3 bucket notification for Watcher Lambda
resource "aws_s3_bucket_notification" "wear_files_notification" {
  bucket = aws_s3_bucket.wear_files.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.watcher_lambda.arn
    events              = ["s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:CompleteMultipartUpload"]
    
    filter_suffix = ".zip"
  }

  depends_on = [aws_lambda_permission.watcher_lambda_s3_permission]
}

# Permission for S3 to invoke Watcher Lambda
resource "aws_lambda_permission" "watcher_lambda_s3_permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.watcher_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${local.s3_bucket_name}"
}
