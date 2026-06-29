output "app_ec2_public_ip" {
  description = "Elastic IP of the app EC2 instance"
  value       = aws_eip.app.public_ip
}

output "jenkins_ec2_public_ip" {
  description = "Elastic IP of the Jenkins EC2 instance"
  value       = aws_eip.jenkins.public_ip
}

output "app_ec2_instance_id" {
  description = "App EC2 instance ID"
  value       = aws_instance.app.id
}

output "jenkins_ec2_instance_id" {
  description = "Jenkins EC2 instance ID"
  value       = aws_instance.jenkins.id
}

output "pyforum_main_private_key" {
  description = "Private SSH key for pyforum-main (PEM format)"
  value       = tls_private_key.pyforum_main.private_key_pem
  sensitive   = true
}
