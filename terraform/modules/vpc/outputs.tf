output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "sg_app_id" {
  description = "Security group ID for app EC2"
  value       = aws_security_group.sg_app.id
}

output "sg_jenkins_id" {
  description = "Security group ID for Jenkins EC2"
  value       = aws_security_group.sg_jenkins.id
}

output "sg_rds_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.sg_rds.id
}
