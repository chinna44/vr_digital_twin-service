output "watcher_lambda_name" {
  description = "Name of the Watcher Lambda function"
  value       = aws_lambda_function.watcher_lambda.function_name
}

output "iam_instance_profile" {
  description = "ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_instance_profile.arn
}

output "queue_lambda_name" {
  description = "Name of the Queue Lambda function"
  value       = aws_lambda_function.queue_lambda.function_name
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.rail_simulation.arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.rail_simulation.repository_url
}

output "wear_files_bucket_name" {
  description = "Name of the wear files S3 bucket"
  value       = aws_s3_bucket.wear_files.bucket
}

output "vti_files_bucket_name" {
  description = "Name of the VTI files S3 bucket"
  value       = aws_s3_bucket.vti_files.bucket
}

output "batch_lambda_name" {
  description = "Name of the Batch Lambda function"
  value       = aws_lambda_function.batch_lambda.function_name
}

# Optional: Store outputs in SSM Parameters for cross-stack references
resource "aws_ssm_parameter" "watcher_lambda_name" {
  name  = "/rail/simulation/${var.stack_suffix}/watcher-lambda-name"
  type  = "String"
  value = aws_lambda_function.watcher_lambda.function_name
  
  tags = local.common_tags
}

resource "aws_ssm_parameter" "iam_instance_profile" {
  name  = "/rail/simulation/${var.stack_suffix}/iam-instance-profile"
  type  = "String"
  value = aws_iam_instance_profile.ec2_instance_profile.arn
  
  tags = local.common_tags
}

resource "aws_ssm_parameter" "queue_lambda_name" {
  name  = "/rail/simulation/${var.stack_suffix}/queue-lambda-name"
  type  = "String"
  value = aws_lambda_function.queue_lambda.function_name
  
  tags = local.common_tags
}

resource "aws_ssm_parameter" "ecr_repository_arn" {
  name  = "/rail/simulation/${var.stack_suffix}/ecr-repository-arn"
  type  = "String"
  value = aws_ecr_repository.rail_simulation.arn
  
  tags = local.common_tags
}

resource "aws_ssm_parameter" "ecr_repository_url" {
  name  = "/rail/simulation/${var.stack_suffix}/ecr-repository-url"
  type  = "String"
  value = aws_ecr_repository.rail_simulation.repository_url
  
  tags = local.common_tags
}

resource "aws_ssm_parameter" "wear_files_bucket_name" {
  name  = "/rail/simulation/${var.stack_suffix}/wear-files-bucket-name"
  type  = "String"
  value = aws_s3_bucket.wear_files.bucket
  
  tags = local.common_tags
}

resource "aws_ssm_parameter" "vti_files_bucket_name" {
  name  = "/rail/simulation/${var.stack_suffix}/vti-files-bucket-name"
  type  = "String"
  value = aws_s3_bucket.vti_files.bucket
  
  tags = local.common_tags
}
