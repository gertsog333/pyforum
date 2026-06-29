variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "my_ip" {
  description = "Operator IP in CIDR notation (x.x.x.x/32) for SSH/admin ingress rules"
  type        = string
}
