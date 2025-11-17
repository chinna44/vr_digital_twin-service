terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources for external dependencies
data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "user_pool_id" {
  count = var.user_pool_id == "" ? 1 : 0
  name  = "/rail/user-management/${var.stack_suffix}/user-pool-id"
}

data "aws_ssm_parameter" "private_subnet" {
  count = var.private_subnet == "" ? 1 : 0
  name  = "/rail/networking/${var.stack_suffix}/private-subnet-1"
}

data "aws_ssm_parameter" "api_table_arn" {
  count = var.api_table_arn == "" ? 1 : 0
  name  = "/rail/api/${var.stack_suffix}/dynamodb-table-arn"
}

data "aws_ssm_parameter" "api_table_name" {
  count = var.api_table_name == "" ? 1 : 0
  name  = "/rail/api/${var.stack_suffix}/dynamodb-table-name"
}

data "aws_ssm_parameter" "topic_arn" {
  count = var.topic_arn == "" ? 1 : 0
  name  = "/rail/topology/${var.stack_suffix}/topic-arn-rail-simulation"
}

data "aws_ssm_parameter" "queue_arn" {
  count = var.queue_arn == "" ? 1 : 0
  name  = "/rail/topology/${var.stack_suffix}/queue-arn-rail-simulation"
}

locals {
  stack_name         = var.stack_name != "" ? var.stack_name : "RailSimulation${var.stack_suffix}"
  s3_bucket_name     = "loram-digital-wear-uploads-${lower(var.stack_suffix)}"
  s3_vti_bucket_name = "loram-digital-vti-files-${lower(var.stack_suffix)}"
  
  user_pool_id   = var.user_pool_id != "" ? var.user_pool_id : try(data.aws_ssm_parameter.user_pool_id[0].value, "")
  private_subnet = var.private_subnet != "" ? var.private_subnet : try(data.aws_ssm_parameter.private_subnet[0].value, "")
  api_table_arn  = var.api_table_arn != "" ? var.api_table_arn : try(data.aws_ssm_parameter.api_table_arn[0].value, "")
  api_table_name = var.api_table_name != "" ? var.api_table_name : try(data.aws_ssm_parameter.api_table_name[0].value, "")
  topic_arn      = var.topic_arn != "" ? var.topic_arn : try(data.aws_ssm_parameter.topic_arn[0].value, "")
  queue_arn      = var.queue_arn != "" ? var.queue_arn : try(data.aws_ssm_parameter.queue_arn[0].value, "")
  
  common_tags = {
    Environment = var.environment
    Project     = "RailSimulation"
    StackSuffix = var.stack_suffix
  }
}

# ECR Repository for simulation image
resource "aws_ecr_repository" "rail_simulation" {
  name                 = "${lower(local.stack_name)}/simulation"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_repository_policy" "rail_simulation_policy" {
  repository = aws_ecr_repository.rail_simulation.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:PutLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:StartLifecyclePolicyPreview"
        ]
      }
    ]
  })
}

# S3 Buckets
resource "aws_s3_bucket" "wear_files" {
  bucket = local.s3_bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wear_files_encryption" {
  bucket = aws_s3_bucket.wear_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "wear_files_cors" {
  bucket = aws_s3_bucket.wear_files.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket" "vti_files" {
  bucket = local.s3_vti_bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vti_files_encryption" {
  bucket = aws_s3_bucket.vti_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "vti_files_cors" {
  bucket = aws_s3_bucket.vti_files.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET"]
    allowed_origins = ["*"]
  }
}
