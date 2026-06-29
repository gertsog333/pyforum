resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "secret_key" {
  length  = 50
  special = false
}

# DB credentials secret
resource "aws_secretsmanager_secret" "db" {
  name                    = "pyforum/db"
  description             = "PostgreSQL database credentials for pyforum"
  recovery_window_in_days = 0

  tags = {
    Name = "pyforum/db"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    db_name     = "forum"
    db_user     = "forumuser"
    db_password = random_password.db_password.result
  })
}

# App secret (Django secret key)
resource "aws_secretsmanager_secret" "app" {
  name                    = "pyforum/app"
  description             = "Django application secret key for pyforum"
  recovery_window_in_days = 0

  tags = {
    Name = "pyforum/app"
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    secret_key = random_password.secret_key.result
  })
}

# Cloudflare origin certificate
resource "aws_secretsmanager_secret" "cloudflare_cert" {
  name                    = "pyforum/cloudflare-cert"
  description             = "Cloudflare origin certificate for pyforum-demo.win"
  recovery_window_in_days = 0

  tags = {
    Name = "pyforum/cloudflare-cert"
  }
}

resource "aws_secretsmanager_secret_version" "cloudflare_cert" {
  secret_id     = aws_secretsmanager_secret.cloudflare_cert.id
  secret_string = "REPLACE_WITH_CERT"
}

# Cloudflare origin private key
resource "aws_secretsmanager_secret" "cloudflare_key" {
  name                    = "pyforum/cloudflare-key"
  description             = "Cloudflare origin private key for pyforum-demo.win"
  recovery_window_in_days = 0

  tags = {
    Name = "pyforum/cloudflare-key"
  }
}

resource "aws_secretsmanager_secret_version" "cloudflare_key" {
  secret_id     = aws_secretsmanager_secret.cloudflare_key.id
  secret_string = "REPLACE_WITH_KEY"
}
