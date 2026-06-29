variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repo_arn" {
  description = "ARN of the ECR repository"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for static files"
  type        = string
}
