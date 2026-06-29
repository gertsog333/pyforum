#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/bootstrap"

echo "Initializing Terraform bootstrap..."
terraform init

echo "Applying Terraform bootstrap (S3 bucket + DynamoDB table)..."
terraform apply -auto-approve

echo "Bootstrap complete!"
echo "State bucket: $(terraform output -raw state_bucket_name)"
echo "DynamoDB table: $(terraform output -raw dynamodb_table_name)"
