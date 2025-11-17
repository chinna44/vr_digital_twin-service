variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "stack_suffix" {
  description = "Stack suffix for resource naming"
  type        = string
  default     = ""
}

variable "stack_name" {
  description = "Stack name override"
  type        = string
  default     = ""
}

variable "version" {
  description = "Application version"
  type        = string
  default     = "0.0.0"
}

variable "rail_image_ami" {
  description = "AMI ID for rail simulation instances"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = ""
}

variable "force_build" {
  description = "Force Docker image build"
  type        = string
  default     = "false"
}

variable "user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
  default     = ""
}

variable "private_subnet" {
  description = "Private subnet ID for EC2 instances"
  type        = string
  default     = ""
}

variable "api_table_arn" {
  description = "DynamoDB table ARN"
  type        = string
  default     = ""
}

variable "api_table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = ""
}

variable "topic_arn" {
  description = "SNS topic ARN"
  type        = string
  default     = ""
}

variable "queue_arn" {
  description = "SQS queue ARN"
  type        = string
  default     = ""
}

variable "git_access_token" {
  description = "Git access token for Docker build"
  type        = string
  sensitive   = true
  default     = ""
}
