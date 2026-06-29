output "app_instance_profile_name" {
  description = "Name of the app EC2 instance profile"
  value       = aws_iam_instance_profile.app_ec2.name
}

output "jenkins_instance_profile_name" {
  description = "Name of the Jenkins EC2 instance profile"
  value       = aws_iam_instance_profile.jenkins_ec2.name
}

output "app_role_arn" {
  description = "ARN of the app EC2 IAM role"
  value       = aws_iam_role.app_ec2.arn
}

output "jenkins_role_arn" {
  description = "ARN of the Jenkins EC2 IAM role"
  value       = aws_iam_role.jenkins_ec2.arn
}
