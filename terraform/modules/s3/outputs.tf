output "bucket_name" {
  description = "S3 bucket name for static files"
  value       = aws_s3_bucket.static.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.static.arn
}

output "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.static.bucket_regional_domain_name
}
