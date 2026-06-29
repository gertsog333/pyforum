output "app_ec2_public_ip" {
  description = "Public Elastic IP of the app EC2 instance"
  value       = module.ec2.app_ec2_public_ip
}

output "jenkins_ec2_public_ip" {
  description = "Public Elastic IP of the Jenkins EC2 instance"
  value       = module.ec2.jenkins_ec2_public_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "s3_bucket_name" {
  description = "S3 bucket for static files"
  value       = module.s3.bucket_name
}

output "pyforum_main_private_key" {
  description = "Private SSH key for pyforum-main key pair"
  value       = module.ec2.pyforum_main_private_key
  sensitive   = true
}
