variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name"
  type        = string
  default     = "pyforum"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "pyforum"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "891376973099"
}
