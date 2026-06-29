output "db_secret_arn" {
  description = "ARN of the DB credentials secret"
  value       = aws_secretsmanager_secret.db.arn
}

output "app_secret_arn" {
  description = "ARN of the app secret"
  value       = aws_secretsmanager_secret.app.arn
}

output "cloudflare_cert_secret_arn" {
  description = "ARN of the Cloudflare certificate secret"
  value       = aws_secretsmanager_secret.cloudflare_cert.arn
}

output "cloudflare_key_secret_arn" {
  description = "ARN of the Cloudflare private key secret"
  value       = aws_secretsmanager_secret.cloudflare_key.arn
}

output "db_name" {
  description = "Database name"
  value       = "forum"
}

output "db_username" {
  description = "Database username"
  value       = "forumuser"
}

output "db_password" {
  description = "Database password (random)"
  value       = random_password.db_password.result
  sensitive   = true
}
