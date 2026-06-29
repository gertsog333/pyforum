variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for EC2 instances (eu-central-1a)"
  type        = string
}

variable "sg_app_id" {
  description = "Security group ID for app EC2"
  type        = string
}

variable "sg_jenkins_id" {
  description = "Security group ID for Jenkins EC2"
  type        = string
}

variable "my_ip" {
  description = "Current operator IP in CIDR notation (x.x.x.x/32)"
  type        = string
}

variable "app_instance_profile_name" {
  description = "IAM instance profile name for app EC2"
  type        = string
}

variable "jenkins_instance_profile_name" {
  description = "IAM instance profile name for Jenkins EC2"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS endpoint (host:port)"
  type        = string
  sensitive   = true
}

